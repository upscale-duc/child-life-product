import 'package:child_life/features/care/visit_report.dart';
import 'package:child_life/features/premium/premium_models.dart';
import 'package:child_life/features/rhythm/coming_up_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/rhythm_fixtures.dart';
import '../helpers/router_pump.dart';

// D-147 (the app is not live; purchase comes later): Premium parts that used to be hidden for a
// Free household show as invites that open Premium.
void main() {
  Capabilities caps(Map<String, Object?> json) => Capabilities.fromJson(json)!;

  test(
    '"Chuẩn bị đi khám": Premium opens it, Free is invited, nothing else shows',
    () {
      final premium = caps(rhythmCaps(plan: 'premium', groupA: true));
      final free = caps(rhythmCaps());
      expect(visitReportAllowed(mai, premium), isTrue);
      expect(visitReportInvite(mai, premium), isFalse);
      expect(visitReportAllowed(mai, free), isFalse);
      expect(visitReportInvite(mai, free), isTrue);
      // A plan not known yet (D-125) or another reason is never an invite.
      expect(visitReportInvite(mai, null), isFalse);
      expect(
        visitReportInvite(mai, caps(rhythmCaps(reason: 'REGION_UNAVAILABLE'))),
        isFalse,
      );
      expect(
        visitReportInvite(mai, caps(rhythmCaps(reason: 'ROLE_DENIED'))),
        isFalse,
      );
    },
  );

  testWidgets('"Sắp tới" invite says what Premium shows and opens Premium', (
    tester,
  ) async {
    final (visits, _) = await pumpRouted(
      tester,
      const Scaffold(body: ComingUpInvite(babyName: 'Teddy')),
    );
    expect(find.textContaining('Nhật ký của Teddy đã đủ'), findsOneWidget);
    expect(find.text('Có trong Premium'), findsOneWidget);
    await tester.tap(find.text('Xem Premium'));
    await tester.pumpAndSettle();
    expect(visits.last.location, contains('card=rhythm'));
  });
}
