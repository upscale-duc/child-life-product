import 'package:child_life/core/platform/device_heartbeat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P-137 activity heartbeat: once per local day per account and install, coarse device facts.
void main() {
  group('once per local day', () {
    test('the day is the local calendar date', () {
      expect(localDayKey(DateTime(2026, 10, 8, 0, 0)), '2026-10-08');
      expect(localDayKey(DateTime(2026, 10, 8, 23, 59, 59)), '2026-10-08');
      expect(localDayKey(DateTime(2026, 1, 2, 9)), '2026-01-02');
    });

    test(
      'due when never sent or sent on another day, not twice the same day',
      () {
        final morning = DateTime(2026, 10, 8, 7, 30);
        expect(heartbeatDue(null, morning), isTrue);
        expect(heartbeatDue('2026-10-07', morning), isTrue);
        expect(heartbeatDue('2026-10-08', morning), isFalse);
        expect(
          heartbeatDue('2026-10-08', DateTime(2026, 10, 8, 23, 59)),
          isFalse,
        );
        // Just after midnight is a new day.
        expect(heartbeatDue('2026-10-08', DateTime(2026, 10, 9, 0, 1)), isTrue);
        // A clock set back still sends once for that day.
        expect(heartbeatDue('2026-10-09', morning), isTrue);
      },
    );

    test('the schedule remembers the day per account and install', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const device = 'd_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final mai = HeartbeatSchedule(prefs, uid: 'u_mai', deviceId: device);
      final minh = HeartbeatSchedule(prefs, uid: 'u_minh', deviceId: device);
      final launch = DateTime(2026, 10, 8, 7);
      final resume = DateTime(2026, 10, 8, 21);

      expect(mai.isDue(launch), isTrue);
      await mai.markSent(launch);
      expect(mai.isDue(resume), isFalse, reason: 'same day: no second write');
      expect(
        minh.isDue(resume),
        isTrue,
        reason: 'another account on this phone',
      );
      expect(mai.isDue(DateTime(2026, 10, 9, 6)), isTrue, reason: 'next day');

      // Survives a restart (preferences, not memory).
      final again = HeartbeatSchedule(prefs, uid: 'u_mai', deviceId: device);
      expect(again.isDue(resume), isFalse);
    });
  });

  group('coarse device facts', () {
    test('model is one of the four Rules values, never a name', () {
      expect(
        coarseModel(TargetPlatform.iOS, shortestSide: 390, iosModel: 'iPhone'),
        'iPhone',
      );
      expect(
        coarseModel(TargetPlatform.iOS, shortestSide: 390, iosModel: 'iPad'),
        'iPad',
        reason: 'the OS-reported generic model wins',
      );
      expect(coarseModel(TargetPlatform.iOS, shortestSide: 820), 'iPad');
      expect(coarseModel(TargetPlatform.iOS, shortestSide: 0), 'iPhone');
      expect(
        coarseModel(TargetPlatform.android, shortestSide: 411),
        'Android phone',
      );
      expect(
        coarseModel(TargetPlatform.android, shortestSide: 600),
        'Android tablet',
      );
      for (final (platform, side) in const [
        (TargetPlatform.iOS, 300.0),
        (TargetPlatform.iOS, 900.0),
        (TargetPlatform.android, 300.0),
        (TargetPlatform.android, 900.0),
      ]) {
        expect(
          deviceModels,
          contains(coarseModel(platform, shortestSide: side)),
        );
      }
    });

    test(
      'OS version reads "iOS 26.1" / "Android 16", at most 40 characters',
      () {
        expect(osVersionLabel('iOS', '26.1'), 'iOS 26.1');
        expect(osVersionLabel('Android', '16'), 'Android 16');
        expect(osVersionLabel('Android', ''), 'Android');
        expect(osVersionLabel('Android', 'x' * 60).length, 40);
      },
    );
  });
}
