import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';

/// Nhập chi tiêu (D-060, P-144). Mirrors `packages/contracts/src/spending-import.ts`; the server
/// writes `babies/{babyId}/spendingImports/{importId}`, the app only reads it.

String newImportId() => 'im_${const Uuid().v4().replaceAll('-', '')}';

enum ImportKind { file, text, images }

enum ImportStatus { analyzing, ready, queued, importing, done, failed, undone }

enum ImportIssue {
  noDate('no-date'),
  badDate('bad-date'),
  futureDate('future-date'),
  noAmount('no-amount'),
  badAmount('bad-amount'),
  tooLarge('too-large'),
  otherCurrency('other-currency'),
  income('income'),
  duplicate('duplicate');

  const ImportIssue(this.wire);
  final String wire;

  static ImportIssue? of(Object? wire) =>
      values.where((i) => i.wire == wire).firstOrNull;
}

/// Which grid column holds what (null = not in the file).
@immutable
class ImportMapping {
  const ImportMapping({
    required this.firstRow,
    this.date,
    this.amount,
    this.note = const [],
    this.category,
    this.payer,
  });

  final int firstRow;
  final int? date;
  final int? amount;
  final List<int> note;
  final int? category;
  final int? payer;

  factory ImportMapping.fromJson(Object? json) {
    final j = json is Map ? json : const {};
    int? n(Object? v) => v is num ? v.toInt() : null;
    return ImportMapping(
      firstRow: n(j['firstRow']) ?? 0,
      date: n(j['date']),
      amount: n(j['amount']),
      note: [
        for (final v in (j['note'] as List? ?? const []))
          if (v is num) v.toInt(),
      ],
      category: n(j['category']),
      payer: n(j['payer']),
    );
  }

  Map<String, Object?> toJson() => {
    'firstRow': firstRow,
    'date': date,
    'amount': amount,
    'note': note,
    'category': category,
    'payer': payer,
  };

  ImportMapping copyWith({
    int? Function()? date,
    int? Function()? amount,
    List<int>? note,
    int? Function()? category,
    int? Function()? payer,
  }) => ImportMapping(
    firstRow: firstRow,
    date: date == null ? this.date : date(),
    amount: amount == null ? this.amount : amount(),
    note: note ?? this.note,
    category: category == null ? this.category : category(),
    payer: payer == null ? this.payer : payer(),
  );
}

enum DateOrder { dmy, mdy }

/// Which rows are spending when a file mixes signs.
enum RowSign { all, negative, positive }

@immutable
class ImportOptions {
  const ImportOptions({
    this.dateOrder = DateOrder.dmy,
    this.rows = RowSign.all,
    this.skipDuplicates = true,
  });

  final DateOrder dateOrder;
  final RowSign rows;
  final bool skipDuplicates;

  factory ImportOptions.fromJson(Object? json) {
    final j = json is Map ? json : const {};
    return ImportOptions(
      dateOrder: DateOrder.values.asNameMap()[j['dateOrder']] ?? DateOrder.dmy,
      rows: RowSign.values.asNameMap()[j['rows']] ?? RowSign.all,
      skipDuplicates: j['skipDuplicates'] != false,
    );
  }

  Map<String, Object?> toJson() => {
    'dateOrder': dateOrder.name,
    'rows': rows.name,
    'skipDuplicates': skipDuplicates,
  };

  ImportOptions copyWith({
    DateOrder? dateOrder,
    RowSign? rows,
    bool? skipDuplicates,
  }) => ImportOptions(
    dateOrder: dateOrder ?? this.dateOrder,
    rows: rows ?? this.rows,
    skipDuplicates: skipDuplicates ?? this.skipDuplicates,
  );
}

/// Where a category named in the file goes: an existing one, or a new one.
@immutable
sealed class CategoryChoice {
  const CategoryChoice();

  static CategoryChoice? fromJson(Object? json) {
    if (json is! Map) return null;
    return switch (json['kind']) {
      'existing' => ExistingCategory(json['id'] as String? ?? 'c_other'),
      'new' => NewCategory(json['name'] as String? ?? ''),
      _ => null,
    };
  }

  Map<String, Object?> toJson();
}

class ExistingCategory extends CategoryChoice {
  const ExistingCategory(this.id);
  final String id;
  @override
  Map<String, Object?> toJson() => {'kind': 'existing', 'id': id};
  @override
  bool operator ==(Object other) => other is ExistingCategory && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

class NewCategory extends CategoryChoice {
  const NewCategory(this.name);
  final String name;
  @override
  Map<String, Object?> toJson() => {'kind': 'new', 'name': name};
  @override
  bool operator ==(Object other) => other is NewCategory && other.name == name;
  @override
  int get hashCode => name.hashCode;
}

@immutable
class ImportPreviewRow {
  const ImportPreviewRow({
    required this.row,
    required this.spentOn,
    required this.amount,
    required this.note,
    required this.category,
    required this.payer,
    required this.issue,
  });

  final int row;
  final String? spentOn;
  final int? amount;
  final String note;
  final String category;
  final String payer;
  final ImportIssue? issue;

  factory ImportPreviewRow.fromJson(Object? json) {
    final j = json is Map ? json : const {};
    return ImportPreviewRow(
      row: (j['row'] as num?)?.toInt() ?? 0,
      spentOn: j['spentOn'] as String?,
      amount: (j['amount'] as num?)?.toInt(),
      note: j['note'] as String? ?? '',
      category: j['category'] as String? ?? '',
      payer: j['payer'] as String? ?? '',
      issue: ImportIssue.of(j['issue']),
    );
  }
}

/// A category or payer named in the file, with the server's suggestion.
@immutable
class SourceName<T> {
  const SourceName({
    required this.key,
    required this.name,
    required this.rows,
    required this.suggested,
  });
  final String key;
  final String name;
  final int rows;
  final T? suggested;
}

@immutable
class ImportCounts {
  const ImportCounts({
    this.rows = 0,
    this.ready = 0,
    this.duplicates = 0,
    this.income = 0,
    this.errors = 0,
  });
  final int rows;
  final int ready;
  final int duplicates;
  final int income;
  final int errors;

  factory ImportCounts.fromJson(Object? json) {
    final j = json is Map ? json : const {};
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    return ImportCounts(
      rows: n('rows'),
      ready: n('ready'),
      duplicates: n('duplicates'),
      income: n('income'),
      errors: n('errors'),
    );
  }
}

/// `babies/{babyId}/spendingImports/{importId}`.
@immutable
class SpendingImport {
  const SpendingImport({
    required this.id,
    required this.kind,
    required this.status,
    required this.fileName,
    required this.preset,
    required this.columns,
    required this.mapping,
    required this.options,
    required this.mixedSigns,
    required this.ambiguousDates,
    required this.counts,
    required this.preview,
    this.skipped = const [],
    this.total = (amount: 0, from: null, to: null),
    required this.categories,
    required this.payers,
    required this.progress,
    required this.imported,
    required this.issues,
    required this.failure,
    required this.createdBy,
    required this.createdAt,
    required this.finishedAt,
    required this.undoUntil,
  });

  final String id;
  final ImportKind kind;
  final ImportStatus status;
  final String? fileName;
  final String? preset;
  final List<String> columns;
  final ImportMapping mapping;
  final ImportOptions options;
  final bool mixedSigns;
  final bool ambiguousDates;
  final ImportCounts counts;

  /// The first rows that will be imported.
  final List<ImportPreviewRow> preview;

  /// The first rows left out, with why.
  final List<ImportPreviewRow> skipped;

  /// What will be imported: the sum and the first and last day.
  final ({int amount, String? from, String? to}) total;
  final List<SourceName<CategoryChoice>> categories;
  final List<SourceName<String>> payers;

  /// Percent written (0–100) while importing.
  final int progress;

  /// Expenses written so far (all of them once done).
  final int imported;
  final List<(int row, ImportIssue issue)> issues;
  final String? failure;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? finishedAt;
  final DateTime? undoUntil;

  /// Also after a failure that had already written some expenses (the server then sets
  /// [undoUntil]).
  bool canUndo(DateTime now) =>
      (status == ImportStatus.done || status == ImportStatus.failed) &&
      undoUntil != null &&
      now.isBefore(undoUntil!);

  bool get working =>
      status == ImportStatus.analyzing ||
      status == ImportStatus.queued ||
      status == ImportStatus.importing;

  static SpendingImport? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final j = d.data();
    if (j == null) return null;
    DateTime? t(Object? v) => v is Timestamp ? v.toDate() : null;
    List<Map<Object?, Object?>> maps(Object? v) => [
      for (final x in (v as List? ?? const []))
        if (x is Map) x,
    ];
    return SpendingImport(
      id: d.id,
      kind: ImportKind.values.asNameMap()[j['kind']] ?? ImportKind.file,
      status:
          ImportStatus.values.asNameMap()[j['status']] ?? ImportStatus.failed,
      fileName: j['fileName'] as String?,
      preset: j['preset'] as String?,
      columns: [for (final c in (j['columns'] as List? ?? const [])) '$c'],
      mapping: ImportMapping.fromJson(j['mapping']),
      options: ImportOptions.fromJson(j['options']),
      mixedSigns: j['mixedSigns'] == true,
      ambiguousDates: j['ambiguousDates'] == true,
      counts: ImportCounts.fromJson(j['counts']),
      preview: [
        for (final r in (j['preview'] as List? ?? const []))
          ImportPreviewRow.fromJson(r),
      ],
      skipped: [
        for (final r in (j['skipped'] as List? ?? const []))
          ImportPreviewRow.fromJson(r),
      ],
      total: switch (j['total']) {
        final Map<Object?, Object?> t => (
          amount: (t['amount'] as num?)?.toInt() ?? 0,
          from: t['from'] as String?,
          to: t['to'] as String?,
        ),
        _ => (amount: 0, from: null, to: null),
      },
      categories: [
        for (final c in maps(j['categories']))
          SourceName<CategoryChoice>(
            key: c['key'] as String? ?? '',
            name: c['name'] as String? ?? '',
            rows: (c['rows'] as num?)?.toInt() ?? 0,
            suggested: CategoryChoice.fromJson(c['suggested']),
          ),
      ],
      payers: [
        for (final p in maps(j['payers']))
          SourceName<String>(
            key: p['key'] as String? ?? '',
            name: p['name'] as String? ?? '',
            rows: (p['rows'] as num?)?.toInt() ?? 0,
            suggested: p['suggested'] as String?,
          ),
      ],
      progress: (j['progress'] as num?)?.toInt() ?? 0,
      imported: (j['imported'] as num?)?.toInt() ?? 0,
      issues: [
        for (final i in maps(j['issues']))
          if (ImportIssue.of(i['issue']) case final issue?)
            ((i['row'] as num?)?.toInt() ?? 0, issue),
      ],
      failure: j['failure'] as String?,
      createdBy: j['createdBy'] as String? ?? '',
      createdAt: t(j['createdAt']),
      finishedAt: t(j['finishedAt']),
      undoUntil: t(j['undoUntil']),
    );
  }
}

/// One page of "Xem tất cả".
@immutable
class ImportPage {
  const ImportPage({
    required this.rows,
    required this.total,
    required this.page,
    required this.pages,
  });
  final List<ImportPreviewRow> rows;
  final int total;
  final int page;
  final int pages;
}

/// A server refusal, by its reason (`SpendingError` in Functions).
class ImportException implements Exception {
  const ImportException(this.reason);
  final String reason;
}

class SpendingImportRepository {
  SpendingImportRepository(this._db, this._functions, [FirebaseStorage? s])
    : _storage = s ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _col(String babyId) =>
      _db.collection('babies/$babyId/spendingImports');

  Stream<List<SpendingImport>> watchAll(String babyId) => _col(babyId)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => [for (final d in s.docs) ?SpendingImport.fromSnapshot(d)]);

  Stream<SpendingImport?> watch(String babyId, String importId) =>
      _col(babyId).doc(importId).snapshots().map(SpendingImport.fromSnapshot);

  /// The grid the phone read, for the server (`imports/{uid}/{importId}.json`).
  Future<void> uploadGrid(
    String uid,
    String importId,
    List<List<String>> grid,
  ) => _storage
      .ref('imports/$uid/$importId.json')
      .putData(
        Uint8List.fromList(utf8.encode(jsonEncode(grid))),
        SettableMetadata(contentType: 'application/json'),
      );

  /// Photos for the AI reading (`imports/{uid}/{importId}/{n}.jpg`).
  Future<void> uploadPhoto(
    String uid,
    String importId,
    int n,
    Uint8List jpeg,
  ) => _storage
      .ref('imports/$uid/$importId/$n.jpg')
      .putData(jpeg, SettableMetadata(contentType: 'image/jpeg'));

  /// Reading 5 photos with AI can take a few minutes on the server.
  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, Object?> data, {
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      final r = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call<Map<String, dynamic>?>(data);
      return r.data ?? const {};
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map && details['reason'] is String
          ? details['reason'] as String
          : e.code;
      throw ImportException(reason);
    }
  }

  /// First call: names the source. Later calls: read again with [mapping] / [options].
  Future<void> analyze({
    required String babyId,
    required String importId,
    required ImportKind kind,
    String? fileName,
    String? text,
    int? images,
    ImportMapping? mapping,
    ImportOptions? options,
  }) => _call('analyzeSpendingImport', timeout: const Duration(seconds: 310), {
    'babyId': babyId,
    'importId': importId,
    'kind': kind.name,
    'fileName': ?fileName,
    'text': ?text,
    'images': ?images,
    if (mapping != null) 'mapping': mapping.toJson(),
    if (options != null) 'options': options.toJson(),
  });

  Future<void> confirm({
    required String babyId,
    required String importId,
    required ImportMapping mapping,
    required ImportOptions options,
    required Map<String, CategoryChoice> categories,
    required Map<String, String?> payers,
  }) => _call('confirmSpendingImport', {
    'babyId': babyId,
    'importId': importId,
    'mapping': mapping.toJson(),
    'options': options.toJson(),
    'categories': {for (final e in categories.entries) e.key: e.value.toJson()},
    'payers': payers,
  });

  /// "Xem tất cả": one page of 50 rows that will be imported.
  Future<ImportPage> page(String babyId, String importId, int page) async {
    final r = await _call('spendingImportPage', {
      'babyId': babyId,
      'importId': importId,
      'page': page,
    });
    return ImportPage(
      rows: [
        for (final x in (r['rows'] as List? ?? const []))
          ImportPreviewRow.fromJson(x),
      ],
      total: (r['total'] as num?)?.toInt() ?? 0,
      page: (r['page'] as num?)?.toInt() ?? 0,
      pages: (r['pages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Returns how many expenses were removed.
  Future<int> undo(String babyId, String importId) async {
    final r = await _call('undoSpendingImport', {
      'babyId': babyId,
      'importId': importId,
    });
    return (r['removed'] as num?)?.toInt() ?? 0;
  }
}

final spendingImportRepositoryProvider = Provider<SpendingImportRepository>(
  (ref) => SpendingImportRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final spendingImportsProvider =
    StreamProvider.family<List<SpendingImport>, String>(
      (ref, babyId) =>
          ref.watch(spendingImportRepositoryProvider).watchAll(babyId),
    );

final spendingImportProvider =
    StreamProvider.family<SpendingImport?, (String, String)>(
      (ref, key) =>
          ref.watch(spendingImportRepositoryProvider).watch(key.$1, key.$2),
    );
