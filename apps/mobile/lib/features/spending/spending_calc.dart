import 'dart:math' as math;

import 'spending_currency.dart';
import 'spending_models.dart';

/// Figures for 8b / 8d / 8e / 8h (P-140). Pure functions over the expenses the caller may read;
/// [today] is the baby's calendar date. D-075 #4: a figure counts ONE currency (`currency:`);
/// the other currencies are only ever summed apart ([otherTotals]), never added in.

typedef YearMonth = ({int year, int month});

YearMonth monthOf(DateTime d) => (year: d.year, month: d.month);

YearMonth addMonths(YearMonth m, int n) {
  final d = DateTime(m.year, m.month + n);
  return (year: d.year, month: d.month);
}

int daysIn(YearMonth m) => DateTime(m.year, m.month + 1, 0).day;

bool inMonth(Expense e, YearMonth m) =>
    e.spentOn.year == m.year && e.spentOn.month == m.month;

int sumOf(Iterable<Expense> items) => items.fold(0, (s, e) => s + e.amount);

/// [all] in [currency] only; everything when it is null.
List<Expense> inCurrency(List<Expense> all, String? currency) =>
    currency == null
    ? all
    : [
        for (final e in all)
          if (e.currency == currency) e,
      ];

/// Totals of [items] per currency other than [main], by code (D-075 #4: shown apart).
Map<String, int> otherTotals(Iterable<Expense> items, String main) =>
    sumByCurrency([
      for (final e in items)
        if (e.currency != main) (currency: e.currency, amount: e.amount),
    ]);

/// Totals of [items] per currency, [first] first ("1.020.000 ₫ · 12,50 $" day headers).
Map<String, int> totalsByCurrency(Iterable<Expense> items, {String? first}) =>
    sumByCurrency([
      for (final e in items) (currency: e.currency, amount: e.amount),
    ], first: first);

/// Nearest thousand ("351.250" → "351.000", 8b).
int roundThousand(double v) => (v / 1000).round() * 1000;

/// 8b: one calendar month.
class MonthSummary {
  MonthSummary._({
    required this.month,
    required this.items,
    required this.total,
    required this.byCategory,
    required this.daysCounted,
    required this.previousSamePeriod,
    required this.allItems,
    required this.others,
    this.currency,
  });

  /// [currency]: the one the figures count (D-075 #4); null counts every item (single-currency
  /// callers and tests).
  factory MonthSummary.of(
    List<Expense> every,
    YearMonth month,
    DateTime today, {
    String? currency,
  }) {
    final all = inCurrency(every, currency);
    final allItems = [
      for (final e in every)
        if (inMonth(e, month)) e,
    ];
    final items = [
      for (final e in all)
        if (inMonth(e, month)) e,
    ];
    final current = monthOf(today);
    final isCurrent = month == current;
    final future =
        month.year > current.year ||
        (month.year == current.year && month.month > current.month);
    // Days elapsed this month; a past month counts whole.
    final days = future ? 0 : (isCurrent ? today.day : daysIn(month));
    final prev = addMonths(month, -1);
    final prevDays = math.min(days, daysIn(prev));
    final previous = sumOf(
      all.where((e) => inMonth(e, prev) && e.spentOn.day <= prevDays),
    );
    final byCategory = <String, int>{};
    for (final e in items) {
      byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
    }
    return MonthSummary._(
      month: month,
      items: items,
      total: sumOf(items),
      byCategory: byCategory,
      daysCounted: days,
      previousSamePeriod: previous,
      allItems: allItems,
      others: currency == null ? const {} : otherTotals(allItems, currency),
      currency: currency,
    );
  }

  final YearMonth month;

  /// The month's items in the counted currency.
  final List<Expense> items;

  /// The month's items in every currency (the recent list).
  final List<Expense> allItems;

  /// The month's totals in the other currencies, never added to [total].
  final Map<String, int> others;
  final int total;
  final Map<String, int> byCategory;
  final int daysCounted;

  /// The previous month over the same number of days (P-140 "So với tháng trước").
  final int previousSamePeriod;

  /// The counted currency (null: every item, VND callers).
  final String? currency;

  /// VND to the nearest thousand (8b "351.000"); another currency to its minor unit.
  int get averagePerDay => daysCounted == 0
      ? 0
      : currency == null || currency == legacyCurrency
      ? roundThousand(total / daysCounted)
      : (total / daysCounted).round();

  /// −0.06 = "Thấp hơn 6%"; null when there is nothing to compare with.
  double? get change => previousSamePeriod == 0 || daysCounted == 0
      ? null
      : (total - previousSamePeriod) / previousSamePeriod;

  /// Categories by amount, largest first.
  List<MapEntry<String, int>> get ranked =>
      byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  int countIn(String categoryId) =>
      items.where((e) => e.categoryId == categoryId).length;

  int vaccinesIn(String categoryId) => items
      .where(
        (e) => e.categoryId == categoryId && e.source == ExpenseSource.vaccine,
      )
      .length;
}

enum CapState { fine, near, over }

/// 8h: how a category stands against its cap.
CapState capState(int spent, int cap) {
  if (cap <= 0) return CapState.fine;
  if (spent > cap) return CapState.over;
  if (spent >= cap * SpendingLimits.nearCapShare) return CapState.near;
  return CapState.fine;
}

/// One bar of 8d (a calendar month) or 8e (a month of age).
class BarStack {
  BarStack({required this.label, required this.segments});
  final String label;

  /// Amounts per legend entry, bottom to top.
  final List<int> segments;
  int get total => segments.fold(0, (s, v) => s + v);
}

/// 8d: the last six calendar months, the top [keep] categories each with a colour and the rest
/// folded into "Khác".
class SixMonths {
  SixMonths._({
    required this.months,
    required this.legend,
    required this.bars,
    required this.byCategory,
    required this.byPayer,
    required this.total,
  });

  factory SixMonths.of(
    List<Expense> every,
    DateTime today, {
    int keep = 4,
    String? currency,
  }) {
    final all = inCurrency(every, currency);
    final current = monthOf(today);
    final months = [for (var i = 5; i >= 0; i--) addMonths(current, -i)];
    final items = [
      for (final e in all)
        if (months.any((m) => inMonth(e, m))) e,
    ];
    final byCategory = <String, int>{};
    final byPayer = <String, ({Payer? payer, int amount})>{};
    for (final e in items) {
      byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
      final key = e.payer?.uid ?? '';
      final had = byPayer[key];
      byPayer[key] = (payer: e.payer, amount: (had?.amount ?? 0) + e.amount);
    }
    final ranked = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final legend = [
      for (final e in ranked)
        if (e.key != otherCategoryId) e.key,
    ].take(keep).toList();
    final folds = ranked.length > legend.length;
    final columns = [...legend, if (folds) otherCategoryId];
    final bars = [
      for (final m in months)
        BarStack(
          label: '${m.month}',
          segments: [
            for (final c in columns)
              sumOf(
                items.where(
                  (e) =>
                      inMonth(e, m) &&
                      (c == otherCategoryId
                          ? !legend.contains(e.categoryId)
                          : e.categoryId == c),
                ),
              ),
          ],
        ),
    ];
    final payers = byPayer.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return SixMonths._(
      months: months,
      legend: columns,
      bars: bars,
      byCategory: ranked,
      byPayer: payers,
      total: sumOf(items),
    );
  }

  final List<YearMonth> months;

  /// Category ids with their own colour, "Khác" last when others are folded in.
  final List<String> legend;
  final List<BarStack> bars;
  final List<MapEntry<String, int>> byCategory;
  final List<({Payer? payer, int amount})> byPayer;
  final int total;

  /// "TB mỗi tháng": over the five complete months (the current one is partial).
  int get averagePerMonth {
    final complete = bars.take(bars.length - 1).map((b) => b.total).toList();
    final counted = complete.where((t) => t > 0).length;
    return counted == 0
        ? 0
        : (complete.fold(0, (s, t) => s + t) / counted).round();
  }

  int get highestIndex {
    var best = 0;
    for (var i = 1; i < bars.length; i++) {
      if (bars[i].total > bars[best].total) best = i;
    }
    return best;
  }
}

/// 8e: everything since birth, by month of age (birth day + N months).
class SinceBirth {
  SinceBirth._({
    required this.total,
    required this.count,
    required this.months,
    required this.bars,
    required this.largest,
  });

  /// Without a date of birth (no right to read it), months count from the first expense.
  factory SinceBirth.of(
    List<Expense> every,
    DateTime today,
    DateTime? dob, {
    String? currency,
  }) {
    final all = inCurrency(every, currency);
    final start =
        dob ??
        (all.isEmpty
            ? today
            : all
                  .map((e) => e.spentOn)
                  .reduce((a, b) => a.isBefore(b) ? a : b));
    final age = math.max(0, monthsBetween(start, today));
    final buckets = List<int>.filled(age + 1, 0);
    var total = 0;
    for (final e in all) {
      // Gear bought before the birth counts in the first month ("Tháng đầu gồm đồ dùng sơ
      // sinh", 8e).
      final m = math.max(0, monthsBetween(start, e.spentOn));
      if (m > age) continue;
      buckets[m] += e.amount;
      total += e.amount;
    }
    final largest = [...all]..sort((a, b) => b.amount.compareTo(a.amount));
    return SinceBirth._(
      total: total,
      count: all.length,
      months: age,
      bars: [
        for (var i = 0; i < buckets.length; i++)
          BarStack(label: '$i', segments: [buckets[i]]),
      ],
      largest: largest.take(4).toList(),
    );
  }

  final int total;
  final int count;

  /// Whole months of age today.
  final int months;
  final List<BarStack> bars;
  final List<Expense> largest;

  /// "Trung bình 6,9 tr mỗi tháng tuổi" (at least one month).
  int get averagePerMonth => (total / math.max(1, months)).round();
}

/// Whole months from [from] to [to] (a month passes on the same day number, clamped).
int monthsBetween(DateTime from, DateTime to) {
  var m = (to.year - from.year) * 12 + to.month - from.month;
  final lastDay = DateTime(to.year, to.month + 1, 0).day;
  if (to.day < math.min(from.day, lastDay)) m -= 1;
  return m;
}

/// "Lần trước": the latest amount in [categoryId] (8c suggestion), else the latest overall;
/// only in [currency] when given (an amount in another currency would read wrong).
int? lastAmount(List<Expense> all, String? categoryId, {String? currency}) {
  for (final e in all) {
    if (currency != null && e.currency != currency) continue;
    if (categoryId == null || e.categoryId == categoryId) return e.amount;
  }
  return null;
}

/// 8k: the last cost paid for the same vaccine ("hexa6_2" → "hexa6"), with its currency.
({int amount, String currency})? lastVaccineCost(
  List<Expense> all,
  String doseKey,
) {
  final vaccine = doseKey.split('_').first;
  for (final e in all) {
    if (e.source == ExpenseSource.vaccine &&
        (e.sourceRef ?? '').split('_').first == vaccine) {
      return (amount: e.amount, currency: e.currency);
    }
  }
  return null;
}

/// 8f search and filters.
class ExpenseFilter {
  const ExpenseFilter({
    this.month,
    this.categoryId,
    this.payerUid,
    this.receiptOnly = false,
    this.query = '',
  });

  /// Null: every month.
  final YearMonth? month;
  final String? categoryId;

  /// '' = "Khác" (no member); null = anyone.
  final String? payerUid;
  final bool receiptOnly;
  final String query;

  bool matches(Expense e, String Function(String categoryId) nameOf) {
    if (month != null && !inMonth(e, month!)) return false;
    if (categoryId != null && e.categoryId != categoryId) return false;
    if (payerUid != null && (e.payer?.uid ?? '') != payerUid) return false;
    if (receiptOnly && !e.hasReceipt) return false;
    final q = foldVietnamese(query.trim());
    if (q.isEmpty) return true;
    return foldVietnamese(e.note).contains(q) ||
        foldVietnamese(nameOf(e.categoryId)).contains(q);
  }

  ExpenseFilter copyWith({
    YearMonth? Function()? month,
    String? Function()? categoryId,
    String? Function()? payerUid,
    bool? receiptOnly,
    String? query,
  }) => ExpenseFilter(
    month: month == null ? this.month : month(),
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    payerUid: payerUid == null ? this.payerUid : payerUid(),
    receiptOnly: receiptOnly ?? this.receiptOnly,
    query: query ?? this.query,
  );
}

const _from =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _to =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Lower case without Vietnamese marks, so "sua" finds "Sữa".
String foldVietnamese(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    final i = _from.indexOf(ch);
    out.write(i < 0 ? ch : _to[i]);
  }
  return out.toString();
}

/// CSV (P-140): date, category, description, amount, currency (D-075 #4), payer, recorded by.
/// The amount is plain in the currency's units ("12.50", "1020000"). No receipts.
String expensesCsv(
  List<Expense> items, {
  required List<String> header,
  required String Function(Expense) category,
  required String Function(Expense) payer,
  required String Function(Expense) recordedBy,
}) {
  String cell(String v) {
    // Spreadsheet formula injection: a leading = + - @ is read as text.
    final safe = RegExp(r'^[=+\-@]').hasMatch(v) ? "'$v" : v;
    return '"${safe.replaceAll('"', '""')}"';
  }

  final rows = [header.map(cell).join(',')];
  for (final e in [...items]..sort((a, b) => a.spentOn.compareTo(b.spentOn))) {
    rows.add(
      [
        cell(isoDay(e.spentOn)),
        cell(category(e)),
        cell(e.note),
        minorPlain(e.amount, e.currency),
        cell(e.currency),
        cell(payer(e)),
        cell(recordedBy(e)),
      ].join(','),
    );
  }
  // BOM so spreadsheet apps read Vietnamese as UTF-8.
  return '﻿${rows.join('\r\n')}\r\n';
}

/// 1250 USD → "12.50"; 1020000 VND → "1020000" (CSV: no grouping, `.` as the mark).
String minorPlain(int amount, String currency) {
  final c = spCurrency(currency);
  if (c.exponent == 0) return '$amount';
  final abs = amount.abs();
  return '${amount < 0 ? '-' : ''}${abs ~/ c.unit}.'
      '${(abs % c.unit).toString().padLeft(c.exponent, '0')}';
}
