#!/usr/bin/env ruby
# Adds the localized InfoPlist.strings (vi, en) to the Runner target. Idempotent.
#
#   ruby tool/ios_localized_resources.rb
require 'xcodeproj'

root = File.expand_path('../ios', __dir__)
project = Xcodeproj::Project.open(File.join(root, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' }
group = project.main_group['Runner']

variant = group.children.find { |c| c.isa == 'PBXVariantGroup' && c.name == 'InfoPlist.strings' } ||
          group.new_variant_group('InfoPlist.strings')
%w[vi en].each do |lang|
  path = "#{lang}.lproj/InfoPlist.strings"
  next if variant.files.any? { |f| f.path == path }

  ref = variant.new_reference(path)
  ref.name = lang
  ref.last_known_file_type = 'text.plist.strings'
end
unless runner.resources_build_phase.files_references.include?(variant)
  runner.resources_build_phase.add_file_reference(variant)
end
project.root_object.known_regions = (project.root_object.known_regions | %w[vi en Base])
project.save
puts 'InfoPlist.strings (vi, en) registered'
