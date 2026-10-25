@Tags(['golden'])
library;

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/ai/ai_consent_screen.dart';
import 'package:child_life/features/ai/ai_models.dart';
import 'package:child_life/features/ai/handover_screen.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/rhythm/rhythm_episodes.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/features/rhythm/rhythm_own.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/ai_fixtures.dart';
import '../helpers/reminder_fixtures.dart';
import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';

/// Premium Slice 3 and the Nhịp lớn lên leftovers, Light / Night care × vi / en: SU01 worded by
/// AI (591:6564 / 591:6830), SU01 as the template without consent (NL10b 574:1317), the ST01
/// states on SU01 (594:6967: AI error, quota, offline, new notes), the caregiver's read-only
/// copy, the AI consent screen (NL10 privacy) and NL07b / NL07's episode card (573:1199,
/// 573:1109). Synthetic data only.
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/ai_golden_test.dart

typedef _Case = ({
  Widget Function() build,
  List<Override> Function(String language) overrides,
});

const _heights = {
  'su01_ai': 1500.0,
  'su01_consent': 1240.0,
  'su01_error': 1240.0,
  'su01_quota': 1240.0,
  'su01_offline': 1240.0,
  'su01_stale': 1240.0,
  'su01_caregiver': 1100.0,
  'su01_received': 1400.0,
  'ai_consent': 1360.0,
  'nl07b_suggest': 900.0,
  'nl07_episode': 900.0,
};

/// NL01's own-rhythm card alone (where NL07b sits).
Widget _ownCard() => Consumer(
  builder: (context, ref, _) => Scaffold(
    backgroundColor: context.cl.colors.cloud,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(ClSpace.s4),
        children: [
          OwnRhythmCard(
            me: mai,
            caps: ref.watch(capabilitiesProvider(teddyId)).value,
            zone: 'Asia/Ho_Chi_Minh',
            today: rhythmToday,
          ),
        ],
      ),
    ),
  ),
);

List<Override> _su01(
  String language, {
  String method = 'ai',
  String? reason,
  Map<String, Object?>? quota,
  AiSettings? settings,
  bool online = true,
  bool stored = false,
  int? dataVersion,
  bool caregiver = false,
  bool sentToMe = false,
}) {
  final answer = handover(
    method: method,
    reason: reason,
    language: language,
    quota: quota,
  );
  final ai = FakeAiRepository(
    answer: answer,
    stored: stored ? [answer] : const [],
    settings:
        settings ??
        const AiSettings(
          consent: AiConsent(version: aiConsentVersion, shareMyNotes: true),
        ),
    dataVersion: dataVersion,
  );
  // Mẹ sent it to Cô Lan with a note (P-180 v2: the recipient's view and action).
  if (sentToMe) {
    ai.sends.add(
      HandoverSend(
        id: 'hs_golden',
        summaryId: answer.id,
        senderUid: 'u_mai',
        recipientUid: 'u_lan',
        sentAt: DateTime.utc(2026, 10, 8, 2, 40),
        note: 'Bé hay quấy sau 11h, bế đi dạo là ngủ.',
      ),
    );
  }
  return aiOverrides(
    ai: ai,
    online: online,
    member: caregiver ? lan : null,
    // A realistic morning at 10:00 (senior-ui-ux §2): the live part read like a carer would.
    records: _morning(),
    reminders: [reminder('Cho bé uống vitamin D', vn(8, 16, 0), mai)],
  );
}

final _cases = <String, _Case>{
  // SU01 worded by AI: three parts, record links, the AI label, report / send.
  'su01_ai': (build: () => const HandoverScreen(), overrides: _su01),
  // NL10b / ST01: no consent yet → the template, still three parts, the consent link.
  'su01_consent': (
    build: () => const HandoverScreen(summaryOpen: true),
    overrides: (l) => _su01(
      l,
      method: 'fallback',
      reason: 'CONSENT_REQUIRED',
      settings: AiSettings.none,
    ),
  ),
  // ST01 card 3: AI didn't respond → template, "không trừ lượt", Thử lại.
  'su01_error': (
    build: () => const HandoverScreen(summaryOpen: true),
    overrides: (l) => _su01(l, method: 'fallback', reason: 'timeout'),
  ),
  // Quota used up today: template + the quota line, no plan.
  'su01_quota': (
    build: () => const HandoverScreen(summaryOpen: true),
    overrides: (l) => _su01(
      l,
      method: 'fallback',
      reason: 'QUOTA_EXCEEDED',
      quota: quotaDayUsed(),
    ),
  ),
  // ST01 card 4: offline → the last stored version.
  'su01_offline': (
    build: () => const HandoverScreen(summaryOpen: true),
    overrides: (l) => _su01(l, online: false, stored: true),
  ),
  // New notes since this version: "Có ghi nhận mới · Tạo lại".
  'su01_stale': (
    build: () => const HandoverScreen(summaryOpen: true),
    overrides: (l) => _su01(l, stored: true, dataVersion: 9),
  ),
  // Cô Lan reads the latest stored handover (no "Gửi cho").
  'su01_caregiver': (
    build: () => const HandoverScreen(),
    overrides: (l) => _su01(l, stored: true, caregiver: true),
  ),
  // Mẹ sent it to Cô Lan with a note: who and the note on top, "Tôi đã nhận bàn giao" below.
  'su01_received': (
    build: () => const HandoverScreen(),
    overrides: (l) => _su01(l, stored: true, caregiver: true, sentToMe: true),
  ),
  // A1: what is sent, never sent, who handles it, share my notes, version.
  'ai_consent': (
    build: () => const AiConsentScreen(),
    overrides: (_) =>
        aiOverrides(ai: FakeAiRepository(settings: AiSettings.none)),
  ),
  // NL07b: the suggestion to group 06–08/10.
  'nl07b_suggest': (
    build: _ownCard,
    overrides: (_) =>
        rhythmOverrides(repo: FakeRhythmRepository(checkIns: recentCheckIns())),
  ),
  // NL07: the open episode, "Đang cập nhật", "Con đã ổn hơn".
  'nl07_episode': (
    build: _ownCard,
    overrides: (_) => rhythmOverrides(
      repo: FakeRhythmRepository(
        checkIns: recentCheckIns(),
        episodes: [
          ObservationEpisode(
            id: episodeIdFor(teddyId, '2026-10-06'),
            babyId: teddyId,
            startDate: '2026-10-06',
            confirmedBy: 'u_minh',
            checkInIds: [
              for (final c in recentCheckIns())
                if (c.changed) c.id,
            ],
          ),
        ],
      ),
    ),
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
          final height = _heights[name] ?? 812;
          tester.view.physicalSize = Size(375, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                environmentProvider.overrideWithValue(AppEnvironment.dev),
                ...c.overrides(locale.languageCode),
              ],
              child: MediaQuery(
                data: MediaQueryData(
                  size: Size(375, height),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
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
          debugDisableShadows = false;
          try {
            await tester.pump();
            await expectLater(
              find.byKey(const ValueKey('golden')),
              matchesGoldenFile(
                'goldens/ai/${name}_${palette.name}_${locale.languageCode}.png',
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

/// Teddy's night and morning up to 10:00 in Hồ Chí Minh ([rhythmNow]).
List<CareRecord> _morning() => [
  rec(CareType.diaper, vn(8, 9, 35), lan, diaper: DiaperKind.wet),
  rec(
    CareType.bottle,
    vn(8, 9, 30),
    lan,
    amountMl: 120,
    milk: MilkType.formula,
  ),
  rec(CareType.sleep, vn(8, 8, 30), lan, endedAt: vn(8, 9, 20)),
  rec(CareType.diaper, vn(8, 7, 5), mai, diaper: DiaperKind.dirty),
  rec(
    CareType.bottle,
    vn(8, 6, 50),
    mai,
    amountMl: 90,
    milk: MilkType.breastMilk,
  ),
  rec(CareType.sleep, vn(7, 22, 0), mai, endedAt: vn(8, 6, 40)),
  rec(CareType.breast, vn(8, 3, 10), mai, endedAt: vn(8, 3, 25)),
];
