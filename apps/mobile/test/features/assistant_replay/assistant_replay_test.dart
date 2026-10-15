import 'dart:convert';
import 'dart:io';

import 'package:child_life/app/environment.dart';
import 'package:child_life/app/providers.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/assistant/assistant_cards.dart';
import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:child_life/features/assistant/assistant_widgets.dart';
import 'package:child_life/features/auth/auth_repository.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/assistant_fixtures.dart';
import '../../helpers/family_fixtures.dart';

/// Lumi app replay (docs/assistant/test-plan.md §3c). Every snapshot the server harness
/// (`firebase/tests/assistant-e2e`, fake model) produced is rendered through the REAL chat screen
/// (the assistant repository is a fake fed with the snapshot) and checked for the UI side of "no
/// dead end": a flagged field is named in plain words, a fix control is on the card (no extra
/// sheet to find it), a clean draft can be saved in one tap, the server's question shows its
/// chips, nothing throws, and nothing overflows at large text. Synthetic data only.
///
/// Fixtures: `fixtures/*.json` (the current server), `fixtures/device/*.json` (snapshots of the
/// server the owner's device bugs came from; drafts live 24 h, so the app must cope with them).
/// Baseline: `known_failures.json` (fixture id → codes). A code not in the baseline fails; run with
/// `--dart-define=REPLAY_STRICT=true` to fail on every violation. Results: `build/assistant_replay/`.

const _strict = bool.fromEnvironment('REPLAY_STRICT');
const _root = 'test/features/assistant_replay';

final Map<String, dynamic> _controls =
    jsonDecode(File('$_root/field_controls.json').readAsStringSync())
        as Map<String, dynamic>;
final Map<String, dynamic> _known =
    (jsonDecode(File('$_root/known_failures.json').readAsStringSync())
            as Map<String, dynamic>)['fixtures']
        as Map<String, dynamic>;

/// Plain words that name a field, for any kind (the controls map first).
List<String> _wordsFor(String kind, String field) {
  final kinds = _controls['kinds'] as Map<String, dynamic>;
  final k = kinds[kind] as Map<String, dynamic>?;
  final f = (k?['fields'] as Map<String, dynamic>?)?[field] as Map?;
  if (f != null) return [for (final w in f['words'] as List) '$w'];
  return switch (field) {
    'date' => const ['ngày'],
    'when' => const ['ban đêm', 'ban ngày', 'khi nào', 'buổi'],
    'milk' => const ['sữa'],
    'note' => const ['ghi chú'],
    'observation' => const ['loại', 'điều'],
    'at' => const ['giờ', 'lúc'],
    'side' => const ['bên'],
    _ => [field],
  };
}

bool _editorFor(String kind) =>
    ((_controls['kinds'] as Map<String, dynamic>)[kind]
        as Map<String, dynamic>?)?['editor'] ==
    true;

Membership _member(String who) => switch (who) {
  'DAD' => minh,
  'NANNY' => lan,
  // A Người chăm sóc with "Ghi khoản đã chi" (the harness's NANNY_SPEND).
  'NANNY_SPEND' => member(
    'u_lan2',
    'Cô Hằng',
    MemberRole.caregiver,
    Relation.nanny,
    extra: const ExtraRights(recordSpending: true),
  ),
  'AUNT' => member(
    'u_thu',
    'Dì Thu',
    MemberRole.relative,
    Relation.other,
    extra: const ExtraRights(viewDailyCare: true),
  ),
  'GRANDMA' => hoa,
  _ => mai,
};

/// A replay pump: the chat screen at '/', every other route a stub, a tall phone so the whole
/// thread is built, optional large text; never `pumpAndSettle` (a live timer line keeps ticking).
Future<void> _pump(
  WidgetTester tester, {
  required FakeAssistantRepository repo,
  required Membership me,
  required Map<String, Object> prefs,
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      environmentProvider.overrideWithValue(AppEnvironment.dev),
      providerDisplayNameProvider.overrideWithValue(null),
      minuteClockProvider.overrideWith(
        (ref) => Stream.value(DateTime(2026, 10, 15, 14, 20)),
      ),
      ...assistantOverrides(repo: repo, me: me),
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(375, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final screen = AssistantChatScreen(scopeKey: teddyScope.key);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: screen,
        ),
      ),
      GoRoute(
        path: '/:a/:b/:c/:d',
        builder: (_, _) => const Scaffold(body: Text('stub')),
      ),
      GoRoute(
        path: '/:a/:b/:c',
        builder: (_, _) => const Scaffold(body: Text('stub')),
      ),
      GoRoute(
        path: '/:a/:b',
        builder: (_, _) => const Scaffold(body: Text('stub')),
      ),
      GoRoute(
        path: '/:a',
        builder: (_, _) => const Scaffold(body: Text('stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 1600),
          disableAnimations: true,
        ),
        child: MaterialApp.router(
          theme: buildClTheme(ClPalette.light),
          locale: const Locale('vi'),
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
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Every visible string under [of].
List<String> _texts(WidgetTester tester, Finder of) => [
  for (final w in tester.widgetList<RichText>(
    find.descendant(of: of, matching: find.byType(RichText)),
  ))
    w.text.toPlainText(),
];

/// A property of a widget that may not exist in every app build (read dynamically).
Object? _prop(Object w, Object? Function(dynamic w) read) {
  try {
    return read(w);
  } catch (_) {
    return null;
  }
}

bool _enabled(Object? action) =>
    action != null && _prop(action, (a) => a.onPressed) != null;

/// Actions that only throw the draft away (never a way forward).
final _vi = lookupAppLocalizations(const Locale('vi'));
final _discardLabels = {_vi.asRemove, _vi.asNoThanks, _vi.asDiscardAll};
bool _isDiscard(String label) => _discardLabels.contains(label);

bool _hasType(WidgetTester tester, Finder of, String type) => find
    .descendant(
      of: of,
      matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == type),
    )
    .evaluate()
    .isNotEmpty;

class _Violation {
  _Violation(this.code, this.severity, this.detail);
  final String code;
  final String severity;
  final String detail;
  Map<String, String> toJson() => {
    'code': code,
    'severity': severity,
    'detail': detail,
  };
}

Future<List<_Violation>> _check(
  WidgetTester tester,
  Map<String, dynamic> snap,
  String who,
  String label,
) async {
  final out = <_Violation>[];
  final task = snap['task'] as Map<String, dynamic>;
  final drafts = [
    for (final d in snap['drafts'] as List) d as Map<String, dynamic>,
  ];
  final viewer = who == 'AUNT' || who == 'GRANDMA';
  final error = tester.takeException();
  if (error != null) {
    out.add(_Violation('RENDER_ERROR', 'P0', '$error'.split('\n').first));
    return out;
  }
  // ---- The server's question: its chips are on screen ----
  if (task['state'] == 'awaiting_clarification' &&
      task['clarification'] is Map) {
    final cl = task['clarification'] as Map<String, dynamic>;
    for (final c in cl['choices'] as List) {
      final text = ((c as Map)['label'] as Map)['vi'] as String;
      if (find.textContaining(text, findRichText: true).evaluate().isEmpty) {
        out.add(_Violation('CHIP_NOT_SHOWN', 'P0', '${cl['field']}: "$text"'));
      }
    }
  }
  // ---- Drafts ↔ cards ----
  final cardFinder = find.byType(AsDraftCard);
  final receiptFinder = find.byType(AsReceiptCard);
  final cards = tester.widgetList<AsDraftCard>(cardFinder).toList();
  final receipts = tester.widgetList<AsReceiptCard>(receiptFinder).toList();
  final used = <int>{};
  var receiptAt = 0;
  final bars = tester.widgetList<AsBatchBar>(find.byType(AsBatchBar)).toList();
  for (final d in drafts) {
    final state = d['state'] as String;
    final pending = state == 'draft' || state == 'needs_review';
    if (!pending || viewer) continue;
    final payload = d['payload'] as Map<String, dynamic>;
    final kind = payload['kind'] as String;
    final flagged = {
      for (final f in d['missingFields'] as List) '$f',
      for (final f in d['uncertainFields'] as List) '$f',
    };
    final problems = [for (final p in d['problems'] as List) '$p'];
    final review = state == 'needs_review' || flagged.isNotEmpty;
    final expired = DateTime.parse(
      d['expiresAt'] as String,
    ).isBefore(DateTime.utc(2026, 10, 15, 7, 20));
    if (expired) continue;
    // Find the card.
    Finder? cardOf;
    List<String> texts = const [];
    var fixControl = false;
    var saveable = false;
    var named = <String>{};
    if (kind == 'expense' && receiptAt < receipts.length) {
      final i = receiptAt++;
      final r = receipts[i];
      cardOf = receiptFinder.at(i);
      texts = _texts(tester, cardOf);
      for (final f in r.fields) {
        if (f.flagged && f.onTap != null) fixControl = true;
        if (f.flagged) named.add(f.label.toLowerCase());
      }
      if (r.actions.any((a) => _enabled(a) && !_isDiscard(a.label))) {
        fixControl = true;
      }
      // A suspected duplicate saves after "Vẫn lưu" (an explicit acknowledgement): forward.
      saveable =
          _enabled(r.primary) ||
          (r.duplicate != null && r.duplicate!.onAcknowledge != null);
    } else {
      final i = [
        for (var j = 0; j < cards.length; j++)
          if (!used.contains(j) &&
              (_prop(cards[j], (c) => (c.kind as Enum?)?.name) == kind))
            j,
      ].firstOrNull;
      if (i == null) {
        out.add(
          _Violation(
            'DRAFT_NOT_SHOWN',
            'P0',
            'a $kind draft has no card (the app cannot show or save it)',
          ),
        );
        continue;
      }
      used.add(i);
      final c = cards[i];
      cardOf = cardFinder.at(i);
      texts = _texts(tester, cardOf);
      fixControl =
          c.onTap != null ||
          c.actions.any((a) => _enabled(a) && !_isDiscard(a.label)) ||
          _hasType(tester, cardOf, 'AsFixPanel');
      final primary = _prop(c, (w) => w.primary);
      final ticked = c.selected == true;
      saveable =
          (ticked && bars.any((b) => b.count > 0 && b.onSave != null)) ||
          _enabled(primary) ||
          c.actions.any(
            (a) => _enabled(a) && a.label.toLowerCase().contains('lưu'),
          );
    }
    final cardText = texts
        .where((t) => t != (payload['title'] ?? ''))
        .join(' \n ')
        .toLowerCase();
    if (review || problems.isNotEmpty) {
      for (final f in flagged) {
        final words = _wordsFor(kind, f);
        if (!words.any(cardText.contains) &&
            !named.any((n) => words.any(n.contains))) {
          out.add(
            _Violation(
              'FIELD_NOT_NAMED',
              'P1',
              '$kind: "$f" needs review but the card never names it (${words.join('/')})',
            ),
          );
        }
      }
      if (!fixControl) {
        out.add(
          _Violation(
            'NO_FIX_CONTROL',
            'P0',
            '$kind (${flagged.join(',')}${problems.isEmpty ? '' : ' ${problems.join(',')}'}): nothing on the card fixes it (${_editorFor(kind) ? 'editor exists' : 'no editor'}) — dead end',
          ),
        );
      }
    } else if (!saveable) {
      out.add(
        _Violation(
          'READY_NOT_SAVEABLE',
          'P0',
          '$kind is clean on the server but the app offers no enabled save',
        ),
      );
    }
  }
  return out;
}

void main() {
  // `--dart-define=REPLAY_FIXTURES=<dir>` replays another set (e.g. a live run's snapshots).
  const other = String.fromEnvironment('REPLAY_FIXTURES');
  final dir = Directory(other.isEmpty ? '$_root/fixtures' : other);
  final files = dir.existsSync()
      ? (dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];
  final results = File('build/assistant_replay/results.jsonl');
  setUpAll(() {
    results.parent.createSync(recursive: true);
    if (results.existsSync()) results.deleteSync();
  });

  test('field_controls.json names a control the editor has (labels exist)', () {
    final l10n = lookupAppLocalizations(const Locale('vi'));
    final labels = {
      'asFieldAmount': l10n.asFieldAmount,
      'asFieldWhen': l10n.asFieldWhen,
      'asFieldMinutes': l10n.asFieldMinutes,
      'asFieldSide': l10n.asFieldSide,
      'asFieldStore': l10n.asFieldStore,
      'asFieldDate': l10n.asFieldDate,
      'asFieldTotal': l10n.asFieldTotal,
      'asFieldCategory': l10n.asFieldCategory,
      'asFieldTitle': l10n.asFieldTitle,
      'asFieldTime': l10n.asFieldTime,
      // LUMI-01: the pump's start, the measurement's fields.
      'asFieldStart': l10n.asFieldStart,
      'asFieldWeight': l10n.asFieldWeight,
      'asFieldLength': l10n.asFieldLength,
      'asFieldMeasuredOn': l10n.asFieldMeasuredOn,
    };
    for (final k in (_controls['kinds'] as Map<String, dynamic>).values) {
      for (final f in ((k as Map)['fields'] as Map).values) {
        final control = (f as Map)['control'] as String;
        if (labels.containsKey(control)) {
          expect(labels[control], isNotEmpty, reason: control);
        }
      }
    }
  });

  for (final file in files) {
    final fx = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final id = fx['id'] as String;
    final device = file.path.contains('/device/');
    final key = device ? 'device/$id' : id;
    final known = {
      for (final c in ((_known[key] as Map?)?['codes'] as List?) ?? const [])
        '$c',
    };
    group(key, () {
      for (final step in fx['steps'] as List) {
        final s = step as Map<String, dynamic>;
        final label = s['label'] as String;
        final snap = s['snapshot'] as Map<String, dynamic>;
        final task = snap['task'] as Map<String, dynamic>;
        final who = (s['as'] as String?) ?? 'MOM';
        final me = _member(who);
        testWidgets(label, (tester) async {
          final repo = FakeAssistantRepository(
            tasks: {task['id'] as String: snap},
          );
          final prefs = <String, Object>{
            'assistant.conversation.${me.uid}:${teddyScope.key}':
                task['conversationId'] as String,
            'assistant.tasks.${me.uid}:${teddyScope.key}': [
              task['id'] as String,
            ],
          };
          await _pump(tester, repo: repo, me: me, prefs: prefs);
          final violations = await _check(tester, snap, who, label);
          // Large text (Android "Largest" / iOS larger accessibility sizes): nothing overflows.
          if ((snap['drafts'] as List).isNotEmpty ||
              task['state'] == 'awaiting_clarification') {
            await _pump(
              tester,
              repo: FakeAssistantRepository(
                tasks: {task['id'] as String: snap},
              ),
              me: me,
              prefs: prefs,
              textScale: 2,
            );
            final e = tester.takeException();
            if (e != null) {
              violations.add(
                _Violation('LARGE_TEXT_OVERFLOW', 'P1', '$e'.split('\n').first),
              );
            }
          }
          // Unmount and let pending zero-length timers run (stream providers, prefs).
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
          results.writeAsStringSync(
            '${jsonEncode({'fixture': key, 'step': label, 'violations': violations.map((v) => v.toJson()).toList()})}\n',
            mode: FileMode.append,
          );
          final unexpected = [
            for (final v in violations)
              if (_strict || !known.contains(v.code))
                '${v.severity} ${v.code}: ${v.detail}',
          ];
          expect(unexpected, isEmpty, reason: '$key · $label');
        });
      }
    });
  }
}
