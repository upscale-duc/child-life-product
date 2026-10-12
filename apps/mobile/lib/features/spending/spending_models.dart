import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/widgets/cl_icon.dart';
import '../baby/baby_models.dart';
import '../care/care_models.dart';

/// Chi tiêu (Figma v1.1 8a–8o; D-055 … D-057, P-140). Mirrors
/// `packages/contracts/src/spending.ts`; plan `docs/product/spending-plan.md`.

String _hex() => const Uuid().v4().replaceAll('-', '');
String newExpenseId() => 'x_${_hex()}';
String newRecurringId() => 'rx_${_hex()}';
String newCategoryId() => 'c_${_hex().substring(0, 20)}';

abstract final class SpendingLimits {
  static const amountMax = 1000000000;
  static const noteMax = 80;
  static const categoryNameMax = 24;
  static const recurringTitleMax = 60;

  /// "Gần chạm mức" from this share of a category cap.
  static const nearCapShare = 0.9;
}

final _day = DateFormat('yyyy-MM-dd');
String isoDay(DateTime d) => _day.format(DateTime(d.year, d.month, d.day));
DateTime parseDay(String s) {
  final d = DateTime.tryParse(s);
  return d == null ? DateTime(1970) : DateTime(d.year, d.month, d.day);
}

/// "Ai trả" (D-056): a member's label snapshot, or null for "Khác".
@immutable
class Payer {
  const Payer({required this.uid, required this.author});
  final String uid;
  final CareAuthor author;

  factory Payer.of(Membership m) => Payer(uid: m.uid, author: CareAuthor.of(m));

  static Payer? fromJson(Object? json) {
    if (json is! Map) return null;
    return Payer(
      uid: json['uid'] as String? ?? '',
      author: CareAuthor.fromJson(json),
    );
  }

  Map<String, Object?> toJson() => {'uid': uid, ...author.toJson()};

  @override
  bool operator ==(Object other) => other is Payer && other.uid == uid;
  @override
  int get hashCode => uid.hashCode;
}

enum ExpenseSource { manual, recurring, vaccine }

@immutable
class Expense {
  const Expense({
    required this.id,
    required this.babyId,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.spentOn,
    required this.payer,
    required this.source,
    required this.createdBy,
    required this.author,
    this.receiptPath,
    this.sourceRef,
    this.createdAt,
    this.updatedAt,
    this.deleted = false,
    this.pending = false,
  });

  final String id;
  final String babyId;

  /// Whole VND.
  final int amount;
  final String categoryId;
  final String note;

  /// The day it was spent, in the baby's zone (date only).
  final DateTime spentOn;
  final Payer? payer;
  final String? receiptPath;
  final ExpenseSource source;

  /// A recurring item id, or a vaccine dose key (8k).
  final String? sourceRef;
  final String createdBy;
  final CareAuthor author;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool deleted;

  /// Not on the server yet ("Chờ đồng bộ").
  final bool pending;

  bool get hasReceipt => receiptPath != null;

  static Expense? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data();
    if (j == null) return null;
    return Expense(
      id: d.id,
      babyId: d.reference.parent.parent?.id ?? '',
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      categoryId: j['categoryId'] as String? ?? 'c_other',
      note: j['note'] as String? ?? '',
      spentOn: parseDay(j['spentOn'] as String? ?? ''),
      payer: Payer.fromJson(j['payer']),
      receiptPath: j['receiptPath'] as String?,
      source:
          ExpenseSource.values.asNameMap()[j['source']] ?? ExpenseSource.manual,
      sourceRef: j['sourceRef'] as String?,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
      createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (j['updatedAt'] as Timestamp?)?.toDate(),
      deleted: j['deleted'] == true,
      pending: d.metadata.hasPendingWrites,
    );
  }

  Expense copyWith({
    int? amount,
    String? categoryId,
    String? note,
    DateTime? spentOn,
    Payer? Function()? payer,
    String? Function()? receiptPath,
  }) => Expense(
    id: id,
    babyId: babyId,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    spentOn: spentOn ?? this.spentOn,
    payer: payer == null ? this.payer : payer(),
    receiptPath: receiptPath == null ? this.receiptPath : receiptPath(),
    source: source,
    sourceRef: sourceRef,
    createdBy: createdBy,
    author: author,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deleted: deleted,
    pending: pending,
  );
}

/// The eight category tints (8n), mapped to theme colours by the UI.
enum CategoryTint {
  growth,
  bottle,
  diaper,
  pump,
  breast,
  sleep,
  sunshine,
  mint,
}

/// Which built-in a category is, for its translated name (null for a custom one).
enum BuiltInCategory { childcare, milk, diaper, health, clothes, other }

/// 8m: the family's categories. Built-ins keep a translated name unless renamed.
@immutable
class SpendingCategory {
  const SpendingCategory({
    required this.id,
    required this.icon,
    required this.tint,
    required this.order,
    this.name,
    this.hidden = false,
    this.builtIn = false,
    this.stored = true,
  });

  final String id;

  /// Null: a built-in's translated name.
  final String? name;
  final ClIcons icon;
  final CategoryTint tint;
  final int order;
  final bool hidden;
  final bool builtIn;

  /// False for a built-in shown before anyone wrote it (seeded on first edit).
  final bool stored;

  BuiltInCategory? get kind => switch (id) {
    'c_childcare' => BuiltInCategory.childcare,
    'c_milk' => BuiltInCategory.milk,
    'c_diaper' => BuiltInCategory.diaper,
    'c_health' => BuiltInCategory.health,
    'c_clothes' => BuiltInCategory.clothes,
    'c_other' => BuiltInCategory.other,
    _ => null,
  };

  /// "Khác": cannot be deleted or hidden (8m).
  bool get locked => id == otherCategoryId;

  static SpendingCategory? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final j = d.data();
    if (j == null) return null;
    return SpendingCategory(
      id: d.id,
      name: j['name'] as String?,
      icon: ClIcons.values.asNameMap()[j['icon']] ?? ClIcons.grid,
      tint: CategoryTint.values.asNameMap()[j['tint']] ?? CategoryTint.sleep,
      order: (j['order'] as num?)?.toInt() ?? 0,
      hidden: j['hidden'] == true,
      builtIn: j['builtIn'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'icon': icon.name,
    'tint': tint.name,
    'order': order,
    'hidden': hidden,
    'builtIn': builtIn,
  };

  SpendingCategory copyWith({
    String? Function()? name,
    ClIcons? icon,
    CategoryTint? tint,
    int? order,
    bool? hidden,
  }) => SpendingCategory(
    id: id,
    name: name == null ? this.name : name(),
    icon: icon ?? this.icon,
    tint: tint ?? this.tint,
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    builtIn: builtIn,
    stored: stored,
  );
}

const otherCategoryId = 'c_other';

/// Y tế & tiêm chủng: where a vaccine cost goes (8k).
const healthCategoryId = 'c_health';

/// The six every family starts with, in Figma's order (8c, 8m).
const builtInCategories = [
  SpendingCategory(
    id: 'c_childcare',
    icon: ClIcons.family,
    tint: CategoryTint.growth,
    order: 0,
    builtIn: true,
    stored: false,
  ),
  SpendingCategory(
    id: 'c_milk',
    icon: ClIcons.feed,
    tint: CategoryTint.bottle,
    order: 1,
    builtIn: true,
    stored: false,
  ),
  SpendingCategory(
    id: 'c_diaper',
    icon: ClIcons.diaper,
    tint: CategoryTint.diaper,
    order: 2,
    builtIn: true,
    stored: false,
  ),
  SpendingCategory(
    id: healthCategoryId,
    icon: ClIcons.heart,
    tint: CategoryTint.pump,
    order: 3,
    builtIn: true,
    stored: false,
  ),
  SpendingCategory(
    id: 'c_clothes',
    icon: ClIcons.star,
    tint: CategoryTint.breast,
    order: 4,
    builtIn: true,
    stored: false,
  ),
  SpendingCategory(
    id: otherCategoryId,
    icon: ClIcons.grid,
    tint: CategoryTint.sleep,
    order: 99,
    builtIn: true,
    stored: false,
  ),
];

/// 8n: what a category can look like.
const categoryIcons = [
  ClIcons.family,
  ClIcons.feed,
  ClIcons.diaper,
  ClIcons.heart,
  ClIcons.star,
  ClIcons.journal,
  ClIcons.grid,
  ClIcons.spark,
  ClIcons.sleep,
  ClIcons.ruler,
  ClIcons.camera,
  ClIcons.cake,
  ClIcons.bell,
  ClIcons.globe,
  ClIcons.today,
  ClIcons.drop,
];

/// Stored categories over the built-ins not written yet, by order ("Khác" last).
List<SpendingCategory> mergeCategories(List<SpendingCategory> stored) {
  final byId = {for (final c in stored) c.id: c};
  final all = [
    ...stored,
    for (final b in builtInCategories)
      if (!byId.containsKey(b.id)) b,
  ];
  all.sort((a, b) {
    if (a.locked != b.locked) return a.locked ? 1 : -1;
    return a.order != b.order
        ? a.order.compareTo(b.order)
        : a.id.compareTo(b.id);
  });
  return all;
}

/// 8h: one standing monthly total and optional caps per category.
@immutable
class Budget {
  const Budget({this.monthlyTotal, this.caps = const {}, this.alert80 = true});

  final int? monthlyTotal;
  final Map<String, int> caps;
  final bool alert80;

  static const empty = Budget();

  bool get isSet => monthlyTotal != null && monthlyTotal! > 0;

  factory Budget.fromJson(Map<String, dynamic>? j) => j == null
      ? empty
      : Budget(
          monthlyTotal: (j['monthlyTotal'] as num?)?.toInt(),
          caps: {
            for (final e in ((j['caps'] as Map?) ?? const {}).entries)
              if (e.value is num) '${e.key}': (e.value as num).toInt(),
          },
          alert80: j['alert80'] != false,
        );

  Map<String, Object?> toJson() => {
    'monthlyTotal': monthlyTotal,
    'caps': caps,
    'alert80': alert80,
  };
}

/// 8i: twice a month on fixed days, every N weeks from a date, or once a year.
@immutable
sealed class RecurringSchedule {
  const RecurringSchedule();

  Map<String, Object?> toJson();

  static RecurringSchedule fromJson(Object? json) {
    final j = json is Map ? json : const {};
    switch (j['kind']) {
      case 'weeks':
        return EveryWeeks(
          every: (j['every'] as num?)?.toInt() ?? 1,
          startOn: parseDay(j['startOn'] as String? ?? ''),
        );
      case 'yearly':
        return Yearly(
          month: (j['month'] as num?)?.toInt() ?? 1,
          day: (j['day'] as num?)?.toInt() ?? 1,
        );
      default:
        return Monthly([
          for (final d in (j['days'] as List? ?? const [1]))
            if (d is num) d.toInt(),
        ]);
    }
  }

  /// Whether [day] (date only) is due. A day past a month's end falls on its last day.
  bool isDue(DateTime day);

  /// The next due day strictly after [after], within a year.
  DateTime? nextAfter(DateTime after) {
    var d = DateTime(after.year, after.month, after.day + 1);
    for (var i = 0; i < 400; i++) {
      if (isDue(d)) return d;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return null;
  }
}

int _lastDay(int year, int month) => DateTime(year, month + 1, 0).day;

class Monthly extends RecurringSchedule {
  const Monthly(this.days);
  final List<int> days;

  @override
  bool isDue(DateTime day) {
    final last = _lastDay(day.year, day.month);
    return days.any((n) => (n > last ? last : n) == day.day);
  }

  @override
  Map<String, Object?> toJson() => {'kind': 'monthly', 'days': days};
}

class EveryWeeks extends RecurringSchedule {
  const EveryWeeks({required this.every, required this.startOn});
  final int every;
  final DateTime startOn;

  @override
  bool isDue(DateTime day) {
    final diff = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(startOn.year, startOn.month, startOn.day)).inDays;
    return diff >= 0 && diff % (7 * every) == 0;
  }

  @override
  Map<String, Object?> toJson() => {
    'kind': 'weeks',
    'every': every,
    'startOn': isoDay(startOn),
  };
}

class Yearly extends RecurringSchedule {
  const Yearly({required this.month, required this.day});
  final int month;
  final int day;

  @override
  bool isDue(DateTime d) {
    final last = _lastDay(d.year, d.month);
    return d.month == month && (day > last ? last : day) == d.day;
  }

  @override
  Map<String, Object?> toJson() => {
    'kind': 'yearly',
    'month': month,
    'day': day,
  };
}

/// `babies/{babyId}/recurringExpenses/{id}` (8i).
@immutable
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.amount,
    required this.payer,
    required this.schedule,
    required this.enabled,
    required this.createdBy,
    required this.author,
  });

  final String id;
  final String title;
  final String categoryId;
  final int amount;
  final Payer? payer;
  final RecurringSchedule schedule;
  final bool enabled;
  final String createdBy;
  final CareAuthor author;

  static RecurringExpense? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final j = d.data();
    if (j == null) return null;
    return RecurringExpense(
      id: d.id,
      title: j['title'] as String? ?? '',
      categoryId: j['categoryId'] as String? ?? otherCategoryId,
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      payer: Payer.fromJson(j['payer']),
      schedule: RecurringSchedule.fromJson(j['schedule']),
      enabled: j['enabled'] == true,
      createdBy: j['createdBy'] as String? ?? '',
      author: CareAuthor.fromJson(j['author']),
    );
  }
}

/// Who may do what with spending on this baby (D-055).
@immutable
class SpendingAccess {
  const SpendingAccess({
    required this.uid,
    required this.parent,
    required this.viewAll,
    required this.record,
  });

  final String uid;

  /// Cùng nuôi: everything (budget, recurring, categories, anyone's items).
  final bool parent;

  /// "Xem toàn bộ chi tiêu" (or Cùng nuôi): totals, statistics, every item.
  final bool viewAll;

  /// "Ghi khoản đã chi" (or Cùng nuôi): records items, sees and edits their own.
  final bool record;

  bool get any => viewAll || record;

  factory SpendingAccess.of(Membership m) {
    final parent = m.role == MemberRole.coParent;
    return SpendingAccess(
      uid: m.uid,
      parent: parent,
      viewAll: parent || m.extraRights.viewSpending,
      record: parent || m.extraRights.recordSpending,
    );
  }

  bool canEdit(Expense e) => parent || (record && e.createdBy == uid);

  @override
  bool operator ==(Object other) =>
      other is SpendingAccess &&
      other.uid == uid &&
      other.parent == parent &&
      other.viewAll == viewAll &&
      other.record == record;
  @override
  int get hashCode => Object.hash(uid, parent, viewAll, record);
}
