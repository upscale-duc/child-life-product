import 'dart:io';

import 'package:child_life/features/adaptive/adaptive_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every Hôm nay widget the app can save must be accepted by the contract and the Firestore
/// rules. P-181 added `care_duty` to the app only: every "Xong" in Tuỳ chỉnh Hôm nay that listed it
/// was refused by the server and silently undone (owner, 2026-10-26: "ko có tác dụng gì").
void main() {
  final root = Directory.current.path.endsWith('mobile') ? '../..' : '.';
  final contract = File(
    '$root/packages/contracts/src/adaptive.ts',
  ).readAsStringSync();
  final rules = File('$root/firebase/firestore.rules').readAsStringSync();
  final widgetList = RegExp(
    r'function validWidgetList\(l\) \{[\s\S]*?\}',
  ).firstMatch(rules)!.group(0)!;
  final goalsLine = RegExp(
    r'd\.goals\.hasOnly\(\[[^\]]*\]\)',
  ).firstMatch(rules)!.group(0)!;

  test('every WidgetId is in the contract and the rules', () {
    for (final id in WidgetId.values) {
      expect(
        contract,
        contains("'${id.wire}'"),
        reason: '${id.wire} missing in the contract',
      );
      expect(
        widgetList,
        contains("'${id.wire}'"),
        reason: '${id.wire} missing in the rules',
      );
    }
    expect(widgetList, contains('l.size() <= ${WidgetId.values.length}'));
  });

  test('every Goal is in the rules', () {
    for (final g in Goal.values) {
      expect(
        goalsLine,
        contains("'${g.wire}'"),
        reason: '${g.wire} missing in the rules',
      );
    }
  });
}
