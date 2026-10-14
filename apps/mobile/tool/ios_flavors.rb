#!/usr/bin/env ruby
# Configures the iOS Runner project for the dev / prod flavors (implementation plan §3.7).
# Idempotent: re-running converges to the same project state.
#
#   ruby tool/ios_flavors.rb
#
# Result: build configurations Debug|Profile|Release-dev|prod, shared schemes `dev` and `prod`,
# per-flavor bundle id + display name, GoogleService-Info.plist copied from ios/config/<flavor>/
# (build fails if the flavor has no Firebase config), and Crashlytics dSYM upload for non-Debug builds.
require 'xcodeproj'

# dev uses an App ID borrowed from the owner's interim Apple team (VHFV2HNZGN) until the
# Child Life developer account exists (D-045); its push certificate is uploaded to Firebase.
TEAM_ID = 'VHFV2HNZGN'
FLAVORS = {
  # dev signs manually with the owner-supplied development profile "hsba app dev" (push, the
  # owner's iPhone); install it into ~/Library/Developer/Xcode/UserData/Provisioning Profiles.
  # Extension profiles (owner-supplied) go here per flavor once they exist; nil = automatic.
  'dev' => { bundle_id: 'dev.hsba.app', name: 'Child Life Dev', icon: 'AppIcon-dev', profile: 'hsba app dev',
             team: TEAM_ID,
             app_group: 'group.dev.hsba.app',
             # Invite links /i/<token> open the app (D-059; the "hsba app dev" profile carries
             # Associated Domains). Both landing hosts: the invite page's "Mở app" button links
             # to the other one, because iOS ignores a Universal Link to the page's own domain.
             applinks: ['dev.childlife.app', 'child-life-dev-landing.web.app'],
             extension_profiles: { 'widgetExtension' => nil, 'share' => nil } },
  # prod has no team until the Child Life developer account exists: signing it on the borrowed
  # team would register app.childlife there (it did once, from Xcode's automatic signing).
  'prod' => { bundle_id: 'app.childlife', name: 'Child Life', icon: 'AppIcon-prod', team: nil,
              app_group: 'group.app.childlife',
              # Needs Associated Domains on the prod App ID and profile when they exist, and a
              # second host for the invite page's "Mở app" button (open question in D-059).
              applinks: ['childlife.app'],
              extension_profiles: {} },
}.freeze
BASES = %w[Debug Profile Release].freeze
DEPLOYMENT_TARGET = '16.1'
# App extensions: bundle id = app bundle id + suffix. Interactive widgets and Live Activity
# intents need iOS 17, so the widget extension exists from 17 on; the share extension (S9) runs
# wherever the app does. `shared: true` targets also compile ios/Shared (S8 glance kit).
EXTENSIONS = {
  'widgetExtension' => { suffix: 'widgets', deployment: '17.0', dir: 'widget', shared: true },
  'share' => { suffix: 'share', deployment: DEPLOYMENT_TARGET, dir: 'share' },
}.freeze
# Apple Watch app (Figma "Apple Watch" 464:18, plan docs/product/apple-watch-plan.md, P-142): a
# single-target SwiftUI watchOS app, bundle id = app bundle id + ".watchkitapp", compiling
# ios/watch and ios/Shared without the iOS-only Live Activity intents. Not embedded in Runner
# yet, so `flutter run` does not build it; build and run it with the `watch-<flavor>` scheme.
WATCH = { name: 'watch', suffix: 'watchkitapp', deployment: '10.0', dir: 'watch' }.freeze
WATCH_SKIPS_SHARED = %w[GlanceIntents.swift].freeze
APP_VERSION = File.read(File.expand_path('../pubspec.yaml', __dir__), encoding: 'UTF-8')[/^version:\s*(\S+)/, 1].to_s

root = File.expand_path('../ios', __dir__)

# Entitlements per flavor, generated here: the App Group shared by the app and its extensions
# (share hand-off, widget data); the app also has push and Sign in with Apple. Xcode switches
# aps-environment to production when exporting for distribution.
def plist_value(value)
  case value
  when Array then "<array>\n#{value.map { |v| "\t\t<string>#{v}</string>" }.join("\n")}\n\t</array>"
  else "<string>#{value}</string>"
  end
end

def write_entitlements(path, entries)
  body = entries.map { |k, v| "\t<key>#{k}</key>\n\t#{plist_value(v)}" }.join("\n")
  File.write(path, <<~PLIST)
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    #{body}
    </dict>
    </plist>
  PLIST
end

FLAVORS.each do |flavor, info|
  # The keychain group lets widgets and Live Activity buttons write as the signed-in person (S8).
  keychain = ["$(AppIdentifierPrefix)#{info[:bundle_id]}.shared"]
  write_entitlements(File.join(root, 'Runner', "Runner-#{flavor}.entitlements"), {
    'aps-environment' => 'development',
    'com.apple.developer.applesignin' => ['Default'],
    'com.apple.security.application-groups' => [info[:app_group]],
    'keychain-access-groups' => keychain,
  }.merge(info[:applinks].to_a.empty? ? {} : {
    'com.apple.developer.associated-domains' => info[:applinks].map { |d| "applinks:#{d}" },
  }))
  EXTENSIONS.each_value do |ext|
    write_entitlements(File.join(root, ext[:dir], "#{ext[:dir]}-#{flavor}.entitlements"), {
      'com.apple.security.application-groups' => [info[:app_group]],
    }.merge(ext[:shared] ? { 'keychain-access-groups' => keychain } : {}))
  end
  # The watch keeps its own copy of the session and snapshot (it cannot read the phone's).
  write_entitlements(File.join(root, WATCH[:dir], "#{WATCH[:dir]}-#{flavor}.entitlements"), {
    'com.apple.security.application-groups' => [info[:app_group]],
    'keychain-access-groups' => keychain,
  })
end
project = Xcodeproj::Project.open(File.join(root, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
tests = project.targets.find { |t| t.name == 'RunnerTests' }

def flutter_xcconfig(project, base)
  group = project.main_group['Flutter']
  group.files.find { |f| f.path == "#{base}.xcconfig" } || group.files.find { |f| f.path == "#{base == 'Profile' ? 'Release' : base}.xcconfig" }
end

# Manual signing with an owner-supplied development profile, or automatic signing without one.
def sign(config, profile, team)
  config.build_settings.delete('DEVELOPMENT_TEAM[sdk=iphoneos*]')
  unless team
    # No team: nothing can be signed or registered for this flavor.
    %w[DEVELOPMENT_TEAM PROVISIONING_PROFILE_SPECIFIER CODE_SIGN_IDENTITY[sdk=iphoneos*]].each { |k| config.build_settings.delete(k) }
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['CODE_SIGN_IDENTITY'] = ''
    return
  end
  config.build_settings['DEVELOPMENT_TEAM'] = team
  config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
  config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Development'
  if profile
    config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
    config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = profile
  else
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
  end
end

def ensure_config(list, name, template)
  config = list.build_configurations.find { |c| c.name == name }
  unless config
    config = list.project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
    config.name = name
    list.build_configurations << config
  end
  config.build_settings = template.build_settings.dup
  config.base_configuration_reference = template.base_configuration_reference
  config
end

# Flavor xcconfigs include the matching Pods config and Flutter's Generated.xcconfig.
FLAVORS.each_key do |flavor|
  BASES.each do |base|
    path = File.join(root, 'Flutter', "#{base}-#{flavor}.xcconfig")
    pods_kind = "#{base.downcase}-#{flavor}"
    File.write(path, <<~XC)
      // Generated by tool/ios_flavors.rb — do not edit.
      #include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.#{pods_kind}.xcconfig"
      #include "Generated.xcconfig"
      FLUTTER_FLAVOR = #{flavor}
    XC
  end
end

flutter_group = project.main_group['Flutter']
[[:project, project.build_configuration_list], [:runner, runner.build_configuration_list], [:tests, tests.build_configuration_list]].each do |owner, list|
  BASES.each do |base|
    template = list.build_configurations.find { |c| c.name == base } || list.build_configurations.find { |c| c.name.start_with?("#{base}-") }
    FLAVORS.each do |flavor, info|
      config = ensure_config(list, "#{base}-#{flavor}", template)
      if owner == :runner
        # Mirror how Flutter references its own xcconfigs (path may include the "Flutter/" prefix).
        template_ref = flutter_group.files.find { |f| File.basename(f.path.to_s) == 'Debug.xcconfig' }
        prefix = File.dirname(template_ref.path.to_s)
        wanted = prefix == '.' ? "#{base}-#{flavor}.xcconfig" : File.join(prefix, "#{base}-#{flavor}.xcconfig")
        stale = flutter_group.files.select { |f| File.basename(f.path.to_s) == "#{base}-#{flavor}.xcconfig" && f.path != wanted }
        stale.each(&:remove_from_project)
        ref = flutter_group.files.find { |f| f.path == wanted }
        unless ref
          ref = flutter_group.new_reference(wanted)
          ref.source_tree = template_ref.source_tree
          ref.path = wanted
        end
        config.base_configuration_reference = ref
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = info[:bundle_id]
        config.build_settings['FLAVOR_APP_NAME'] = info[:name]
        config.build_settings['CL_APP_GROUP'] = info[:app_group]
        config.build_settings['CL_URL_SCHEME'] = info[:bundle_id]
        config.build_settings['CL_KEYCHAIN_GROUP'] = "#{info[:bundle_id]}.shared"
        config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = info[:icon]
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
        # Signing on the team; push (aps-environment) comes from the entitlements.
        config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "Runner/Runner-#{flavor}.entitlements"
        sign(config, info[:profile], info[:team])
      elsif owner == :tests
        # The template's Pods xcconfig is another flavor's: use this configuration's own.
        pods = project.files.find { |f| File.basename(f.path.to_s) == "Pods-RunnerTests.#{base.downcase}-#{flavor}.xcconfig" }
        config.base_configuration_reference = pods if pods
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{info[:bundle_id]}.RunnerTests"
        config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Runner.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Runner'
      else
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
      end
    end
  end
  # Unflavored configurations are removed so no build can run without an explicit environment.
  list.build_configurations.select { |c| BASES.include?(c.name) }.each(&:remove_from_project)
  list.default_configuration_name = 'Release-prod'
end

# App extensions: per-flavor bundle id and signing, flavored configurations only.
EXTENSIONS.each do |name, ext|
  target = project.targets.find { |t| t.name == name }
  next unless target
  list = target.build_configuration_list
  BASES.each do |base|
    template = list.build_configurations.find { |c| c.name == base } || list.build_configurations.find { |c| c.name.start_with?("#{base}-") }
    FLAVORS.each do |flavor, info|
      config = ensure_config(list, "#{base}-#{flavor}", template)
      config.base_configuration_reference = nil
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{info[:bundle_id]}.#{ext[:suffix]}"
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = ext[:deployment]
      config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "#{ext[:dir]}/#{ext[:dir]}-#{flavor}.entitlements"
      config.build_settings['CL_APP_GROUP'] = info[:app_group]
      config.build_settings['CL_URL_SCHEME'] = info[:bundle_id]
      config.build_settings['CL_KEYCHAIN_GROUP'] = "#{info[:bundle_id]}.shared"
      config.build_settings['FLAVOR_APP_NAME'] = info[:name]
      sign(config, info[:extension_profiles][name], info[:team])
    end
  end
  list.build_configurations.select { |c| BASES.include?(c.name) }.each(&:remove_from_project)
  list.default_configuration_name = 'Release-prod'
end

# ios/Shared (glance kit: App Group snapshot, shared session, Firestore REST, intents, Live
# Activity attributes) compiles into the app and every `shared: true` extension.
shared_group = project.main_group['Shared'] || project.main_group.new_group('Shared', 'Shared')
shared_files = Dir[File.join(root, 'Shared', '*.swift')].sort.map do |path|
  name = File.basename(path)
  shared_group.files.find { |f| f.path == name } || shared_group.new_file(name)
end
shared_group.files.reject { |f| shared_files.include?(f) }.each(&:remove_from_project)
shared_targets = [runner] + EXTENSIONS.select { |_, e| e[:shared] }.keys.map { |n| project.targets.find { |t| t.name == n } }.compact
shared_targets.each do |target|
  phase = target.source_build_phase
  shared_files.each { |ref| phase.add_file_reference(ref, true) }
end

# Apple Watch target: flavored configurations like the extensions, watchOS settings, its own
# sources and resources plus ios/Shared.
watch = project.targets.find { |t| t.name == WATCH[:name] } ||
        project.new_target(:application, WATCH[:name], :watchos, WATCH[:deployment])
watch_list = watch.build_configuration_list
marketing_version, build_number = APP_VERSION.split('+')
BASES.each do |base|
  template = watch_list.build_configurations.find { |c| c.name == base } ||
             watch_list.build_configurations.find { |c| c.name.start_with?("#{base}-") } ||
             watch_list.build_configurations.find { |c| c.name == 'Release' }
  FLAVORS.each do |flavor, info|
    config = ensure_config(watch_list, "#{base}-#{flavor}", template)
    config.base_configuration_reference = nil
    s = config.build_settings
    s['PRODUCT_NAME'] = 'ChildLifeWatch'
    s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{info[:bundle_id]}.#{WATCH[:suffix]}"
    s['INFOPLIST_FILE'] = "#{WATCH[:dir]}/Info.plist"
    s['GENERATE_INFOPLIST_FILE'] = 'NO'
    s['SDKROOT'] = 'watchos'
    s['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
    s['TARGETED_DEVICE_FAMILY'] = '4'
    s['WATCHOS_DEPLOYMENT_TARGET'] = WATCH[:deployment]
    s.delete('IPHONEOS_DEPLOYMENT_TARGET')
    s['SWIFT_VERSION'] = '5.0'
    s['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = base == 'Debug' ? 'DEBUG $(inherited)' : '$(inherited)'
    s['ASSETCATALOG_COMPILER_APPICON_NAME'] = "AppIcon-#{flavor}"
    s['CODE_SIGN_ENTITLEMENTS'] = "#{WATCH[:dir]}/#{WATCH[:dir]}-#{flavor}.entitlements"
    s['CL_APP_GROUP'] = info[:app_group]
    s['CL_KEYCHAIN_GROUP'] = "#{info[:bundle_id]}.shared"
    s['CL_COMPANION_BUNDLE_ID'] = info[:bundle_id]
    s['FLAVOR_APP_NAME'] = info[:name]
    s['MARKETING_VERSION'] = marketing_version
    s['CURRENT_PROJECT_VERSION'] = build_number || '1'
    s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
    s['ENABLE_PREVIEWS'] = 'YES'
    sign(config, nil, info[:team])
  end
end
watch_list.build_configurations.select { |c| BASES.include?(c.name) }.each(&:remove_from_project)
watch_list.default_configuration_name = 'Release-prod'

watch_group = project.main_group[WATCH[:dir]] || project.main_group.new_group(WATCH[:dir], WATCH[:dir])
watch_dir = File.join(root, WATCH[:dir])
watch_names = Dir[File.join(watch_dir, '*.swift')].map { |p| File.basename(p) }.sort +
              %w[Info.plist Assets.xcassets Localizable.xcstrings] +
              Dir[File.join(watch_dir, '*.entitlements')].map { |p| File.basename(p) }.sort
watch_refs = watch_names.map { |name| watch_group.files.find { |f| f.path == name } || watch_group.new_file(name) }
watch_group.files.reject { |f| watch_refs.include?(f) }.each(&:remove_from_project)
watch_sources = watch_refs.select { |f| f.path.end_with?('.swift') } +
                shared_files.reject { |f| WATCH_SKIPS_SHARED.include?(f.path) }
watch.source_build_phase.files.reject { |bf| watch_sources.include?(bf.file_ref) }.each(&:remove_from_project)
watch_sources.each { |ref| watch.source_build_phase.add_file_reference(ref, true) }
%w[Assets.xcassets Localizable.xcstrings].each do |name|
  watch.resources_build_phase.add_file_reference(watch_refs.find { |f| f.path == name }, true)
end

# App-only native code next to AppDelegate (background uploads, 10j): every ios/Runner/*.swift.
runner_group = project.main_group['Runner']
Dir[File.join(root, 'Runner', '*.swift')].sort.each do |path|
  name = File.basename(path)
  ref = runner_group.files.find { |f| f.path == name } || runner_group.new_file(name)
  runner.source_build_phase.add_file_reference(ref, true)
end

# Copy the flavor's GoogleService-Info.plist into the app bundle; fail if the flavor has none.
copy_name = 'Copy Firebase config for flavor'
copy = runner.shell_script_build_phases.find { |p| p.name == copy_name } || runner.new_shell_script_build_phase(copy_name)
copy.shell_script = <<~SH
  FLAVOR="${CONFIGURATION##*-}"
  SRC="${PROJECT_DIR}/config/${FLAVOR}/GoogleService-Info.plist"
  if [ ! -f "$SRC" ]; then
    echo "error: Firebase is not configured for flavor '${FLAVOR}' (missing ios/config/${FLAVOR}/GoogleService-Info.plist)"
    exit 1
  fi
  cp "$SRC" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
SH
copy.input_paths = ['$(PROJECT_DIR)/config/$(FLUTTER_FLAVOR)/GoogleService-Info.plist']
copy.output_paths = ['$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app/GoogleService-Info.plist']

# Crashlytics symbol upload (skipped for Debug builds).
dsym_name = 'Upload Crashlytics symbols'
dsym = runner.shell_script_build_phases.find { |p| p.name == dsym_name } || runner.new_shell_script_build_phase(dsym_name)
dsym.shell_script = <<~SH
  if [ "${CONFIGURATION%%-*}" = "Debug" ]; then exit 0; fi
  "${PODS_ROOT}/FirebaseCrashlytics/run"
SH
dsym.input_paths = [
  '${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}',
  '${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}',
  '${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist',
  '$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app/GoogleService-Info.plist',
  '$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)',
]
# Keep both phases last so they run after Flutter's build and resource phases. Extensions are
# embedded before Flutter's "Thin Binary" script, or Xcode reports a dependency cycle.
[copy, dsym].each { |phase| runner.build_phases.delete(phase); runner.build_phases << phase }
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
thin = runner.shell_script_build_phases.find { |p| p.name == 'Thin Binary' }
if embed && thin
  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
end

project.save

# Shared schemes named after the flavors (required by `flutter run --flavor`).
schemes_dir = File.join(root, 'Runner.xcodeproj', 'xcshareddata', 'xcschemes')
FLAVORS.each_key do |flavor|
  scheme = Xcodeproj::XCScheme.new
  scheme.configure_with_targets(runner, tests)
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.test_action.build_configuration = "Debug-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"
  scheme.save_as(File.join(root, 'Runner.xcodeproj'), flavor, true)
end
FLAVORS.each_key do |flavor|
  scheme = Xcodeproj::XCScheme.new
  scheme.configure_with_targets(watch, nil, launch_target: true)
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"
  scheme.save_as(File.join(root, 'Runner.xcodeproj'), "watch-#{flavor}", true)
end
runner_scheme = File.join(schemes_dir, 'Runner.xcscheme')
File.delete(runner_scheme) if File.exist?(runner_scheme)

# Display name follows the flavor.
plist_path = File.join(root, 'Runner', 'Info.plist')
plist = Xcodeproj::Plist.read_from_path(plist_path)
plist['CFBundleDisplayName'] = '$(FLAVOR_APP_NAME)'
plist['CFBundleName'] = '$(FLAVOR_APP_NAME)'
Xcodeproj::Plist.write_to_path(plist, plist_path)

puts 'iOS flavors configured: ' + FLAVORS.keys.join(', ')
