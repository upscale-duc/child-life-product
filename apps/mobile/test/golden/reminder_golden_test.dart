@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/reminders/reminder_models.dart';
import 'package:child_life/features/reminders/reminder_screens.dart';
import 'package:child_life/features/reminders/rule_models.dart';
import 'package:child_life/features/reminders/rule_screens.dart';
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/rule_fixtures.dart';

/// S7 reminders in Light / Night care × vi / en at 375 × 812, on the 8a mock (Thursday 8 Oct,
/// 15:05): one overdue, two upcoming on Mai's iPhone, one done.
/// Regenerate on macOS: flutter test --tags golden --update-goldens

typedef _Case = ({
  Widget Function() build,
  List<Override> Function() overrides,
  Map<String, Object> prefs,
  Future<void> Function(WidgetTester tester)? act,
});

AppLocalizations _l10n(WidgetTester t) =>
    AppLocalizations.of(t.element(find.byType(Scaffold).first));

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is ClButton && w.label == label);

Future<void> _openNew(WidgetTester t) async {
  await t.tap(
    find.byWidgetPredicate((w) => w is ClButton && w.icon == ClIcons.plus),
  );
  await t.pumpAndSettle();
}

_Case _list({
  Membership? me,
  bool on = true,
  Map<String, Object> prefs = const {},
  Future<void> Function(WidgetTester tester)? act,
  List<Reminder>? reminders,
}) => (
  build: () => const RemindersScreen(),
  overrides: () => careOverrides(
    me: me,
    notifications: FakeReminderNotifications(on: on),
    reminders: reminders,
  ),
  prefs: prefs,
  // The dated reminders: the "Một lần" half, which Nhắc nhở opens on (tapping it is a no-op).
  act: (t) async {
    await t.tap(find.text(_l10n(t).ruleTabOnce));
    await t.pumpAndSettle();
    await act?.call(t);
  },
);

Future<void> _next(WidgetTester t) async {
  final next = find.text(_l10n(t).ruleContinue);
  await t.ensureVisible(next);
  await t.tap(next);
  await t.pumpAndSettle();
}

_Case _rules({Membership? me}) => (
  build: () => const RemindersScreen(),
  overrides: () => careOverrides(me: me, rules: [feed, sleep, diaper]),
  prefs: const {},
  // "Theo quy tắc" is the second half now ("Một lần" opens first).
  act: (t) async {
    await t.tap(find.text(_l10n(t).ruleTabRules));
    await t.pumpAndSettle();
  },
);

_Case _editor(Future<void> Function(WidgetTester tester)? act) => (
  build: () => const RuleEditorScreen(),
  overrides: () => careOverrides(records: mockDay()),
  prefs: const {},
  act: act,
);

final _cases = <String, _Case>{
  '8a_reminders': _list(),
  '12f_reminders_caregiver': _list(me: lan),
  '8b_new_reminder': _list(act: _openNew),
  '8c_notification_prompt': _list(
    on: false,
    act: (t) async {
      await _openNew(t);
      await t.enterText(find.byType(EditableText), 'Tiêm 6 trong 1');
      await t.tap(_button(_l10n(t).reminderSave));
      await t.pumpAndSettle();
    },
  ),
  '8d_notifications_off': _list(
    on: false,
    prefs: const {'reminders.notificationsAsked': true},
  ),
  '8e_reminder_detail': (
    build: () => ReminderDetailScreen(reminderId: _ids[1]),
    overrides: () => careOverrides(reminders: _list8e),
    prefs: const {},
    act: null,
  ),
  '8e_reminder_done': (
    build: () => ReminderDetailScreen(reminderId: _ids[3]),
    overrides: () => careOverrides(reminders: _list8e),
    prefs: const {},
    act: null,
  ),
  // v1.0 rule reminders (370:1247).
  'v1i_1a_rules': _rules(),
  'v1i_1a_rules_caregiver': _rules(me: lan),
  'v1i_1b_new_rule': _editor(null),
  'v1i_1c_after_last': _editor(_next),
  'v1i_1c2_fixed': _editor((t) async {
    await t.tap(find.text(_l10n(t).ruleTypeSleep));
    await t.pump();
    await t.tap(find.text(_l10n(t).ruleModeFixed));
    await t.pump();
    await _next(t);
  }),
  'v1i_1d_recipients': _editor((t) async {
    await _next(t);
    await _next(t);
  }),
  'v1i_1g_due': (
    build: () => const Scaffold(body: TodayScreen()),
    overrides: () => careOverrides(
      records: mockDay(),
      rules: [rule('rr_feed', RuleType.feed, pending: vn(8, 14, 45))],
    ),
    prefs: const {},
    act: (t) async {
      showRuleDueSheet(
        t.element(find.byType(TodayScreen)),
        babyId: teddyId,
        ruleId: 'rr_feed',
      );
      await t.pumpAndSettle();
    },
  ),
  'v1i_1h_rule_detail': (
    build: () => const RuleDetailScreen(ruleId: 'rr_feed'),
    overrides: () => careOverrides(
      rules: [
        rule(
          'rr_feed',
          RuleType.feed,
          next: vn(8, 17, 52),
          last: mockOccurrences().first,
        ),
      ],
      occurrences: {'rr_feed': mockOccurrences()},
    ),
    prefs: const {},
    act: null,
  ),
  // D-075 #5: all day and assignee.
  '8a_reminders_assigned': _list(reminders: mockAssignedReminders()),
  '12f_reminders_assigned_caregiver': _list(
    me: lan,
    reminders: mockAssignedReminders(),
  ),
  '8b_new_reminder_all_day': _list(
    act: (t) async {
      await _openNew(t);
      await t.tap(find.byType(ClToggle));
      await t.pumpAndSettle();
    },
  ),
  '8b_assignee_picker': _list(
    act: (t) async {
      await _openNew(t);
      await t.tap(find.text(_l10n(t).reminderAssignee));
      await t.pumpAndSettle();
    },
  ),
  '8e_reminder_all_day_assigned': (
    build: () => ReminderDetailScreen(reminderId: _assigned[4].id),
    overrides: () => careOverrides(reminders: _assigned),
    prefs: const {},
    act: null,
  ),
  '8b_edit_reminder': (
    build: () => ReminderDetailScreen(reminderId: _ids[1]),
    overrides: () => careOverrides(reminders: _list8e),
    prefs: const {},
    act: (t) async {
      await t.tap(_button(_l10n(t).reminderEditTitle));
      await t.pumpAndSettle();
    },
  ),
};

final _list8e = mockReminders();
final _assigned = mockAssignedReminders();
final _ids = [for (final r in _list8e) r.id];

void main() {
  for (final MapEntry(key: name, value: c) in _cases.entries) {
    for (final palette in ClPalette.values) {
      for (final locale in const [Locale('vi'), Locale('en')]) {
        testWidgets('$name ${palette.name} ${locale.languageCode}', (
          tester,
        ) async {
          SharedPreferences.setMockInitialValues(c.prefs);
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = const Size(375, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final router = GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, _) => c.build()),
              GoRoute(
                path: '/:a/:b',
                builder: (_, _) => const Scaffold(body: Text('stub')),
              ),
            ],
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                providerDisplayNameProvider.overrideWithValue(null),
                minuteClockProvider.overrideWith(
                  (ref) => Stream.value(DateTime(2026, 10, 8, 10)),
                ),
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
                  child: MaterialApp.router(
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
                    routerConfig: router,
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
                'goldens/s7/${name}_${palette.name}_${locale.languageCode}.png',
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
