import 'dart:io';
import 'package:child_life/app/account_local_scope.dart';
import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/features/auto_save/auto_save_controller.dart';
import 'package:child_life/features/auto_save/auto_save_native.dart';
import 'package:child_life/features/auto_save/auto_save_review.dart';
import 'package:child_life/features/auto_save/auto_save_today.dart';
import 'package:child_life/features/memories/upload_queue.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'changing UID disposes local notifiers and creates stores owned by the next account',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('account-scope');
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      messenger.setMockMethodCallHandler(paths, (_) async => dir.path);
      final owner = ValueNotifier<String>('a');
      UploadQueue? queue;
      AutoSaveController? auto;
      String? storeOwner;
      BuildContext? currentContext;
      BuildContext? rootContext;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            autoSaveNativeProvider.overrideWithValue(
              AutoSaveNative(supported: false),
            ),
            networkKindProvider.overrideWith(
              (ref) => Stream.value(NetworkKind.none),
            ),
          ],
          child: ValueListenableBuilder<String>(
            valueListenable: owner,
            builder: (context, uid, _) {
              rootContext = context;
              return AccountLocalScope(
                uid: uid,
                child: Consumer(
                  builder: (context, ref, _) {
                    ref.watch(uploadQueueProvider);
                    ref.watch(autoSaveProvider);
                    // Root-declared readers of the scoped controller (Hôm nay banner,
                    // Kỷ niệm tab dot, review "Đã có").
                    ref.watch(autoSaveBannerProvider);
                    ref.watch(autoSaveTabDotProvider);
                    ref.watch(alreadySavedProvider);
                    currentContext = context;
                    queue = ref.read(uploadQueueProvider.notifier);
                    auto = ref.read(autoSaveProvider.notifier);
                    storeOwner =
                        (ref.read(queueStoreProvider) as FileQueueStore).owner;
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      final firstContext = currentContext;
      final firstQueue = queue;
      final firstAuto = auto;
      expect(storeOwner, 'a');
      expect(
        ProviderScope.containerOf(rootContext!).exists(autoSaveProvider),
        false,
        reason: 'no second, unscoped AutoSaveController in the root container',
      );
      owner.value = 'b';
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(storeOwner, 'b');
      expect(identical(queue, firstQueue), false);
      expect(identical(auto, firstAuto), false);
      expect(firstContext!.mounted, false);
      // Rebuilding the same account retains its queue and stable override list.
      final second = queue;
      owner.notifyListeners();
      await tester.pump();
      expect(identical(queue, second), true);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      messenger.setMockMethodCallHandler(paths, null);
      owner.dispose();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      expect(tester.takeException(), isNull);
    },
  );
}
