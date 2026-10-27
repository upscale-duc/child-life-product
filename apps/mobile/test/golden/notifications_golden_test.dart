@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/engagement/engagement_repository.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/notifications/inbox_screen.dart';
import 'package:child_life/features/notifications/notification_bell.dart';
import 'package:child_life/features/notifications/notification_settings_screen.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_repository.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/notification_fixtures.dart';
import '../helpers/reminder_fixtures.dart';

/// Notification centre (D-076 #2): the Hôm nay header bell without and with unread rows
/// (559:57622, EN04), EN06 Hộp thông báo (560:2884) full and empty, EN07 Cài đặt thông báo
/// (560:2981) top and bottom, in Light / Night care × vi / en. Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens
typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Future<void> Function(WidgetTester tester)? act,
});

final _now = DateTime(2026, 10, 8, 21);

List<Override> _base(
  FakeNotificationRepository repo, {
  bool systemOn = true,
}) => [
  ...familyOverrides(
    now: _now,
    notificationRepo: repo,
    notifications: FakeReminderNotifications(on: systemOn),
  ),
  // Pin the clock Night care auto reads, so the header's theme toggle does not flip when
  // the suite runs after 22:00.
  minuteClockProvider.overrideWith(
    (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
  ),
  userPreferencesProvider.overrideWith(
    (ref, uid) => Stream.value(
      UserPreferences.defaults.copyWith(digestTime: () => '20:30'),
    ),
  ),
  // Gợi ý thông minh on, as D-098 defaults it, so EN07 shows that group too.
  engagementProvider.overrideWith(
    (ref) async => {
      'enabled': true,
      'preferences': {'consent': true},
      'fatigue': <String, Object?>{},
    },
  ),
];

Widget _header() => const Scaffold(
  body: Padding(
    padding: EdgeInsets.fromLTRB(ClSpace.s4, 47, ClSpace.s4, 0),
    child: BabyHeader(
      actions: [
        NotificationBell(),
        SizedBox(width: ClSpace.s2),
        NightCareToggle(),
      ],
    ),
  ),
);

final _cases = <String, _Case>{
  'bell_read': (
    build: _header,
    overrides: () => _base(
      FakeNotificationRepository(
        inbox: [
          for (final i in mockInbox())
            if (!i.unread) i,
        ],
      ),
    ),
    act: null,
  ),
  'bell_unread': (
    build: _header,
    overrides: () => _base(FakeNotificationRepository(inbox: mockInbox())),
    act: null,
  ),
  'en06_inbox': (
    build: () => const InboxScreen(),
    overrides: () => _base(FakeNotificationRepository(inbox: mockInbox())),
    act: null,
  ),
  'en06_empty': (
    build: () => const InboxScreen(),
    overrides: () => _base(FakeNotificationRepository()),
    act: null,
  ),
  'en07_settings': (
    build: () => const NotificationSettingsScreen(),
    overrides: () => _base(FakeNotificationRepository(), systemOn: false),
    act: null,
  ),
  // NT-1: the stored switches have not loaded: none is drawn or tappable.
  'en07_loading': (
    build: () => const NotificationSettingsScreen(),
    overrides: () => _base(FakeNotificationRepository(holdSettings: true)),
    act: null,
  ),
  'en07_settings_bottom': (
    build: () => const NotificationSettingsScreen(),
    overrides: () => _base(FakeNotificationRepository()),
    act: (tester) async {
      // To the end: Gợi ý thông minh, Thời gian and the footnote.
      await tester.scrollUntilVisible(
        find.byKey(const Key('nt-quiet')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    },
  ),
};

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...c.overrides(),
              ],
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(375, 812),
                  disableAnimations: true,
                  padding: EdgeInsets.only(top: 47, bottom: 34),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('golden'),
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: buildClTheme(palette),
                    locale: locale,
                    supportedLocales: const [Locale('vi'), Locale('en')],
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    home: c.build(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await c.act?.call(tester);
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/nt/${name}_${palette.name}_${locale.languageCode}.png',
              ),
            );
          } finally {
            debugDisableShadows = true;
          }
        });
      }
    }
  }
}
