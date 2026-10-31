import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/home/home_shell.dart'
    show selectedBabyIdProvider;
import 'package:intl/date_symbol_data_local.dart';
import '../helpers/assistant_fixtures.dart';
import '../helpers/router_pump.dart';
import '../helpers/family_fixtures.dart' show teddyId;
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_cards.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/assistant/assistant_read_links.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _card() => {
  'type': 'read_card',
  'schemaVersion': 1,
  'tool': 'pump_summary',
  'title': 'Hút sữa hôm nay',
  'asOf': '2026-10-20T00:30:00.000Z',
  'rows': [
    {
      'label': 'Tổng lượng',
      'value': '120 ml',
      'link': '/care/history?filter=pump',
    },
  ],
  'action': {
    'label': 'Mở lịch sử hút sữa',
    'link': '/care/history?filter=pump',
  },
  'sourceIds': ['r_one'],
  'caveat': 'Chỉ tính dữ liệu đã ghi.',
};
void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
  });
  test(
    'parses typed read cards and safely handles unknown versions and malformed rows',
    () {
      final card = AssistantPart.fromJson(_card()) as ReadCardPart;
      expect(card.sourceIds, ['r_one']);
      expect(card.rows.single.value, '120 ml');
      expect(
        AssistantPart.fromJson({..._card(), 'schemaVersion': 2}),
        isA<UnsupportedPart>(),
      );
      expect(
        AssistantPart.fromJson({
          ..._card(),
          'rows': [
            {'label': 'x'},
          ],
        }),
        isA<UnsupportedPart>(),
      );
    },
  );
  test(
    'allows the module screens and filters, rejecting external URLs and unknown query keys',
    () {
      for (final path in [
        '/care/history?filter=pump',
        '/care/solids/history?tab=foods',
        '/utilities/spending',
        '/utilities/milestones/sits',
        '/utilities/first-aid/s/choking',
        '/library/a/art_sleep',
        '/stages/stg_m7',
        '/care/reminders/rules/rr_test',
        '/care/timer/pump',
        // Hiểu con (D-151 #7): the insight_basis card opens the screen or one insight.
        '/care/insights',
        '/care/insights/night_longest',
      ]) {
        expect(assistantReadRoute(path), path);
      }
      for (final path in [
        'https://evil.test/care',
        '//evil.test/care',
        '/settings/delete',
        '/care/history?filter=pump&filter=all',
        '/care/history?filter=evil',
        '/care/history?babyId=other',
        '/library/a/%2e%2e',
        '/library/a/x#secret',
      ]) {
        expect(assistantReadRoute(path), isNull, reason: path);
      }
    },
  );
  testWidgets(
    'a module action selects the baby bound to the chat before opening history',
    (tester) async {
      final repo = FakeAssistantRepository(
        tasks: {
          taskA: snapshotWith(
            task: taskJson(),
            messages: [
              userMessage('Hút được bao nhiêu?'),
              assistantMessage([_card()]),
            ],
          ),
        },
      );
      final (visits, container) = await pumpRouted(
        tester,
        AssistantChatScreen(scopeKey: teddyScope.key),
        prefs: {
          'assistant.conversation.u_mai:${teddyScope.key}': conversation1,
          'assistant.tasks.u_mai:${teddyScope.key}': [taskA],
        },
        overrides: assistantOverrides(repo: repo),
      );
      await tester.pumpAndSettle();
      container.read(selectedBabyIdProvider.notifier).select('another_baby');
      await tester.tap(find.text('Mở lịch sử hút sữa'));
      await tester.pumpAndSettle();
      expect(container.read(selectedBabyIdProvider), teddyId);
      expect(visits.last.location, '/care/history?filter=pump');
    },
  );
  for (final palette in [ClPalette.light, ClPalette.nightCare]) {
    testWidgets(
      'read card shows snapshot time, values and working actions in $palette',
      (tester) async {
        final opened = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: buildClTheme(palette),
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: SingleChildScrollView(
                child: AsReadCard(
                  part: AssistantPart.fromJson(_card()) as ReadCardPart,
                  zone: 'Asia/Ho_Chi_Minh',
                  now: DateTime.utc(2026, 10, 20, 3),
                  onOpen: opened.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('120 ml'), findsOneWidget);
        // The same local day shows the time only (owner 2026-10-31).
        expect(find.text('Dữ liệu đến 07:30'), findsOneWidget);
        await tester.tap(find.text('Mở lịch sử hút sữa'));
        expect(opened, ['/care/history?filter=pump']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
