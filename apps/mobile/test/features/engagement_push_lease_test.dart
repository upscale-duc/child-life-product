import 'package:child_life/features/engagement/engagement_repository.dart';
import 'package:child_life/features/notifications/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Owner, 2026-10-26: no "Gợi ý" push in the morning. The lease the app sends with
/// getEngagement read the notification permission before it had loaded, said "not allowed",
/// and the server kept every suggestion in-app only for 30 days.
void main() {
  test(
    'the lease waits for the real permission, not "still loading"',
    () async {
      final container = ProviderContainer(
        overrides: [
          osNotificationsEnabledProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return true;
          }),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(engagementPushAllowedProvider, (_, _) {});
      addTearDown(sub.close);
      // What the old code read at this moment: nothing yet (sent as false).
      expect(container.read(osNotificationsEnabledProvider).value, isNull);
      expect(
        await container.read(engagementPushAllowedProvider.future),
        isTrue,
      );
    },
  );

  test('a permission that cannot be read is "not allowed"', () async {
    final container = ProviderContainer(
      overrides: [
        osNotificationsEnabledProvider.overrideWith(
          (ref) async => throw StateError('no plugin'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(engagementPushAllowedProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(engagementPushAllowedProvider.future), isFalse);
  });
}
