import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:child_life/core/privacy/local_privacy.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/core/format/age.dart';
import 'package:child_life/features/library/content_calc.dart';
import 'package:child_life/features/library/content_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'cached bytes, files and playback are denied after sign-out/account switch/revocation',
    () async {
      final dir = Directory.systemTemp.createTempSync('privacy-test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final privacy = LocalPrivacy()
        ..bind('a', {'child'}, coParents: {'child'});
      String? uid = 'a';
      const path = 'babies/child/media/m/photo.jpg';
      final cache = File('${dir.path}/media-v2/a/${path.replaceAll('/', '_')}');
      await cache.parent.create(recursive: true);
      await cache.writeAsBytes([1, 2, 3]);
      final reader = StorageMediaBytes(
        owner: () => uid,
        cacheDirectory: () async => dir,
        access: privacy,
      );
      expect(await reader.read(path), [1, 2, 3]);
      expect((await reader.file(path)).path, cache.path);
      expect((await reader.playable(path)).uri, startsWith('file:'));
      privacy.bind(null, {});
      uid = null;
      await expectLater(() => reader.read(path), throwsStateError);
      await expectLater(reader.file(path), throwsStateError);
      privacy.bind('b', {'other'}, coParents: {'other'});
      uid = 'b';
      await expectLater(() => reader.read(path), throwsStateError);
      await expectLater(reader.playable(path), throwsStateError);
      privacy.bind('a', {});
      uid = 'a';
      await expectLater(() => reader.read(path), throwsStateError);
    },
  );
  test('membership expiry and generation invalidate in-flight results', () {
    final privacy = LocalPrivacy()..bind('a', {'child'}, coParents: {'child'});
    final epoch = privacy.authorize('a', 'babies/child/media/x/p.jpg');
    privacy.bind('a', {'child'}); // downgrade from co-parent to restricted role
    expect(() => privacy.check(epoch), throwsStateError);
    privacy.bind('a', {'child'}, until: {'child': DateTime(2000)});
    expect(
      () => privacy.authorize('a', 'babies/child/media/x/p.jpg'),
      throwsStateError,
    );
  });
  test(
    'calendar-month labels agree with content at month ends and leap birthdays',
    () {
      for (final (dob, today, expected) in [
        (DateTime(2026, 1, 31), DateTime(2026, 6, 30), 5),
        (DateTime(2026, 8, 31), DateTime(2026, 11, 30), 3),
        (DateTime(2024, 2, 29), DateTime(2025, 2, 28), 12),
      ]) {
        expect(babyAge(dob, today), (unit: AgeUnit.months, count: expected));
        expect(lbAgeIn(LbUnit.month, dob, today), expected);
      }
    },
  );
}
