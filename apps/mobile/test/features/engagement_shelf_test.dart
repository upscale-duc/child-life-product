import 'dart:async';

import 'package:child_life/features/engagement/engagement_repository.dart';
import 'package:child_life/features/engagement/engagement_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/router_pump.dart';

/// Something the real engagement list depends on (the media count, Tự lưu state) changing.
final _signal = NotifierProvider<_Signal, int>(_Signal.new);

class _Signal extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

Map<String, dynamic> _weekly() => {
  'enabled': true,
  'suggestions': [
    {'id': 'a' * 64, 'kind': 'ENG-03', 'context': 'current'},
  ],
};

void main() {
  // Owner, 2026-10-26: "chưa xem mà nó tự mất … mở app nó lại hiển thị rồi mất". A reload of the
  // list (which waits up to a minute) drew as loading and hid the card.
  testWidgets('a reload keeps the suggestion on screen until the new answer', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    var calls = 0;
    final (_, container) = await pumpRouted(
      tester,
      const Scaffold(body: SingleChildScrollView(child: EngagementShelf())),
      overrides: [
        engagementProvider.overrideWith((ref) {
          ref.watch(_signal);
          calls++;
          return calls == 1 ? Future.value(_weekly()) : pending.future;
        }),
      ],
    );
    expect(find.text('Nhìn lại tuần qua'), findsOneWidget);

    container.read(_signal.notifier).bump();
    await tester.pump();
    expect(calls, 2);
    expect(find.text('Nhìn lại tuần qua'), findsOneWidget);

    pending.complete(_weekly());
    await tester.pumpAndSettle();
    expect(find.text('Nhìn lại tuần qua'), findsOneWidget);
  });

  // Owner, 2026-10-31: "sao lại có gợi ý mỗi ngày trong mục kỉ niệm". It belongs to Hôm nay.
  testWidgets('Kỷ niệm leaves "Gợi ý mỗi ngày" to Hôm nay', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: SingleChildScrollView(child: EngagementShelf())),
      overrides: [
        engagementProvider.overrideWith(
          (ref) => Future.value({
            'enabled': true,
            'suggestions': [
              {'id': 'b' * 64, 'kind': 'ENG-06', 'context': 'current'},
              ..._weekly()['suggestions'] as List,
            ],
          }),
        ),
      ],
    );
    expect(find.text('Gợi ý mỗi ngày'), findsNothing);
    expect(find.text('Nhìn lại tuần qua'), findsOneWidget);
  });

  testWidgets('"…" offers Xem gợi ý, Để sau and Bỏ qua gợi ý', (tester) async {
    await pumpRouted(
      tester,
      const Scaffold(body: SingleChildScrollView(child: EngagementShelf())),
      overrides: [engagementProvider.overrideWith((ref) async => _weekly())],
    );
    await tester.tap(find.byKey(Key('engMore_${'a' * 64}')));
    await tester.pumpAndSettle();
    expect(find.text('Xem gợi ý'), findsOneWidget);
    expect(find.text('Để sau'), findsOneWidget);
    expect(find.text('Bỏ qua gợi ý'), findsOneWidget);
  });
}
