import 'package:child_life/core/appearance/appearance_providers.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/home/home_shell.dart';
import 'package:child_life/features/keepsakes/keepsake_card_view.dart';
import 'package:child_life/features/keepsakes/keepsake_catalog.dart';
import 'package:child_life/features/keepsakes/keepsake_occasions.dart';
import 'package:child_life/features/keepsakes/keepsake_resume.dart';
import 'package:child_life/features/keepsakes/memory_story_screens.dart';
import 'package:child_life/features/keepsakes/milestone_card_screens.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:child_life/features/memories/memory_models.dart';
import 'package:child_life/features/premium/billing_models.dart';
import 'package:child_life/features/premium/paywall_screen.dart';
import 'package:child_life/features/premium/plan_screen.dart';
import 'package:child_life/features/premium/premium_gate.dart';
import 'package:child_life/features/premium/premium_repository.dart';
import 'package:child_life/features/premium/purchase_controller.dart';
import 'package:child_life/features/premium/purchase_resume.dart';
import 'package:child_life/features/premium/store_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/keepsake_fixtures.dart';
import '../helpers/premium_fixtures.dart';
import '../helpers/router_pump.dart';
import 'premium_test.dart' show answer;

/// Premium Slice 4 on the phone (plan §7 B4, D-074): PR01 paywall, PR02 purchase states with a
/// fake store, MO03 resume of card and video drafts, PR03 management. Access always comes from
/// `getCapabilities` after the server verified, never from the store's word.

typedef Stubbed = ({List<String> visits, List<Object?> extras});

/// The app's PR01 route plus stub pages; [home] at '/'.
GoRouter _router(Widget home, Stubbed seen, {String initial = '/'}) {
  Widget stub(GoRouterState s) {
    seen.visits.add(s.uri.toString());
    seen.extras.add(s.extra);
    return const Scaffold(body: Text('stub'));
  }

  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      ...premiumRoutes(),
      GoRoute(path: '/:a/:b/:c', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a/:b', builder: (_, s) => stub(s)),
      GoRoute(path: '/:a', builder: (_, s) => stub(s)),
    ],
  );
}

class _Env {
  _Env({Map<String, Object?>? caps, StoreGateway? store, bool owner = true})
    : household = FakeHousehold(caps ?? answer(billing: true)),
      store = store ?? FakeStore(),
      me = owner ? mai : minh {
    billing = FakeBilling(
      onActive: () => household.json = answer(
        plan: 'premium',
        templates: true,
        owner: owner,
        billing: true,
      ),
    );
  }

  final FakeHousehold household;
  final StoreGateway store;
  final Membership me;
  late FakeBilling billing;
  final seen = (visits: <String>[], extras: <Object?>[]);

  FakeStore get fake => store as FakeStore;

  List<Override> get overrides => [
    selectedMembershipProvider.overrideWithValue(me),
    ...premiumOverrides(household: household, store: store, billing: billing),
    keepsakeCatalogProvider.overrideWith((ref) => Stream.value(seedCatalog())),
  ];
}

Future<ProviderContainer> _paywall(
  WidgetTester tester,
  _Env env, {
  PaywallEntry entry = PaywallEntry.templates,
  Locale locale = const Locale('vi'),
}) async {
  final (_, container) = await pumpRouted(
    tester,
    const SizedBox(),
    locale: locale,
    overrides: env.overrides,
    router: _router(
      const SizedBox(),
      env.seen,
      initial: paywallLocation(entry),
    ),
  );
  return container;
}

/// Lets sheets and routes finish; a busy button's spinner never settles, so no pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

CardDraft _cardDraft() {
  final t = seedCatalog().cards.firstWhere((t) => t.id == 'card_blush');
  return CardDraft(
    babyId: teddyId,
    occasion: Occasion.m1,
    date: DateTime(2026, 10, 17),
    format: KeepsakeFormat.portrait,
    template: t,
    palette: t.palette,
    quote: 'Một tháng yêu thương',
    photos: const [
      CardPhoto(
        StorageImage('babies/b1/media/m1/original.jpg'),
        align: Alignment(0.2, -0.4),
        zoom: 1.6,
      ),
    ],
  );
}

VideoDraft _videoDraft() => VideoDraft(
  babyId: teddyId,
  template: seedCatalog().videos.first,
  occasion: Occasion.m1,
  mediaIds: const ['m1', 'm2', 'm3'],
  title: 'Tháng đầu tiên',
  audience: Audience.family,
);

void main() {
  group('PR01 · paywall', () {
    testWidgets(
      'entry A without an open store: group A first, no dead button',
      (tester) async {
        final env = _Env(store: const UnavailableStoreGateway());
        await _paywall(tester, env, entry: PaywallEntry.rhythm);
        expect(find.text('Child Life Premium'), findsOneWidget);
        final a = tester.getTopLeft(find.text(answerGroupA)).dy;
        final b = tester.getTopLeft(find.text(answerGroupB)).dy;
        expect(a, lessThan(b));
        expect(find.text('Bạn đang xem'), findsOneWidget);
        expect(find.text('Gói nào cũng có'), findsOneWidget);
        expect(find.text('Mua trong app sắp có'), findsOneWidget);
        expect(find.text('Tiếp tục với Premium'), findsNothing);
        expect(find.text('Khôi phục'), findsNothing);
        expect(find.text('Điều khoản sử dụng'), findsOneWidget);
        expect(find.text('Quyền riêng tư'), findsOneWidget);
      },
    );

    testWidgets('entry B with the store open: storefront prices and terms', (
      tester,
    ) async {
      final env = _Env();
      await _paywall(tester, env);
      final a = tester.getTopLeft(find.text(answerGroupA)).dy;
      final b = tester.getTopLeft(find.text(answerGroupB)).dy;
      expect(b, lessThan(a));
      expect(find.text('Theo tháng'), findsOneWidget);
      expect(find.text('Theo năm'), findsOneWidget);
      expect(find.text('499.000 ₫'), findsOneWidget);
      // Yearly is preselected; its renewal sentence and the store's disclosure follow.
      expect(
        find.textContaining('499.000 ₫ mỗi năm, tự động gia hạn'),
        findsOneWidget,
      );
      expect(find.textContaining('tài khoản App Store'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theo tháng'));
      await tester.pump();
      expect(find.textContaining('59.000 ₫ mỗi tháng'), findsOneWidget);
      expect(find.text('Tiếp tục với Premium'), findsOneWidget);
      expect(find.text('Khôi phục'), findsOneWidget);
    });

    testWidgets('premium_billing off: nothing to buy even with products', (
      tester,
    ) async {
      final env = _Env(caps: answer());
      await _paywall(tester, env);
      expect(find.text('Mua trong app sắp có'), findsOneWidget);
      expect(find.text('Tiếp tục với Premium'), findsNothing);
    });

    testWidgets('no products configured: closed', (tester) async {
      final env = _Env(store: FakeStore(items: const []));
      await _paywall(tester, env);
      expect(find.text('Mua trong app sắp có'), findsOneWidget);
    });

    testWidgets('a member who is not the owner is asked to ask the owner', (
      tester,
    ) async {
      final env = _Env(caps: answer(owner: false, billing: true), owner: false);
      await _paywall(tester, env);
      expect(find.text('Nhờ chủ hộ nâng cấp'), findsOneWidget);
      expect(find.text('Tiếp tục với Premium'), findsNothing);
      expect(find.text('Khôi phục'), findsNothing);
    });

    testWidgets('a household that has Premium sees so, nothing to buy', (
      tester,
    ) async {
      final env = _Env(
        caps: answer(plan: 'premium', templates: true, billing: true),
      );
      await _paywall(tester, env);
      expect(find.text('Hộ đã có Premium'), findsWidgets);
      expect(find.text('Tiếp tục với Premium'), findsNothing);
    });

    testWidgets('a region without Premium says so instead of selling', (
      tester,
    ) async {
      final env = _Env(
        caps: answer(billing: true, rhythmReason: 'REGION_UNAVAILABLE'),
      );
      await _paywall(tester, env);
      expect(find.text('Hỗ trợ phù hợp chưa mở ở khu vực này'), findsOneWidget);
      expect(find.text('Tiếp tục với Premium'), findsNothing);
    });
  });

  group('PR02 · purchase states', () {
    testWidgets(
      'success: intent bound to the store, verified, then completed',
      (tester) async {
        final env = _Env();
        await _paywall(tester, env);
        await tester.tap(find.text('Tiếp tục với Premium'));
        await _settle(tester);
        expect(env.billing.starts.single, {
          'babyId': teddyId,
          'productKey': 'yearly',
          'provider': 'apple',
          'entryPoint': 'templates',
          'resume': null,
        });
        expect(env.fake.bought.single.accountToken, FakeBilling.intentId);
        expect(env.fake.completed, isEmpty);
        env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
        await _settle(tester);
        expect(env.billing.verifies.single.intentId, FakeBilling.intentId);
        expect(
          env.billing.verifies.single.purchase.transactionId,
          '2000000999',
        );
        // Completed only after the server answered.
        expect(env.fake.completed, hasLength(1));
        expect(find.text('Hộ đã có Premium'), findsWidgets);
        expect(find.text('Xong'), findsOneWidget);
      },
    );

    testWidgets('the store says purchased but capabilities do not: pending', (
      tester,
    ) async {
      final env = _Env();
      // The server says active, but getCapabilities still shows free.
      env.billing = FakeBilling();
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
      await _settle(tester);
      expect(find.text('Hộ đã có Premium'), findsNothing);
      expect(find.text('Đang chờ xác nhận thanh toán'), findsOneWidget);
      expect(find.text('Kiểm tra lại'), findsOneWidget);
    });

    testWidgets('store pending (Ask to Buy): no verify, nothing completed', (
      tester,
    ) async {
      final env = _Env();
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.pending));
      await _settle(tester);
      expect(find.text('Đang chờ xác nhận thanh toán'), findsOneWidget);
      expect(
        find.textContaining('Lựa chọn mẫu và ảnh của bạn vẫn được giữ'),
        findsNothing,
      );
      expect(env.billing.verifies, isEmpty);
      expect(env.fake.completed, isEmpty);
      // "Kiểm tra lại" reads capabilities again; still nothing granted.
      await tester.tap(find.text('Kiểm tra lại'));
      await _settle(tester);
      expect(find.text('Đang chờ xác nhận thanh toán'), findsOneWidget);
    });

    testWidgets('server pending: the transaction is kept unfinished', (
      tester,
    ) async {
      final env = _Env();
      env.billing.verifyAnswers = [
        PurchaseOutcome.pending,
        PurchaseOutcome.active,
      ];
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
      await _settle(tester);
      expect(find.text('Đang chờ xác nhận thanh toán'), findsOneWidget);
      expect(env.fake.completed, isEmpty);
      await tester.tap(find.text('Kiểm tra lại'));
      await _settle(tester);
      expect(env.billing.verifies, hasLength(2));
      expect(env.fake.completed, hasLength(1));
      expect(find.text('Hộ đã có Premium'), findsWidgets);
    });

    testWidgets('verify failure: error, retry sends the same transaction', (
      tester,
    ) async {
      final env = _Env();
      env.billing.verifyAnswers = [
        const PremiumException('internal'),
        PurchaseOutcome.active,
      ];
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
      await _settle(tester);
      expect(find.text('Chưa mua được'), findsOneWidget);
      expect(
        find.textContaining('chưa xác minh được giao dịch'),
        findsOneWidget,
      );
      // Opened without a template: "Đóng", not "Dùng mẫu cơ bản".
      expect(find.text('Đóng'), findsOneWidget);
      expect(env.fake.completed, isEmpty);
      await tester.tap(find.text('Thử lại'));
      await _settle(tester);
      expect(env.billing.verifies, hasLength(2));
      expect(env.billing.starts, hasLength(1));
      expect(find.text('Hộ đã có Premium'), findsWidgets);
    });

    testWidgets('store error: try again buys again', (tester) async {
      final env = _Env();
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.error));
      await _settle(tester);
      expect(find.text('Chưa mua được'), findsOneWidget);
      expect(
        find.textContaining('Bạn chưa bị trừ tiền nếu cửa hàng'),
        findsOneWidget,
      );
      await tester.tap(find.text('Thử lại'));
      await _settle(tester);
      expect(env.fake.bought, hasLength(2));
    });

    testWidgets('cancelled in the store sheet: back to PR01, no sheet', (
      tester,
    ) async {
      final env = _Env();
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.canceled));
      await _settle(tester);
      expect(find.text('Chưa mua được'), findsNothing);
      expect(find.text('Tiếp tục với Premium'), findsOneWidget);
    });

    testWidgets('the server refuses a non-owner (not_owner)', (tester) async {
      final env = _Env();
      env.billing.verifyAnswers = [PurchaseOutcome.notOwner];
      await _paywall(tester, env);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
      await _settle(tester);
      expect(find.text('Chỉ chủ hộ mua và khôi phục gói'), findsOneWidget);
      expect(env.fake.completed, isEmpty);
    });

    group('restore', () {
      Future<_Env> restore(
        WidgetTester tester,
        Object outcome, {
        bool owned = true,
      }) async {
        final env = _Env();
        env.billing.restoreAnswer = outcome;
        if (owned) {
          env.fake.owned = [env.fake.purchase(StorePurchaseStatus.restored)];
        }
        await _paywall(tester, env);
        await tester.tap(find.text('Khôi phục'));
        await _settle(tester);
        expect(find.text('Khôi phục giao dịch'), findsOneWidget);
        expect(
          find.textContaining('Không chuyển gói từ hộ khác'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(ClButton, 'Khôi phục'));
        await _settle(tester);
        return env;
      }

      testWidgets('restored: linked to this household again', (tester) async {
        final env = await restore(tester, PurchaseOutcome.active);
        expect(env.billing.restores.single.single.transactionId, '2000000999');
        expect(find.text('Đã khôi phục Premium'), findsOneWidget);
        expect(env.fake.completed, hasLength(1));
      });

      testWidgets('nothing to restore', (tester) async {
        final env = await restore(tester, PurchaseOutcome.active, owned: false);
        expect(env.billing.restores, isEmpty);
        expect(find.text('Không có giao dịch để khôi phục'), findsOneWidget);
      });

      testWidgets('already bound to another family: never moved', (
        tester,
      ) async {
        await restore(tester, PurchaseOutcome.alreadyBound);
        expect(find.text('Gói đang dùng cho hộ khác'), findsOneWidget);
        expect(find.text('Đã khôi phục Premium'), findsNothing);
      });

      testWidgets('not the owner', (tester) async {
        await restore(tester, PurchaseOutcome.notOwner);
        expect(find.text('Chỉ chủ hộ mua và khôi phục gói'), findsOneWidget);
      });
    });
  });

  group('MO03 · resume after purchase', () {
    test('card and video drafts survive a restart under their ref', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final card = _cardDraft();
      final video = _videoDraft();
      final drafts = ResumeDrafts(prefs);
      final cardRef = drafts.keep(card, cardDraftToJson(card));
      final videoRef = drafts.keep(video, videoDraftToJson(video));
      expect(identical(drafts.live(cardRef), card), isTrue);
      expect(cardRef.length, lessThanOrEqualTo(80));

      // A new run: only the saved copies are left.
      final again = ResumeDrafts(prefs);
      expect(again.live(cardRef), isNull);
      final c = cardDraftFromJson(again.saved(cardRef)!, seedCatalog())!;
      expect(c.template.id, 'card_blush');
      expect(c.occasion, Occasion.m1);
      expect(c.date, DateTime(2026, 10, 17));
      expect(c.quote, 'Một tháng yêu thương');
      expect(c.palette, card.palette);
      final photo = c.photos.single!;
      expect(
        (photo.image as StorageImage).path,
        'babies/b1/media/m1/original.jpg',
      );
      expect(photo.align, const Alignment(0.2, -0.4));
      expect(photo.zoom, 1.6);
      final v = videoDraftFromJson(again.saved(videoRef)!, seedCatalog())!;
      expect(v.template.id, video.template.id);
      expect(v.mediaIds, ['m1', 'm2', 'm3']);
      expect(v.title, 'Tháng đầu tiên');
      expect(v.audience, Audience.family);

      again.drop(cardRef);
      expect(again.saved(cardRef), isNull);
    });

    test('old drafts are pruned', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final drafts = ResumeDrafts(prefs);
      final old = drafts.keep(
        _videoDraft(),
        videoDraftToJson(_videoDraft()),
        now: DateTime(2026, 10, 1),
      );
      drafts.keep(
        _videoDraft(),
        videoDraftToJson(_videoDraft()),
        now: DateTime(2026, 10, 15),
      );
      expect(drafts.saved(old), isNull);
    });

    test('a withdrawn template is not rebuilt', () {
      final json = cardDraftToJson(_cardDraft())..['templateId'] = 'gone';
      expect(cardDraftFromJson(json, seedCatalog()), isNull);
    });

    testWidgets(
      'MO02 → PR01 → verified: back on the same card template, draft kept',
      (tester) async {
        final env = _Env();
        final draft = _cardDraft();
        bool? result;
        final (_, container) = await pumpRouted(
          tester,
          const SizedBox(),
          overrides: env.overrides,
          router: _router(
            Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () async => result = await ensureTemplateAllowed(
                    context,
                    ref,
                    template: draft.template,
                    catalog: const KeepsakeCatalog(
                      [],
                      premiumAccess: PremiumAccess.subscribers,
                    ),
                    babyId: teddyId,
                    keep: () => keepCardDraft(ref, draft),
                  ),
                  child: const Text('use'),
                ),
              ),
            ),
            env.seen,
          ),
        );
        await tester.tap(find.text('use'));
        await _settle(tester);
        expect(
          find.textContaining('Ảnh bạn đã chọn sẽ được giữ sau khi mua'),
          findsOneWidget,
        );
        await tester.tap(find.text('Mở với Premium'));
        await _settle(tester);
        // PR01 from the template: entry B.
        expect(find.text('Bạn đang xem'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục với Premium'));
        await _settle(tester);
        final start = env.billing.starts.single;
        expect(start['entryPoint'], 'templates');
        final resume = PurchaseResume.fromJson(start['resume'])!;
        expect(resume.kind, ResumeKind.card);
        expect(resume.templateId, 'card_blush');
        expect(
          identical(
            container.read(resumeDraftsProvider).live(resume.draftRef!),
            draft,
          ),
          isTrue,
        );
        env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
        await _settle(tester);
        expect(
          find.text('Tiếp tục đúng mẫu “Hồng phấn” với ảnh bạn đã chọn.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Tiếp tục tạo thẻ'));
        await _settle(tester);
        expect(result, isTrue);
        // The editor shows MO03's banner for this template.
        expect(container.read(justResumedProvider), 'card_blush');
      },
    );

    testWidgets('after a restart: the saved card draft opens in the editor', (
      tester,
    ) async {
      final env = _Env();
      final seen = env.seen;
      final router = _router(const SizedBox(), seen);
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        overrides: env.overrides,
        router: router,
      );
      final draft = _cardDraft();
      final key = container
          .read(resumeDraftsProvider)
          .keep(draft, cardDraftToJson(draft));
      // A new run: same phone storage, nothing in memory.
      final fresh = ProviderContainer(
        overrides: [
          ...env.overrides,
          resumeDraftsProvider.overrideWithValue(
            ResumeDrafts(container.read(sharedPreferencesProvider)),
          ),
        ],
      );
      addTearDown(fresh.dispose);
      final done = resumeAfterPurchase(
        router,
        fresh,
        PurchaseResume(
          kind: ResumeKind.card,
          templateId: draft.template.id,
          draftRef: key,
        ),
      );
      await _settle(tester);
      await done;
      expect(seen.visits.last, '/memories/card/edit');
      final rebuilt = seen.extras.last! as CardDraft;
      expect(rebuilt.template.id, 'card_blush');
      expect(
        (rebuilt.photos.single!.image as StorageImage).path,
        'babies/b1/media/m1/original.jpg',
      );
      expect(fresh.read(justResumedProvider), 'card_blush');
      // Used once.
      expect(fresh.read(resumeDraftsProvider).saved(key), isNull);
    });

    testWidgets('a video draft resumes on its photos step', (tester) async {
      final env = _Env();
      final router = _router(const SizedBox(), env.seen);
      final (_, container) = await pumpRouted(
        tester,
        const SizedBox(),
        overrides: env.overrides,
        router: router,
      );
      final draft = _videoDraft();
      final key = container
          .read(resumeDraftsProvider)
          .keep(draft, videoDraftToJson(draft));
      final done = resumeAfterPurchase(
        router,
        container,
        PurchaseResume(
          kind: ResumeKind.video,
          templateId: draft.template.id,
          draftRef: key,
        ),
      );
      await _settle(tester);
      await done;
      expect(env.seen.visits.last, '/memories/video/photos');
      expect(identical(env.seen.extras.last, draft), isTrue);
    });

    testWidgets('entry A: back to Nhịp lớn lên after the purchase', (
      tester,
    ) async {
      final env = _Env();
      bool? result;
      await pumpRouted(
        tester,
        const SizedBox(),
        overrides: env.overrides,
        router: _router(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await openPaywall(
                  context,
                  entry: PaywallEntry.rhythm,
                ),
                child: const Text('learn more'),
              ),
            ),
          ),
          env.seen,
        ),
      );
      await tester.tap(find.text('learn more'));
      await _settle(tester);
      await tester.tap(find.text('Tiếp tục với Premium'));
      await _settle(tester);
      env.fake.emit(env.fake.purchase(StorePurchaseStatus.purchased));
      await _settle(tester);
      expect(find.text('Về Nhịp lớn lên'), findsOneWidget);
      await tester.tap(find.text('Về Nhịp lớn lên'));
      await _settle(tester);
      expect(result, isTrue);
      expect(env.seen.visits.last, '/rhythm');
    });
  });

  group('PR03 · managing the plan', () {
    Future<void> plan(
      WidgetTester tester,
      Map<String, Object?> caps, {
      bool owner = true,
      StoreGateway store = const UnavailableStoreGateway(),
    }) async {
      final env = _Env(caps: caps, store: store, owner: owner);
      await pumpRouted(
        tester,
        const SizedBox(),
        overrides: env.overrides,
        router: _router(const HouseholdPlanScreen(), env.seen),
      );
    }

    Map<String, Object?> premium({
      bool owner = true,
      String? provider,
      String via = 'paid',
    }) => answer(
      plan: 'premium',
      templates: true,
      owner: owner,
      provider: provider,
      via: via,
      validUntil: '2026-11-14T00:00:00.000Z',
      autoRenew: true,
    );

    testWidgets('the owner manages in the store the plan came from', (
      tester,
    ) async {
      await plan(tester, premium(provider: 'google'));
      expect(find.text('Quản lý trong Google Play'), findsOneWidget);
      expect(find.text('Quản lý trong App Store'), findsNothing);
      expect(find.textContaining('sẽ có ở bản sau'), findsNothing);
    });

    testWidgets('unknown store: both links', (tester) async {
      await plan(tester, premium());
      expect(find.text('Quản lý trong App Store'), findsOneWidget);
      expect(find.text('Quản lý trong Google Play'), findsOneWidget);
      // No store in the app yet (D-074): restore hidden, not dead.
      expect(find.text('Khôi phục'), findsNothing);
    });

    testWidgets('restore appears once the store is open', (tester) async {
      await plan(tester, premium(), store: FakeStore());
      expect(find.text('Khôi phục'), findsOneWidget);
    });

    testWidgets('a staff promo has nothing to manage in a store', (
      tester,
    ) async {
      await plan(tester, premium(via: 'promo'));
      expect(find.text('Quản lý trong App Store'), findsNothing);
    });

    testWidgets('members who are not the owner: no actions', (tester) async {
      await plan(tester, premium(owner: false), owner: false);
      expect(find.text('Quản lý trong App Store'), findsNothing);
      expect(find.text('Xem Premium'), findsNothing);
      expect(
        find.textContaining('Chỉ chủ hộ mua và quản lý gói'),
        findsOneWidget,
      );
    });

    testWidgets('PR04: expired keeps history and offers renewal', (
      tester,
    ) async {
      await plan(
        tester,
        answer(plan: 'expired', validUntil: '2026-10-14T00:00:00.000Z'),
      );
      expect(find.text('Gia hạn Premium'), findsOneWidget);
      expect(
        find.textContaining('Mọi ghi nhận, phản hồi và bản tóm tắt đã lưu'),
        findsOneWidget,
      );
      await tester.tap(find.text('Gia hạn Premium'));
      await _settle(tester);
      expect(find.text('Child Life Premium'), findsWidgets);
    });

    testWidgets('free owner: "Xem Premium" opens PR01', (tester) async {
      await plan(tester, answer());
      await tester.tap(find.text('Xem Premium'));
      await _settle(tester);
      expect(find.text('Gói nào cũng có'), findsWidgets);
      expect(find.text('Mua trong app sắp có'), findsOneWidget);
    });
  });

  test('purchase answers and quota read the contracts', () {
    final a = PurchaseAnswer.fromJson({
      'outcome': 'already_bound',
      'validUntil': null,
      'resume': {'kind': 'video', 'templateId': 't', 'draftRef': 'd1'},
    })!;
    expect(a.outcome, PurchaseOutcome.alreadyBound);
    expect(
      a.resume,
      const PurchaseResume(
        kind: ResumeKind.video,
        templateId: 't',
        draftRef: 'd1',
      ),
    );
    expect(PurchaseAnswer.fromJson({'outcome': 'gold'}), isNull);
    final q = VideoQuota.fromJson({
      'quota': {
        'limit': 5,
        'used': 2,
        'reserved': 1,
        'resetsAt': '2026-10-31T17:00:00.000Z',
      },
    })!;
    expect(q.taken, 3);
    expect(q.left, 2);
    expect(q.exhausted, isFalse);
    expect(VideoQuota.fromJson({'limit': 'x'}), isNull);
    expect(
      PurchaseResume.fromQuery(
        const PurchaseResume(
          kind: ResumeKind.card,
          templateId: 'card_blush',
          draftRef: 'dabc',
        ).toQuery(),
      ),
      const PurchaseResume(
        kind: ResumeKind.card,
        templateId: 'card_blush',
        draftRef: 'dabc',
      ),
    );
    expect(paywallLocation(PaywallEntry.rhythm), '/premium?entry=rhythm');
  });

  test('controller starts idle and never grants without the server', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...premiumOverrides(household: FakeHousehold(answer())),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(purchaseControllerProvider).phase,
      PurchasePhase.idle,
    );
  });
}

const answerGroupA = 'A · Cá nhân hoá & Nhịp lớn lên nâng cao';
const answerGroupB = 'B · Mẫu thẻ & video Premium';
