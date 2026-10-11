import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/timer_models.dart';
import 'package:child_life/features/glance/glance_bridge.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:child_life/l10n/glance_copy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';

// S8: the iOS widgets and Live Activities read every string from the snapshot's copy map (or, for
// the gallery, from Localizable.xcstrings). These tests keep the Swift side, the ARB catalogs and
// the generated files in step, so a renamed key never shows a Vietnamese fallback in English.

String _swift(String dir) => [
  for (final f in Directory(dir).listSync(recursive: true))
    if (f is File && f.path.endsWith('.swift')) f.readAsStringSync(),
].join('\n');

Set<String> _matches(String source, String pattern) => {
  for (final m in RegExp(pattern).allMatches(source))
    for (var i = 1; i <= m.groupCount; i++)
      if (m.group(i) != null) m.group(i)!,
};

void main() {
  final swift =
      _swift('ios/Shared') + _swift('ios/widget') + _swift('ios/Runner');
  final live = File('ios/widget/LockAndLive.swift').readAsStringSync();
  final l10ns = {
    for (final code in ['vi', 'en']) code: lookupAppLocalizations(Locale(code)),
  };

  group('glance copy', () {
    test('every key the Swift side reads is in the copy map (vi and en)', () {
      final keys = {
        ..._matches(swift, r'text\("([A-Za-z.]+)"'),
        ..._matches(
          live,
          r'\bt\((?:a|attributes), (?:compact \? )?"([A-Za-z.]+)"(?: : "([A-Za-z.]+)")?',
        ),
        // Built with string interpolation in Swift.
        for (final s in ['left', 'right']) 'breastSide.$s',
        for (final k in DiaperKind.values) 'diaper.${k.name}',
        for (final p in ['dur', 'durS'])
          for (final u in ['m', 'h', 'hm']) '$p.$u',
        for (final n in ['doneTitle', 'failedTitle', 'wifiTitle'])
          for (final v in ['', '.one']) 'upload.$n$v',
      }..remove('title'); // Filled in by the uploader ("Kỷ niệm của Teddy").
      expect(keys.length, greaterThan(40));
      for (final MapEntry(key: code, value: l) in l10ns.entries) {
        final copy = glanceCopy(l);
        final missing = keys.where((k) => !copy.containsKey(k)).toList();
        expect(missing, isEmpty, reason: 'missing in $code');
      }
    });

    test('the Live Activity carries every key it reads', () {
      final list = RegExp(
        r'let keys = \[([^\]]*)\]',
      ).firstMatch(File('ios/Shared/GlanceLive.swift').readAsStringSync())!;
      final carried = _matches(list.group(1)!, r'"([A-Za-z.]+)"');
      final read = {
        ..._matches(
          live,
          r'\bt\((?:a|attributes), (?:compact \? )?"([A-Za-z.]+)"(?: : "([A-Za-z.]+)")?',
        ),
        'breastSide.left',
        'breastSide.right',
      };
      expect(read.difference(carried), isEmpty);
    });

    test('the upload Live Activity carries every key it reads', () {
      final list = RegExp(r'let keys = \[([^\]]*)\]').firstMatch(
        File('ios/Runner/BackgroundUploads.swift').readAsStringSync(),
      )!;
      final carried = {..._matches(list.group(1)!, r'"([A-Za-z.]+)"'), 'title'};
      final read = _matches(
        File('ios/widget/UploadLive.swift').readAsStringSync(),
        r'a\.text\("([A-Za-z.]+)"',
      );
      expect(read, isNotEmpty);
      expect(read.difference(carried), isEmpty);
    });

    test('placeholders stay as {x} templates', () {
      final copy = glanceCopy(l10ns['en']!);
      expect(copy['since'], contains('{time}'));
      expect(copy['since'], contains('{name}'));
      expect(copy['dur.hm'], allOf(contains('{h}'), contains('{m}')));
    });
  });

  group('widget gallery strings', () {
    final catalog =
        jsonDecode(File('ios/widget/Localizable.xcstrings').readAsStringSync())
            as Map<String, dynamic>;
    final strings = catalog['strings'] as Map<String, dynamic>;

    test('Localizable.xcstrings matches the ARB catalogs', () {
      for (final code in ['vi', 'en']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
                as Map<String, dynamic>;
        final ids = arb.keys.where((k) => k.startsWith('glanceGallery'));
        expect(ids.toSet(), strings.keys.toSet());
        for (final id in ids) {
          final unit =
              (strings[id] as Map)['localizations'][code]['stringUnit'] as Map;
          expect(
            unit['value'],
            arb[id],
            reason: '$id ($code): run python3 tool/s8_widget_strings.py',
          );
        }
      }
    });

    test('every gallery key the widgets use is in the catalog', () {
      final used = {
        ..._matches(
          swift,
          r'(?:configurationDisplayName|description)\("([A-Za-z]+)"\)',
        ),
        ..._matches(
          swift,
          r'smallConfiguration\("[^"]+", "[a-z]+", "([A-Za-z]+)", "([A-Za-z]+)"\)',
        ),
      };
      expect(used, hasLength(18));
      expect(used.difference(strings.keys.toSet()), isEmpty);
    });
  });

  test('a widget tile asks Hôm nay to open its log (?log=<type>)', () {
    expect(widgetLogRequest(Uri.parse('/today?log=bottle')), 'bottle');
    expect(widgetLogRequest(Uri.parse('/today?log=sleep')), 'sleep');
    expect(widgetLogRequest(Uri.parse('/today')), isNull);
    expect(widgetLogRequest(Uri.parse('/memories?log=bottle')), isNull);
    expect(widgetLogRequest(Uri.parse('/today?log=growth')), isNull);
  });

  group('buildGlanceSnapshot', () {
    final en = l10ns['en']!;
    Map<String, Object?> build({
      Membership? me,
      List<CareRecord> records = const [],
      CareTimer? sleep,
    }) => buildGlanceSnapshot(
      l10n: en,
      locale: 'en',
      now: careNow,
      projectId: 'child-life-dev',
      apiKey: 'test-key',
      emulatorHost: null,
      me: me,
      nickname: 'Teddy',
      zone: 'Asia/Ho_Chi_Minh',
      records: records,
      sleep: sleep,
      breast: null,
    );

    test('signed out: no baby, no person, but the copy is there', () {
      final s = build();
      expect(s['signedIn'], isFalse);
      expect(s['canLog'], isFalse);
      expect(s.containsKey('babyId'), isFalse);
      expect(s.containsKey('uid'), isFalse);
      expect((s['copy']! as Map).isNotEmpty, isTrue);
    });

    test('today totals, newest entries and "You" for my own logs', () {
      final records = [
        rec(CareType.diaper, vn(8, 14, 50), minh, diaper: DiaperKind.dirty),
        rec(
          CareType.bottle,
          vn(8, 14, 0),
          mai,
          amountMl: 120,
          milk: MilkType.formula,
        ),
        rec(CareType.sleep, vn(8, 11, 0), mai, endedAt: vn(8, 12, 30)),
        rec(CareType.bottle, vn(8, 10, 0), minh, amountMl: 90),
        // Yesterday: not in today's totals.
        rec(CareType.bottle, vn(7, 22, 0), mai, amountMl: 150),
      ];
      final s = build(me: mai, records: records);
      expect(s['signedIn'], isTrue);
      expect(s['canLog'], isTrue);
      expect(s['uid'], mai.uid);
      expect(s['bottlesToday'], 2);
      expect(s['bottleMlToday'], 210);
      expect(s['feedsToday'], 2);
      expect(s['diapersToday'], 1);
      expect(s['sleptTodayMin'], 90);
      expect(s['lastSleepMin'], 90);
      final lastBottle = s['lastBottle']! as Map;
      expect(lastBottle['amountMl'], 120);
      expect(lastBottle['by'], en.glanceYou);
      expect((s['lastDiaper']! as Map)['by'], isNot(en.glanceYou));
      final recent = s['recent']! as List;
      expect(recent, hasLength(3));
      expect((recent.first as Map)['type'], 'diaper');
    });

    test('relatives see the widgets but cannot log', () {
      expect(build(me: hoa)['canLog'], isFalse);
    });

    test('a running sleep timer is passed with its start and author', () {
      final timer = CareTimer.start(
        type: TimerType.sleep,
        me: mai,
        now: vn(8, 14, 30),
      );
      final sleep = build(me: mai, sleep: timer)['sleep']! as Map;
      expect(sleep['sessionId'], timer.sessionId);
      expect(sleep['startedAt'], vn(8, 14, 30).millisecondsSinceEpoch);
      expect(sleep['byName'], en.glanceYou);
      expect(sleep['left'], isNull);
    });

    test('no child photos, captions or dates of birth in the snapshot', () {
      // The copy strings may say "photos"; the data must not carry any.
      final json = jsonEncode({...build(me: mai)}..remove('copy'));
      for (final word in ['photo', 'caption', 'dateOfBirth', 'storagePath']) {
        expect(json.contains(word), isFalse, reason: word);
      }
    });
  });
}
