import 'package:child_life/features/rhythm/wake_check.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 10, 25, 2);
  final plan = (
    babyId: 'b_teddy',
    sessionId: 'a' * 32,
    start: start,
    fireAt: start.add(const Duration(minutes: 105)),
  );

  test('L6 words: the time asleep, no baby name, never a verdict', () {
    final vi = wakeCheckNotification(
      lookupAppLocalizations(const Locale('vi')),
      plan,
    );
    expect(vi.title, 'Bé dậy chưa?');
    expect(
      vi.body,
      'Bé đã ngủ 1 giờ 45 phút. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé.',
    );
    expect(vi.body, isNot(contains('Teddy')));
    final en = wakeCheckNotification(
      lookupAppLocalizations(const Locale('en')),
      plan,
    );
    expect(en.title, 'Is your baby awake?');
    expect(en.fireAt, plan.fireAt);
  });

  test('a tap finds its baby; other payloads are not ours', () {
    final n = wakeCheckNotification(
      lookupAppLocalizations(const Locale('vi')),
      plan,
    );
    expect(wakeCheckOfPayload(n.payload), 'b_teddy');
    expect(wakeCheckOfPayload('{"k":"reminder","b":"b_teddy"}'), isNull);
    expect(wakeCheckOfPayload('not json'), isNull);
  });

  test('ids stay apart from reminders, the digest and Nhịp lớn lên', () {
    for (final id in ['b_teddy', 'b_na', 'b_${'f' * 28}']) {
      final n = wakeCheckNotificationId(id);
      expect(n, greaterThanOrEqualTo((1 << 28) + 0x100));
      expect(n, lessThan(1 << 29));
    }
  });
}
