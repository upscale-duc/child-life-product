import 'package:child_life/features/assistant/assistant_time.dart';
import 'package:child_life/l10n/app_localizations_en.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Linked time editing for Lumi's drafts and time questions (owner feedback 2026-10-15: a
/// 9-hour sleep whose start is picked must keep its 9 hours). Hồ Chí Minh is UTC+7, so
/// 21:00 there is 14:00Z.
void main() {
  setUpAll(() => initializeDateFormatting('vi'));
  const zone = 'Asia/Ho_Chi_Minh';
  // 2026-10-15 14:20 in Hồ Chí Minh.
  final now = DateTime.utc(2026, 10, 15, 7, 20);
  DateTime vn(int day, int h, [int m = 0]) =>
      DateTime.utc(2026, 10, day, h - 7, m);

  group('LinkedSpan', () {
    final nine = LinkedSpan(vn(14, 21), vn(15, 6));

    test('a new start keeps the length: the end follows', () {
      final next = nine.withStart(vn(14, 22));
      expect(next.start, vn(14, 22));
      expect(next.end, vn(15, 7));
      expect(next.minutes, 9 * 60);
    });

    test('a new length moves the end, clamped', () {
      expect(nine.withMinutes(8 * 60).end, vn(15, 5));
      expect(nine.withMinutes(1).minutes, minSpanMinutes);
      expect(nine.withMinutes(30 * 60).minutes, maxSpanMinutes);
    });

    test('a new end changes the length only', () {
      final next = nine.withEnd(vn(15, 7, 30));
      expect(next.start, nine.start);
      expect(next.minutes, 10 * 60 + 30);
    });
  });

  group('wall times across midnight', () {
    test(
      'pickStart: 21:00 for a 9-hour sleep reported at 14:20 is last night',
      () {
        // "Bé ngủ 9 tiếng", known length only: guessed as ending now.
        final guess = LinkedSpan.endingAt(now, 9 * 60);
        final picked = pickStart(guess, zone, 21, 0, now: now);
        expect(picked.start, vn(14, 21));
        expect(picked.end, vn(15, 6));
        expect(picked.minutes, 540);
      },
    );

    test('pickStart keeps the day nearest the current start', () {
      final span = LinkedSpan(vn(14, 21), vn(15, 6));
      expect(pickStart(span, zone, 22, 30, now: now).start, vn(14, 22, 30));
      // 01:00 is nearer to 21:00 yesterday as the next morning (4 h) than 20 h before.
      final early = pickStart(span, zone, 1, 0, now: now);
      expect(early.start, vn(15, 1));
      expect(early.end, vn(15, 10));
    });

    test('pickStart never starts after now', () {
      // A nap 13:00–14:00 moved to 13:50 ends at 14:50 (> 14:20 now): it stays today and the
      // form flags the future time (no silent jump to yesterday).
      final nap = LinkedSpan(vn(15, 13), vn(15, 14));
      final next = pickStart(nap, zone, 13, 50, now: now);
      expect(next.start, vn(15, 13, 50));
      // 23:00 for a 9-hour sleep is last night; 15:00 for a nap today (not yet 15:00) is
      // yesterday's.
      final night = LinkedSpan(vn(14, 21), vn(15, 6));
      expect(pickStart(night, zone, 23, 0, now: now).start, vn(14, 23));
      expect(pickStart(nap, zone, 15, 0, now: now).start, vn(14, 15));
    });

    test('pickEnd: an end before the start clock crosses midnight', () {
      final span = LinkedSpan(vn(14, 21), vn(14, 22));
      final next = pickEnd(span, zone, 6, 0);
      expect(next.end, vn(15, 6));
      expect(next.minutes, 9 * 60);
      // Later the same evening stays the same day.
      expect(pickEnd(span, zone, 23, 15).end, vn(14, 23, 15));
    });

    test('wallAfter / wallBefore stay within a day', () {
      expect(wallAfter(zone, 6, 0, vn(14, 21)), vn(15, 6));
      expect(wallBefore(zone, 21, 0, vn(15, 6)), vn(14, 21));
    });
  });

  group('labels', () {
    final vi = AppLocalizationsVi();
    final en = AppLocalizationsEn();

    test(
      'cross-midnight start says "hôm qua"; a same-day span says no day',
      () {
        final night = LinkedSpan(vn(14, 21), vn(15, 6));
        expect(
          spanLine(vi, 'vi', night, zone, now),
          '21:00 hôm qua – 06:00 · 9 giờ',
        );
        expect(
          spanLine(en, 'en', night, zone, now),
          '21:00 yesterday – 06:00 · 9 h',
        );
        final nap = LinkedSpan(vn(15, 9), vn(15, 10, 30));
        expect(
          spanLine(vi, 'vi', nap, zone, now),
          '09:00 – 10:30 · 1 giờ 30 phút',
        );
        // A span that ended yesterday names that day on its end.
        final earlier = LinkedSpan(vn(13, 21), vn(14, 6));
        expect(
          spanLine(vi, 'vi', earlier, zone, now),
          '21:00 13/10 – 06:00 hôm qua · 9 giờ',
        );
      },
    );

    test(
      'an end before the start reads as a problem, not a negative length',
      () {
        final wrong = LinkedSpan(vn(15, 10), vn(15, 9));
        expect(
          spanLine(vi, 'vi', wrong, zone, now),
          contains('giờ dậy trước giờ ngủ'),
        );
      },
    );
  });

  group('spokenDurationMinutes', () {
    test('hours, half hours and minutes as parents say them', () {
      expect(spokenDurationMinutes('Bé ngủ 9 tiếng'), 540);
      expect(spokenDurationMinutes('con ngủ được 1 tiếng rưỡi'), 90);
      expect(spokenDurationMinutes('ngủ 2 tiếng 15 phút'), 135);
      expect(spokenDurationMinutes('bú mẹ 20 phút'), 20);
      expect(spokenDurationMinutes('slept for 2 hours'), 120);
      expect(spokenDurationMinutes('napped 1.5 hours'), 90);
    });

    test('clock times are never durations', () {
      expect(spokenDurationMinutes('ngủ lúc 9 giờ'), isNull);
      expect(spokenDurationMinutes('ngủ từ 21h tới 6h'), isNull);
      expect(spokenDurationMinutes('con bú 120 ml'), isNull);
      expect(spokenDurationMinutes('ngủ 40 tiếng'), isNull);
    });
  });

  test('time questions and their end', () {
    expect(isTimeField('time.missing'), isTrue);
    expect(isTimeField('sleep.start'), isTrue);
    expect(isTimeField('sleep.end'), isTrue);
    expect(isTimeField('sleep.period'), isFalse);
    expect(isTimeField('intent'), isFalse);
    expect(isEndField('sleep.end'), isTrue);
    expect(isEndField('sleep.start'), isFalse);
    expect(hhmm(6, 5), '06:05');
  });
}
