import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_format.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/care/care_repository.dart';
import 'package:child_life/features/care/care_screens.dart';
import 'package:child_life/features/care/care_sheets.dart';
import 'package:child_life/features/onboarding/setup_screens.dart'
    show relationLabel;
import 'package:child_life/features/today/today_screen.dart';
import 'package:child_life/l10n/app_localizations_en.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/care_fixtures.dart';
import '../helpers/family_fixtures.dart';
import '../helpers/router_pump.dart';

/// A page with one button that opens [open] — sheets need a navigator underneath.
class _Host extends StatelessWidget {
  const _Host(this.open);
  final void Function(BuildContext) open;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  final vi = AppLocalizationsVi();
  final en = AppLocalizationsEn();

  group('copy rules (D-023, D-024)', () {
    test('relative time uses the full form', () {
      final now = DateTime(2026, 10, 8, 15, 5);
      DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
      expect(relativeAgo(vi, ago(0), now), 'Vừa xong');
      expect(relativeAgo(vi, ago(45), now), '45 phút trước');
      expect(relativeAgo(vi, ago(85), now), '1 giờ 25 phút trước');
      expect(relativeAgo(vi, ago(120), now), '2 giờ trước');
      expect(relativeAgo(vi, ago(60 * 50), now), '2 ngày trước');
      expect(relativeAgo(en, ago(85), now), '1 h 25 min ago');
    });

    test('family relations read as labels, others as names, you as "Bạn"', () {
      String who(Membership m, {bool me = false}) => authorLabel(
        vi,
        CareAuthor.of(m),
        isMe: me,
        relationLabel: (r, c) => relationLabel(vi, r, c),
      );
      expect(who(mai), 'Mẹ');
      expect(who(minh), 'Ba');
      expect(who(lan), 'Cô Lan');
      expect(who(hoa), 'Bà');
      expect(who(mai, me: true), 'Bạn');
      expect(
        authorFull(
          vi,
          CareAuthor.of(mai),
          isMe: true,
          relationLabel: (r, c) => relationLabel(vi, r, c),
        ),
        'Mẹ Mai (bạn)',
      );
    });

    test('decimal comma in Vietnamese (28: "4,3 kg")', () {
      expect(decimal('vi', 4.3), '4,3');
      expect(decimal('vi', 53), '53');
      expect(decimal('en', 54.5), '54.5');
      expect(parseDecimal('4,3'), 4.3);
      expect(parseDecimal('54.5'), 54.5);
    });
  });

  group('records', () {
    test('the document matches the Rules shape', () {
      final record = CareRecord.create(
        id: newRecordId(),
        babyId: teddyId,
        type: CareType.breast,
        occurredAt: DateTime(2026, 10, 8, 11, 30),
        me: mai,
        side: Side.left,
        durationMin: 15,
      );
      expect(record.toCreateJson().keys.toSet(), {
        'id',
        'babyId',
        'type',
        'occurredAt',
        'endedAt',
        'data',
        'createdBy',
        'author',
        'createdAt',
        'clientCreatedAt',
        'updatedAt',
        'updatedBy',
        'deleted',
        'deletedAt',
        'deletedBy',
        'source',
      });
      expect(record.id, matches(RegExp(r'^r_[a-f0-9]{32}$')));
      expect(record.dataJson(), {'side': 'left', 'durationMin': 15});
      expect(record.endedAt, DateTime(2026, 10, 8, 11, 45));
      expect(record.author.relation, Relation.mother);
      final longer = record.copyWith(durationMin: 20);
      expect(longer.endedAt, DateTime(2026, 10, 8, 11, 50));
      expect(record.toEditJson('u_mai').keys.toSet(), {
        'occurredAt',
        'endedAt',
        'data',
        'updatedAt',
        'updatedBy',
      });
    });

    test('"Đã ghi hôm nay": pending included, pumping left out (R-054)', () {
      final day = babyDayBounds('Asia/Ho_Chi_Minh', careNow);
      final totals = DayTotals.of(mockDay(offline: true), day.start, day.end);
      expect(totals.bottleCount, 2);
      expect(totals.bottleMl, 240);
      expect(totals.breastCount, 1);
      expect(totals.breastMinutes, 15);
      expect(totals.diaperCount, 2);
    });

    test('edit rights (D-022)', () {
      final momsBottle = mockDay().first;
      final lansDiaper = mockDay()[1];
      expect(canEditRecord(minh, momsBottle), isTrue);
      expect(canEditRecord(lan, momsBottle), isFalse);
      expect(canEditRecord(lan, lansDiaper), isTrue);
      expect(canEditRecord(hoa, lansDiaper), isFalse);
    });
  });

  group('screens', () {
    testWidgets('19: tiles show the last entry and totals, not who logged it', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(),
      );
      // The last bottle also says when by the clock; who logged it is not on the tile
      // (owner, 2026-10-30).
      expect(find.text('45 phút trước'), findsOneWidget);
      expect(find.textContaining('Lúc '), findsWidgets);
      expect(find.text('Tã ướt'), findsOneWidget);
      expect(find.text('Kết thúc 3 giờ 20 phút trước'), findsOneWidget);
      // The day's totals sit under the reminders card, which lists up to 3 now.
      await tester.scrollUntilVisible(
        find.text('2\u00a0cữ · 240\u00a0ml'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2\u00a0cữ · 240\u00a0ml'), findsOneWidget);
      expect(find.text('1\u00a0cữ · 15\u00a0phút'), findsOneWidget);
      expect(find.text('2 lần'), findsOneWidget);
      expect(find.textContaining('chờ đồng bộ'), findsNothing);
    });

    testWidgets('9a: offline entries show "Chờ đồng bộ" and the banner → 9b', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const Scaffold(body: TodayScreen()),
        overrides: careOverrides(
          records: mockDay(offline: true),
          online: false,
        ),
      );
      expect(find.text('Đang offline · 2 bản ghi chờ đồng bộ'), findsOneWidget);
      expect(find.text('Chờ đồng bộ'), findsNWidgets(2));
      await tester.tap(find.text('Đang offline · 2 bản ghi chờ đồng bộ'));
      await tester.pumpAndSettle();
      expect(find.text('Chỉ lưu trên máy này'), findsNWidgets(2));
      expect(find.text('Thử lại ngay'), findsOneWidget);
    });

    testWidgets('22: a bottle saves in two taps; ml is optional but bounded', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      await pumpRouted(
        tester,
        _Host((c) => openCareLog(c, CareType.bottle)),
        overrides: careOverrides(repo: repo),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Ghi cữ bú'), findsOneWidget);
      expect(find.text('Bây giờ · 15:05'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '900');
      await tester.tap(find.text('Lưu cữ bú'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập từ 1 đến 500 ml.'), findsOneWidget);
      expect(repo.created, isEmpty);

      await tester.enterText(find.byType(EditableText), '120');
      await tester.tap(find.text('Sữa công thức'));
      await tester.tap(find.text('Lưu cữ bú'));
      await tester.pumpAndSettle();
      final saved = repo.created.single;
      expect(saved.type, CareType.bottle);
      expect(saved.amountMl, 120);
      expect(saved.milk, MilkType.formula);
      expect(saved.createdBy, 'u_mai');
      expect(find.text('Đã ghi · Bú bình · 120 ml'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      expect(repo.deleted.single.id, saved.id);
    });

    testWidgets(
      '22 (v1.0): last amount prefilled, quick picks for the baby\'s age',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          _Host((c) => openCareLog(c, CareType.bottle)),
          overrides: careOverrides(repo: repo),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        // The last bottle today was 120 ml at 14:20; Teddy is three weeks old.
        expect(find.text('Lượng sữa · đã điền theo lần trước'), findsOneWidget);
        expect(find.text('Lần trước 120 ml · 14:20'), findsOneWidget);
        expect(find.text('Gợi ý cho bé 3 tuần'), findsOneWidget);
        for (final ml in const ['60', '90', '120', '150']) {
          expect(find.text('$ml ml', findRichText: true), findsOneWidget);
        }
        await tester.tap(find.text('90 ml', findRichText: true));
        await tester.pump();
        expect(find.text('Lượng sữa · tùy chọn'), findsOneWidget);
        await tester.tap(find.text('Lưu cữ bú'));
        await tester.pumpAndSettle();
        expect(repo.created.single.amountMl, 90);
      },
    );

    testWidgets('23: suggests the other side; 24 remembers the last kind', (
      tester,
    ) async {
      final repo = FakeCareRepository();
      final day = mockDay();
      final lastLeft = [
        rec(
          CareType.breast,
          vn(8, 14, 0),
          mai,
          side: Side.left,
          durationMin: 10,
        ),
        ...day,
      ];
      final (_, container) = await pumpRouted(
        tester,
        _Host((c) => openCareLog(c, CareType.breast)),
        overrides: careOverrides(repo: repo, records: lastLeft),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu cữ bú'));
      await tester.pumpAndSettle();
      expect(repo.created.single.side, Side.right);

      container
          .read(careMemoryProvider)
          .set(teddyId, 'diaper', DiaperKind.dirty);
      await tester.pumpWidget(const SizedBox());
      await pumpRouted(
        tester,
        _Host((c) => openCareLog(c, CareType.diaper)),
        overrides: careOverrides(repo: repo),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu lần thay tã'));
      await tester.pumpAndSettle();
      expect(repo.created.last.type, CareType.diaper);
    });

    testWidgets('21: Cùng nuôi can edit and delete, then undo', (tester) async {
      final repo = FakeCareRepository();
      final record = mockDay()[1]; // Cô Lan's diaper
      await pumpRouted(
        tester,
        RecordDetailScreen(recordId: record.id),
        overrides: careOverrides(repo: repo, byId: {record.id: record}),
      );
      expect(find.text('Cô Lan'), findsOneWidget);
      expect(find.text('Đã đồng bộ'), findsOneWidget);
      expect(find.text('Sửa'), findsOneWidget);
      await tester.tap(find.text('Xóa bản ghi'));
      await tester.pumpAndSettle();
      expect(find.text('Xóa bản ghi này?'), findsOneWidget);
      await tester.tap(find.text('Xóa bản ghi').last);
      await tester.pumpAndSettle();
      expect(repo.deleted.single.id, record.id);
    });

    testWidgets('12e: a caregiver sees a parent\'s record read-only', (
      tester,
    ) async {
      final record = mockDay().first; // Mẹ's bottle
      await pumpRouted(
        tester,
        RecordDetailScreen(recordId: record.id),
        overrides: careOverrides(me: lan, byId: {record.id: record}),
      );
      expect(find.text('Sửa'), findsNothing);
      expect(find.text('Xóa bản ghi'), findsNothing);
      expect(
        find.text('Bản ghi của Mẹ · chỉ xem. Nếu sai, nhắn Mẹ để sửa.'),
        findsOneWidget,
      );
      expect(find.text('Nhắn Mẹ'), findsOneWidget);
    });

    testWidgets(
      '28: weight is required; the change since the last measurement shows',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          const GrowthScreen(),
          overrides: careOverrides(repo: repo, growth: mockGrowth()),
        );
        expect(find.text('3,9 kg · 53 cm'), findsOneWidget);
        await tester.tap(find.text('Lưu số đo'));
        await tester.pumpAndSettle();
        expect(find.text('Nhập cân nặng từ 0,3 đến 40 kg.'), findsOneWidget);
        await tester.enterText(find.byType(EditableText).at(0), '4,3');
        await tester.enterText(find.byType(EditableText).at(1), '54,5');
        await tester.pump();
        expect(
          find.text('+0,4 kg · +1,5 cm so với lần đo 1 thg 10'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '28: head circumference is optional, 20…60 cm, saved with the measurement (owner 2026-10-16)',
      (tester) async {
        final repo = FakeCareRepository();
        await pumpRouted(
          tester,
          const GrowthScreen(),
          overrides: careOverrides(repo: repo, growth: mockGrowth()),
        );
        expect(find.text('Vòng đầu · tùy chọn'), findsOneWidget);
        final head = find.descendant(
          of: find.byKey(const ValueKey('growth.head')),
          matching: find.byType(EditableText),
        );
        await tester.enterText(find.byType(EditableText).at(0), '4,3');
        await tester.enterText(head, '75');
        await tester.tap(find.text('Lưu số đo'));
        await tester.pumpAndSettle();
        expect(find.text('Vòng đầu từ 20 đến 60 cm.'), findsOneWidget);
        expect(repo.created, isEmpty);
        await tester.enterText(head, '38,54');
        await tester.tap(find.text('Lưu số đo'));
        await tester.pumpAndSettle();
        final saved = repo.created.single;
        expect(saved.headCm, 38.5);
        expect(saved.dataJson()['headCm'], 38.5);
        // Without a value the key is left out (older Rules and readers keep working).
        expect(
          saved.copyWith(clearHead: true).dataJson().containsKey('headCm'),
          isFalse,
        );
      },
    );
  });
}
