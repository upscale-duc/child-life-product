import '../features/engagement/engagement_repository.dart';
import '../features/engagement/engagement_launch.dart';
import 'dart:async';

import '../features/app_update/app_update_screens.dart';
import '../features/analytics/product_analytics.dart';
import '../features/assistant/assistant_device.dart';
import '../features/feedback/feedback_host.dart';
import '../features/me/baby_profile_screens.dart';
import '../features/memories/push_registration.dart';
import '../features/glance/glance_bridge.dart';
import '../features/memories/share_inbox.dart';
import '../features/reminders/reminder_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appearance/appearance_providers.dart';
import '../core/design/cl_theme.dart';
import '../core/design/tokens.g.dart';
import '../core/widgets/cl_keyboard.dart';
import '../features/auth/auth_repository.dart';
import '../features/care/bottle_suggestions.dart';
import '../features/home/home_shell.dart' show selectedMembershipProvider;
import '../features/premium/premium_repository.dart'
    show selectedCapabilitiesProvider;
import '../features/premium/premium_v2.dart' show familyPlanV2Provider;
import '../features/care/growth_reference.dart';
import '../features/vaccines/vaccine_reference.dart';
import '../l10n/app_localizations.dart';
import 'locale.dart';
import 'router.dart';
import 'local_privacy_guard.dart';
import 'account_local_scope.dart';
import 'session.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class ChildLifeApp extends ConsumerWidget {
  const ChildLifeApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pin the opaque launch queue above AccountLocalScope, whose UID changes on login.
    ref.watch(engagementLaunchQueueProvider);
    final session = ref.watch(sessionProvider);
    final auth = ref.watch(authUserProvider);
    final uid = session is SessionSignedIn
        ? session.user.uid
        : session is SessionLoading
        ? auth.value?.uid
        : null;
    return AccountLocalScope(uid: uid, child: const _SessionApp());
  }
}

class _SessionApp extends ConsumerStatefulWidget {
  const _SessionApp();

  @override
  ConsumerState<_SessionApp> createState() => _SessionAppState();
}

class _SessionAppState extends ConsumerState<_SessionApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reference data (P-138): one read per launch; the bundled copy until it lands.
    unawaited(ref.read(bottleTableProvider.notifier).refresh());
    unawaited(ref.read(growthReferenceProvider.notifier).refresh());
    unawaited(ref.read(vaccineScheduleProvider.notifier).refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final me = ref.read(selectedMembershipProvider);
    if (me != null &&
        ref.read(selectedCapabilitiesProvider)?.features.premiumV2 == true) {
      ref.invalidate(familyPlanV2Provider(me.babyId));
    }
  }

  /// "Tự động" follows the system appearance (P-061).
  @override
  void didChangePlatformBrightness() {
    ref
        .read(platformBrightnessProvider.notifier)
        .set(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final privacyEpoch = ref.watch(localPrivacyGuardProvider);
    // Sign-out / family switch: the assistant's phone-side state goes (no child data left).
    ref.watch(assistantDeviceGuardProvider);
    return MaterialApp.router(
      key: ValueKey(privacyEpoch),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildClTheme(palette),
      themeAnimationDuration: ClMotion.gentle,
      themeAnimationCurve: Curves.easeInOut,
      locale: ref.watch(localeOverrideProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      localeListResolutionCallback: (locales, _) => resolveLocale(locales),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Auth emails (verification, reset) follow the app language (D-012).
        ref
            .read(authRepositoryProvider)
            .setLanguage(Localizations.localeOf(context).languageCode);
        // The status bar follows the app's palette, not the phone's appearance, and comes back
        // after a screen that set its own (the photo viewer's white icons stayed on Light).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: clStatusBarStyle(palette),
          // D-061: below the oldest allowed version only UP1 shows; UP2 offers a newer one.
          child: AppUpdateGate(
            child: AppUpdatePrompt(
              child: ReminderNotificationSync(
                child: EngagementScope(
                  child: ProductAnalyticsScope(
                    child: PushRegistration(
                      child: ShareInbox(
                        child: GlanceSync(
                          child: DeletionWatcher(
                            // FB4 screenshot toast, FB5 active days (D-065).
                            child: FeedbackHost(
                              // A tap outside a field closes the keyboard everywhere.
                              child: ClKeyboardDismiss(child: child!),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shown instead of the app when the build's environment configuration is inconsistent.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildClTheme(ClPalette.light),
      supportedLocales: supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      localeListResolutionCallback: (locales, _) => resolveLocale(locales),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${AppLocalizations.of(context).configErrorTitle}\n\n$message',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
