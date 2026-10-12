import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/features/spending/spending_calc.dart';
import 'package:child_life/features/spending/spending_format.dart';
import 'package:child_life/features/spending/spending_models.dart';
import 'package:child_life/l10n/app_localizations_en.dart';
import 'package:child_life/l10n/app_localizations_vi.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/spending_fixtures.dart';

/// Chi tiêu figures (P-140) on the mock of 8b / 8f: Monday 12/10/2026.
void main() {
  final today = DateTime(2026, 10, 12);
  final vi = AppLocalizationsVi();
  final en = AppLocalizationsEn();

  group('money (P-140)', () {
    test('full form per locale', () {
      expect(money('vi', 1020000), '1.020.000 ₫');
      expect(money('en', 1020000), '1,020,000 ₫');
      expect(moneyPlain('vi', 5000), '5.000');
    });

    test('short form from a million, one decimal', () {
      expect(moneyShort(vi, 'vi', 4215000), '4,2 tr');
      expect(moneyShort(en, 'en', 4215000), '4.2M');
      expect(moneyShort(vi, 'vi', 41815000), '41,8 tr');
      expect(moneyShort(vi, 'vi', 8000000), '8 tr');
      expect(moneyShort(vi, 'vi', 950000), '950.000 ₫');
    });

    test('typed amounts ignore separators and stay within the limit', () {
      expect(parseMoney('1.020.000'), 1020000);
      expect(parseMoney('1,020,000 ₫'), 1020000);
      expect(parseMoney(''), isNull);
      expect(parseMoney('99999999999999'), 9999999999);
    });
  });

  group('8b month', () {
    final s = MonthSummary.of(mockSpending(), monthOf(today), today);

    test('total, by category, average per day', () {
      expect(s.total, 4215000);
      expect(s.byCategory['c_childcare'], 2000000);
      expect(s.byCategory['c_milk'], 1120000);
      expect(s.byCategory['c_diaper'], 540000);
      // 4.215.000 / 12 days = 351.250 → nearest thousand.
      expect(s.averagePerDay, 351000);
      expect(s.ranked.first.key, 'c_childcare');
      expect(s.vaccinesIn('c_health'), 1);
    });

    test('compared with the same days of the previous month', () {
      // 1–12/9: 3.500.000 + 1.100.000.
      expect(s.previousSamePeriod, 4600000);
      expect(s.change, closeTo(-0.0837, 0.001));
    });

    test('a past month counts all its days; a future one none', () {
      final sep = MonthSummary.of(mockSpending(), (
        year: 2026,
        month: 9,
      ), today);
      expect(sep.daysCounted, 30);
      final nov = MonthSummary.of(mockSpending(), (
        year: 2026,
        month: 11,
      ), today);
      expect(nov.daysCounted, 0);
      expect(nov.averagePerDay, 0);
    });
  });

  test('8h near the cap from 90 %, over past it', () {
    expect(capState(395000, 400000), CapState.near);
    expect(capState(200000, 400000), CapState.fine);
    expect(capState(450000, 400000), CapState.over);
  });

  group('8d six months', () {
    final six = SixMonths.of(mockSpending(), today);

    test('months, total, average over complete months, highest', () {
      expect(six.months.first, (year: 2026, month: 5));
      expect(six.months.last, (year: 2026, month: 10));
      expect(six.total, 4215000 + 4600000);
      // Only September is complete with spending.
      expect(six.averagePerMonth, 4600000);
      expect(six.months[six.highestIndex].month, 9);
    });

    test('four categories keep a colour; the rest fold into Khác', () {
      expect(six.legend.length, 5);
      expect(six.legend.last, otherCategoryId);
      final oct = six.bars.last;
      expect(oct.total, 4215000);
    });

    test('payers, largest first', () {
      expect(six.byPayer.first.payer?.uid, 'u_mai');
      expect(six.byPayer.any((p) => p.payer == null), isTrue);
    });
  });

  group('8e since birth', () {
    test('by month of age from the date of birth', () {
      final b = SinceBirth.of(mockSpending(), today, DateTime(2026, 3, 22));
      expect(b.months, 6);
      expect(b.bars.length, 7);
      // The stroller bought two days before the birth counts in the first month.
      expect(b.bars.first.total, 6200000);
      expect(b.total, 6200000 + 4600000 + 4215000);
      expect(b.largest.first.amount, 6200000);
      expect(b.largest[1].amount, 3500000);
    });

    test('without a date of birth, from the first expense', () {
      final b = SinceBirth.of(mockSpending(), today, null);
      expect(b.months, 6);
      expect(b.total, 15015000);
    });

    test('a month passes on the same day number', () {
      expect(monthsBetween(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 1);
      expect(monthsBetween(DateTime(2026, 3, 12), DateTime(2026, 4, 11)), 0);
      expect(monthsBetween(DateTime(2026, 3, 12), DateTime(2026, 4, 12)), 1);
    });
  });

  group('8i schedules (D-057)', () {
    test('monthly on two days; 31 falls on a short month\'s last day', () {
      const s = Monthly([1, 16]);
      expect(s.isDue(DateTime(2026, 10, 16)), isTrue);
      expect(s.isDue(DateTime(2026, 10, 15)), isFalse);
      expect(s.nextAfter(today), DateTime(2026, 10, 16));
      expect(const Monthly([31]).isDue(DateTime(2026, 2, 28)), isTrue);
    });

    test('every N weeks from a start, and yearly', () {
      final w = EveryWeeks(every: 2, startOn: DateTime(2026, 10, 1));
      expect(w.isDue(DateTime(2026, 10, 15)), isTrue);
      expect(w.isDue(DateTime(2026, 10, 8)), isFalse);
      expect(w.isDue(DateTime(2026, 9, 17)), isFalse);
      expect(
        const Yearly(month: 3, day: 5).nextAfter(today),
        DateTime(2027, 3, 5),
      );
    });

    test('labels', () {
      expect(
        scheduleLabel(vi, const Monthly([1, 16])),
        'Ngày 1 và 16 hằng tháng',
      );
      expect(
        scheduleLabel(vi, EveryWeeks(every: 2, startOn: today)),
        'Mỗi 2 tuần',
      );
      expect(
        scheduleLabel(vi, const Yearly(month: 3, day: 5)),
        'Ngày 5/3 hằng năm',
      );
      expect(scheduleLabel(en, const Monthly([5])), 'Day 5 of every month');
    });

    test('round trip through Firestore maps', () {
      for (final s in [
        const Monthly([1, 16]),
        EveryWeeks(every: 3, startOn: DateTime(2026, 10, 1)),
        const Yearly(month: 3, day: 5),
      ]) {
        expect(RecurringSchedule.fromJson(s.toJson()).toJson(), s.toJson());
      }
    });
  });

  group('8f search and filters', () {
    String name(String id) => categoryName(
      vi,
      mergeCategories(
        const [],
      ).firstWhere((c) => c.id == id, orElse: () => builtInCategories.last),
    );

    test('search without Vietnamese marks', () {
      final f = const ExpenseFilter(query: 'sua cong');
      expect(
        mockSpending().where((e) => f.matches(e, name)).map((e) => e.note),
        ['Sữa công thức ×2', 'Sữa công thức'],
      );
      expect(foldVietnamese('Tã dán ĐẸP'), 'ta dan dep');
    });

    test('month, payer ("Khác" = no member) and receipt', () {
      final f = ExpenseFilter(month: monthOf(today), payerUid: '');
      expect(mockSpending().where((e) => f.matches(e, name)).length, 1);
      const r = ExpenseFilter(receiptOnly: true);
      expect(mockSpending().where((e) => r.matches(e, name)).length, 2);
    });
  });

  test('8c "Lần trước" and 8k the last cost of the same vaccine', () {
    final all = mockSpending();
    expect(lastAmount(all, 'c_milk'), 1020000);
    expect(lastAmount(all, null), 1020000);
    expect(lastVaccineCost(all, 'dtp_3'), 395000);
    expect(lastVaccineCost(all, 'pcv_1'), isNull);
  });

  test('CSV: header, oldest first, quoted, formulas neutralised', () {
    final csv = expensesCsv(
      [
        ...mockSpending().take(2),
        spend('99', 1000, 'c_other', DateTime(2026, 1, 1), note: '=SUM(A1)'),
      ],
      header: ['Ngày', 'Danh mục', 'Nội dung', 'Số tiền', 'Ai trả', 'Ghi bởi'],
      category: (e) => e.categoryId,
      payer: (e) => e.payer?.author.name ?? 'Khác',
      recordedBy: (e) => e.author.name,
    );
    expect(csv, startsWith('\uFEFF"Ngày","Danh mục"'));
    final lines = csv.trim().split('\r\n');
    expect(lines[1], contains('"\'=SUM(A1)"'));
    expect(
      lines.last,
      '"2026-10-12","c_milk","Sữa công thức ×2",1020000,"Mai","Mai"',
    );
  });

  test('categories: built-ins until written, Khác always last', () {
    final merged = mergeCategories([
      swimCategory,
      const SpendingCategory(
        id: 'c_milk',
        icon: ClIcons.feed,
        tint: CategoryTint.bottle,
        order: 9,
        builtIn: true,
        hidden: true,
      ),
    ]);
    expect(merged.last.id, otherCategoryId);
    expect(merged.where((c) => c.id == 'c_milk').single.hidden, isTrue);
    expect(merged.length, 7);
    expect(categoryName(vi, merged.first), 'Giữ trẻ & học');
    expect(categoryName(en, merged.first), 'Childcare & learning');
  });
}
