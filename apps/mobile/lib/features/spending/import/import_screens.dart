import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/route_guard.dart';
import '../../../core/design/cl_theme.dart';
import '../../../core/design/tabular_text.dart';
import '../../../core/design/tokens.g.dart';
import '../../../core/widgets/cl_button.dart';
import '../../../core/widgets/cl_feedback.dart';
import '../../../core/widgets/cl_icon.dart';
import '../../../core/widgets/cl_inputs.dart';
import '../../../core/widgets/cl_pressable.dart';
import '../../../core/widgets/cl_rows.dart';
import '../../../core/widgets/cl_segmented.dart';
import '../../../core/widgets/cl_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../baby/baby_models.dart';
import '../../family/family_repository.dart';
import '../spending_format.dart';
import '../spending_models.dart';
import '../spending_widgets.dart';
import 'import_reader.dart';
import 'import_repository.dart';

/// Nhập chi tiêu (D-060, P-144; not drawn, flagged for design review): choose a source, review
/// how it was read, confirm; the server imports and mails the result.

String importIssueLabel(AppLocalizations l10n, ImportIssue i) => switch (i) {
  ImportIssue.noDate => l10n.imIssueNoDate,
  ImportIssue.badDate => l10n.imIssueBadDate,
  ImportIssue.futureDate => l10n.imIssueFutureDate,
  ImportIssue.noAmount => l10n.imIssueNoAmount,
  ImportIssue.badAmount => l10n.imIssueBadAmount,
  ImportIssue.tooLarge => l10n.imIssueTooLarge,
  ImportIssue.otherCurrency => l10n.imIssueCurrency,
  ImportIssue.income => l10n.imIssueIncome,
  ImportIssue.duplicate => l10n.imIssueDuplicate,
};

String importFailureLabel(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'ai-unavailable' => l10n.imFailAiUnavailable,
      'ai-failed' => l10n.imFailAi,
      'empty' => l10n.imFailEmpty,
      'too-big' => l10n.imFailTooBig,
      'unavailable' || 'deadline-exceeded' => l10n.imFailOffline,
      _ => l10n.imFailGeneric,
    };

String readFailureLabel(AppLocalizations l10n, ReadFailure f) => switch (f) {
  ReadFailure.oldExcel => l10n.imReadOldExcel,
  ReadFailure.unsupported => l10n.imReadUnsupported,
  ReadFailure.empty => l10n.imFailEmpty,
  ReadFailure.tooBig => l10n.imFailTooBig,
  ReadFailure.broken => l10n.imReadBroken,
};

String importStatusLabel(AppLocalizations l10n, SpendingImport im) =>
    switch (im.status) {
      ImportStatus.analyzing => l10n.imStatusAnalyzing,
      ImportStatus.ready => l10n.imStatusReady,
      ImportStatus.queued || ImportStatus.importing => l10n.imStatusImporting,
      ImportStatus.done => l10n.imStatusDone(im.imported),
      ImportStatus.failed => l10n.imStatusFailed,
      ImportStatus.undone => l10n.imStatusUndone,
    };

// ---------- Nhập chi tiêu: choose a source ----------

class SpendingImportScreen extends ConsumerStatefulWidget {
  const SpendingImportScreen({super.key});

  @override
  ConsumerState<SpendingImportScreen> createState() =>
      _SpendingImportScreenState();
}

class _SpendingImportScreenState extends ConsumerState<SpendingImportScreen> {
  /// What is being done before the review opens ("Đang đọc tệp…").
  String? _busy;

  Future<void> _run(
    String busy,
    Future<String?> Function(String importId) start,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    final importId = newImportId();
    setState(() => _busy = busy);
    try {
      final id = await start(importId);
      if (id != null && mounted) {
        unawaited(router.push('${Routes.spendingImport}/$id/review'));
      }
    } on ReadException catch (e) {
      toaster.show(message: readFailureLabel(l10n, e.failure));
    } on ImportException catch (e) {
      toaster.show(message: importFailureLabel(l10n, e.reason));
    } on Object {
      toaster.show(message: l10n.imFailGeneric);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _file(SpendingScope scope) async {
    final l10n = AppLocalizations.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls', 'txt', 'tsv'],
    );
    final file = picked.singleOrNull;
    final path = file?.path;
    if (file == null || path == null || !mounted) return;
    final repo = ref.read(spendingImportRepositoryProvider);
    await _run(l10n.imBusyReading, (importId) async {
      final bytes = await File(path).readAsBytes();
      final grid = await compute((args) => readGrid(args.$1, args.$2), (
        file.name,
        bytes,
      ));
      await repo.uploadGrid(scope.me.uid, importId, grid);
      await repo.analyze(
        babyId: scope.babyId,
        importId: importId,
        kind: ImportKind.file,
        fileName: file.name.length > 120
            ? file.name.substring(0, 120)
            : file.name,
      );
      return importId;
    });
  }

  Future<void> _text(SpendingScope scope) async {
    final l10n = AppLocalizations.of(context);
    final text = await showClSheet<String>(
      context: context,
      builder: (_) => const _PasteSheet(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final repo = ref.read(spendingImportRepositoryProvider);
    await _run(l10n.imBusyAi, (importId) async {
      await repo.analyze(
        babyId: scope.babyId,
        importId: importId,
        kind: ImportKind.text,
        text: text.trim(),
      );
      return importId;
    });
  }

  Future<void> _photos(SpendingScope scope) async {
    final l10n = AppLocalizations.of(context);
    final files = await ImagePicker().pickMultiImage(
      limit: 5,
      maxWidth: 2400,
      maxHeight: 2400,
      requestFullMetadata: false,
    );
    if (files.isEmpty || !mounted) return;
    final repo = ref.read(spendingImportRepositoryProvider);
    await _run(l10n.imBusyAi, (importId) async {
      final chosen = files.take(5).toList();
      for (final (i, f) in chosen.indexed) {
        // No EXIF (no location); legible yet small.
        final jpeg = await FlutterImageCompress.compressWithList(
          await f.readAsBytes(),
          minWidth: 1600,
          minHeight: 1600,
          quality: 80,
          keepExif: false,
        );
        await repo.uploadPhoto(scope.me.uid, importId, i, jpeg);
      }
      await repo.analyze(
        babyId: scope.babyId,
        importId: importId,
        kind: ImportKind.images,
        images: chosen.length,
      );
      return importId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    if (!scope.access.parent) {
      return SpPage(
        children: [
          SpTitle(l10n.imTitle),
          const SizedBox(height: ClSpace.s4),
          SpBanner(icon: ClIcons.lock, text: l10n.imParentsOnly),
        ],
      );
    }
    final imports =
        ref.watch(spendingImportsProvider(scope.babyId)).value ??
        const <SpendingImport>[];
    final busy = _busy;
    return Stack(
      children: [
        SpPage(
          children: [
            SpTitle(l10n.imTitle),
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.imIntro(scope.baby?.nickname ?? ''),
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            SpGroup(
              children: [
                SpActionRow(
                  key: const Key('imFile'),
                  icon: ClIcons.download,
                  label: l10n.imSourceFile,
                  value: l10n.imSourceFileHint,
                  onTap: busy == null ? () => unawaited(_file(scope)) : null,
                ),
                SpActionRow(
                  key: const Key('imText'),
                  icon: ClIcons.journal,
                  label: l10n.imSourceText,
                  value: l10n.imSourceTextHint,
                  onTap: busy == null ? () => unawaited(_text(scope)) : null,
                ),
                SpActionRow(
                  key: const Key('imPhotos'),
                  icon: ClIcons.camera,
                  label: l10n.imSourcePhotos,
                  value: l10n.imSourcePhotosHint,
                  onTap: busy == null ? () => unawaited(_photos(scope)) : null,
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            SpBanner(icon: ClIcons.lock, text: l10n.imPrivacy),
            if (imports.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s6),
              ClSectionHeader(title: l10n.imRecent),
              const SizedBox(height: ClSpace.s2),
              SpGroup(
                children: [
                  for (final im in imports)
                    SpActionRow(
                      icon: switch (im.kind) {
                        ImportKind.file => ClIcons.download,
                        ImportKind.text => ClIcons.journal,
                        ImportKind.images => ClIcons.camera,
                      },
                      label:
                          im.fileName ??
                          switch (im.kind) {
                            ImportKind.text => l10n.imSourceText,
                            _ => l10n.imSourcePhotos,
                          },
                      value: [
                        if (im.createdAt != null)
                          DateFormat('dd/MM, HH:mm').format(im.createdAt!),
                        importStatusLabel(l10n, im),
                      ].join(' · '),
                      onTap: () => context.push(
                        im.status == ImportStatus.ready
                            ? '${Routes.spendingImport}/${im.id}/review'
                            : '${Routes.spendingImport}/${im.id}',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        if (busy != null) _BusyOverlay(label: busy),
      ],
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Positioned.fill(
      child: ColoredBox(
        color: cl.colors.scrim,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(ClSpace.s8),
            padding: const EdgeInsets.all(ClSpace.s6),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(ClRadius.card),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: cl.colors.mintDeep),
                const SizedBox(height: ClSpace.s4),
                Text(label, textAlign: TextAlign.center, style: cl.text.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasteSheet extends StatefulWidget {
  const _PasteSheet();

  @override
  State<_PasteSheet> createState() => _PasteSheetState();
}

class _PasteSheetState extends State<_PasteSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.imSourceText),
        Text(
          l10n.imPasteHint,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        ClTextField(
          key: const Key('imPaste'),
          controller: _text,
          placeholder: l10n.imPastePlaceholder,
          standalone: true,
          maxLength: 20000,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.imRead,
          expand: true,
          onPressed: _text.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_text.text),
        ),
        const SizedBox(height: ClSpace.s2),
      ],
    );
  }
}

// ---------- Review ----------

class SpendingImportReviewScreen extends ConsumerStatefulWidget {
  const SpendingImportReviewScreen({required this.importId, super.key});
  final String importId;

  @override
  ConsumerState<SpendingImportReviewScreen> createState() =>
      _SpendingImportReviewScreenState();
}

class _SpendingImportReviewScreenState
    extends ConsumerState<SpendingImportReviewScreen> {
  /// The user's choices, over the server's suggestions.
  final _categories = <String, CategoryChoice?>{};
  final _payers = <String, String?>{};
  final _payersSet = <String>{};
  bool _busy = false;

  Future<void> _reread(
    SpendingScope scope,
    SpendingImport im, {
    ImportMapping? mapping,
    ImportOptions? options,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(spendingImportRepositoryProvider)
          .analyze(
            babyId: scope.babyId,
            importId: im.id,
            kind: im.kind,
            mapping: mapping ?? im.mapping,
            options: options ?? im.options,
          );
    } on ImportException catch (e) {
      toaster.show(message: importFailureLabel(l10n, e.reason));
    } on Object {
      toaster.show(message: l10n.imFailGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  CategoryChoice? _categoryOf(SourceName<CategoryChoice> c) =>
      _categories.containsKey(c.key) ? _categories[c.key] : c.suggested;

  String? _payerOf(SourceName<String> p) =>
      _payersSet.contains(p.key) ? _payers[p.key] : p.suggested;

  Future<void> _confirm(SpendingScope scope, SpendingImport im) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(spendingImportRepositoryProvider)
          .confirm(
            babyId: scope.babyId,
            importId: im.id,
            mapping: im.mapping,
            options: im.options,
            categories: {for (final c in im.categories) c.key: ?_categoryOf(c)},
            payers: {for (final p in im.payers) p.key: _payerOf(p)},
          );
      if (mounted) {
        router.pushReplacement('${Routes.spendingImport}/${im.id}');
      }
    } on ImportException catch (e) {
      toaster.show(message: importFailureLabel(l10n, e.reason));
    } on Object {
      toaster.show(message: l10n.imFailGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickColumn(
    SpendingScope scope,
    SpendingImport im,
    String title,
    int? current,
    ImportMapping Function(int?) apply,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showClSheet<(int?,)>(
      context: context,
      builder: (sheet) => _ChoiceSheet<int?>(
        title: title,
        current: current,
        options: [
          (null, l10n.imColumnNone),
          for (final (i, name) in im.columns.indexed) (i, name),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    await _reread(scope, im, mapping: apply(picked.$1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final im = ref
        .watch(spendingImportProvider((scope.babyId, widget.importId)))
        .value;
    if (im == null || im.status == ImportStatus.analyzing) {
      return SpPage(
        children: [
          SpTitle(l10n.imReviewTitle),
          const SizedBox(height: ClSpace.s8),
          Center(child: CircularProgressIndicator(color: cl.colors.mintDeep)),
        ],
      );
    }
    if (im.status != ImportStatus.ready) {
      return SpendingImportResultScreen(importId: im.id);
    }
    final locale = spLocale(context);
    final c = im.counts;
    final m = im.mapping;
    String col(int? i) =>
        i == null || i >= im.columns.length ? l10n.imColumnNone : im.columns[i];
    final members =
        ref.watch(familyMembersProvider(scope.babyId)).value ??
        const <Membership>[];
    String payerName(String? uid) {
      if (uid == null) return l10n.spPayerOther;
      final m = members.where((x) => x.uid == uid).firstOrNull;
      return m == null ? l10n.spPayerOther : payerLabel(l10n, Payer.of(m));
    }

    String choiceName(CategoryChoice? choice) => switch (choice) {
      ExistingCategory(:final id) => categoryName(l10n, scope.category(id)),
      NewCategory(:final name) => l10n.imNewCategory(name),
      null => categoryName(l10n, scope.category(otherCategoryId)),
    };

    return Stack(
      children: [
        SpPage(
          bottom: SpBottomButton(
            label: c.ready == 0
                ? l10n.imNothingToImport
                : l10n.imConfirm(c.ready),
            onPressed: c.ready == 0 || _busy
                ? null
                : () => unawaited(_confirm(scope, im)),
          ),
          children: [
            SpTitle(l10n.imReviewTitle),
            const SizedBox(height: ClSpace.s1),
            Text(
              [
                ?im.fileName,
                if (im.preset != null) l10n.imPreset(im.preset!),
              ].join(' · '),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            SpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.imWillImport(c.ready),
                    style: cl.text.headline.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ClSpace.s1),
                  Text(
                    [
                      l10n.imRows(c.rows),
                      if (c.duplicates > 0) l10n.imDuplicates(c.duplicates),
                      if (c.income > 0) l10n.imIncome(c.income),
                      if (c.errors > 0) l10n.imErrors(c.errors),
                    ].join(' · '),
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
            if (im.kind == ImportKind.file) ...[
              const SizedBox(height: ClSpace.s6),
              ClSectionHeader(title: l10n.imColumns),
              const SizedBox(height: ClSpace.s2),
              SpGroup(
                children: [
                  SpActionRow(
                    icon: ClIcons.today,
                    label: l10n.spDate,
                    value: col(m.date),
                    onTap: () => _pickColumn(
                      scope,
                      im,
                      l10n.spDate,
                      m.date,
                      (i) => m.copyWith(date: () => i),
                    ),
                  ),
                  SpActionRow(
                    icon: ClIcons.grid,
                    label: l10n.spAmount,
                    value: col(m.amount),
                    onTap: () => _pickColumn(
                      scope,
                      im,
                      l10n.spAmount,
                      m.amount,
                      (i) => m.copyWith(amount: () => i),
                    ),
                  ),
                  SpActionRow(
                    icon: ClIcons.journal,
                    label: l10n.spNote,
                    value: m.note.isEmpty
                        ? l10n.imColumnNone
                        : m.note.map(col).join(' + '),
                    onTap: () => _pickColumn(
                      scope,
                      im,
                      l10n.spNote,
                      m.note.firstOrNull,
                      (i) => m.copyWith(note: i == null ? const [] : [i]),
                    ),
                  ),
                  SpActionRow(
                    icon: ClIcons.star,
                    label: l10n.spCategory,
                    value: col(m.category),
                    onTap: () => _pickColumn(
                      scope,
                      im,
                      l10n.spCategory,
                      m.category,
                      (i) => m.copyWith(category: () => i),
                    ),
                  ),
                  SpActionRow(
                    icon: ClIcons.family,
                    label: l10n.spPayer,
                    value: col(m.payer),
                    onTap: () => _pickColumn(
                      scope,
                      im,
                      l10n.spPayer,
                      m.payer,
                      (i) => m.copyWith(payer: () => i),
                    ),
                  ),
                ],
              ),
            ],
            if (im.ambiguousDates || im.mixedSigns) ...[
              const SizedBox(height: ClSpace.s6),
              ClSectionHeader(title: l10n.imReading),
            ],
            if (im.ambiguousDates) ...[
              SpLabel(l10n.imDateOrder),
              ClSegmented<DateOrder>(
                options: DateOrder.values,
                selected: im.options.dateOrder,
                labelOf: (o) => switch (o) {
                  DateOrder.dmy => l10n.imDateDmy,
                  DateOrder.mdy => l10n.imDateMdy,
                },
                onChanged: (o) => unawaited(
                  _reread(
                    scope,
                    im,
                    options: im.options.copyWith(dateOrder: o),
                  ),
                ),
              ),
            ],
            if (im.mixedSigns) ...[
              SpLabel(l10n.imRowsAre),
              ClSegmented<RowSign>(
                options: const [
                  RowSign.negative,
                  RowSign.positive,
                  RowSign.all,
                ],
                selected: im.options.rows,
                labelOf: (o) => switch (o) {
                  RowSign.negative => l10n.imRowsNegative,
                  RowSign.positive => l10n.imRowsPositive,
                  RowSign.all => l10n.imRowsAll,
                },
                onChanged: (o) => unawaited(
                  _reread(scope, im, options: im.options.copyWith(rows: o)),
                ),
              ),
            ],
            const SizedBox(height: ClSpace.s3),
            SpGroup(
              children: [
                SpActionRow(
                  icon: ClIcons.check,
                  label: l10n.imSkipDuplicates,
                  value: l10n.imSkipDuplicatesHint,
                  trailing: ClToggle(
                    value: im.options.skipDuplicates,
                    semanticLabel: l10n.imSkipDuplicates,
                    onChanged: _busy
                        ? null
                        : (v) => unawaited(
                            _reread(
                              scope,
                              im,
                              options: im.options.copyWith(skipDuplicates: v),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (im.categories.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s6),
              ClSectionHeader(title: l10n.imCategories),
              const SizedBox(height: ClSpace.s2),
              SpGroup(
                children: [
                  for (final cat in im.categories)
                    SpActionRow(
                      key: Key('imCat-${cat.key}'),
                      icon: ClIcons.star,
                      label: l10n.imSourceRows(cat.name, cat.rows),
                      value: l10n.imInto(choiceName(_categoryOf(cat))),
                      onTap: () async {
                        final picked = await showClSheet<(CategoryChoice?,)>(
                          context: context,
                          builder: (_) => _ChoiceSheet<CategoryChoice?>(
                            title: cat.name,
                            current: _categoryOf(cat),
                            options: [
                              (
                                NewCategory(
                                  cat.name.length > 24
                                      ? cat.name.substring(0, 24)
                                      : cat.name,
                                ),
                                l10n.imNewCategory(cat.name),
                              ),
                              for (final c in scope.visible)
                                (
                                  c.locked ? null : ExistingCategory(c.id),
                                  categoryName(l10n, c),
                                ),
                            ],
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() => _categories[cat.key] = picked.$1);
                        }
                      },
                    ),
                ],
              ),
            ],
            if (im.payers.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s6),
              ClSectionHeader(title: l10n.spPayer),
              const SizedBox(height: ClSpace.s2),
              SpGroup(
                children: [
                  for (final p in im.payers)
                    SpActionRow(
                      icon: ClIcons.family,
                      label: l10n.imSourceRows(p.name, p.rows),
                      value: l10n.imInto(payerName(_payerOf(p))),
                      onTap: () async {
                        final picked = await showClSheet<(String?,)>(
                          context: context,
                          builder: (_) => _ChoiceSheet<String?>(
                            title: p.name,
                            current: _payerOf(p),
                            options: [
                              for (final m in members)
                                (m.uid, payerLabel(l10n, Payer.of(m))),
                              (null, l10n.spPayerOther),
                            ],
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _payersSet.add(p.key);
                            _payers[p.key] = picked.$1;
                          });
                        }
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: ClSpace.s6),
            ClSectionHeader(title: l10n.imPreview(im.preview.length)),
            const SizedBox(height: ClSpace.s2),
            SpGroup(
              children: [
                for (final r in im.preview) _PreviewRow(row: r, locale: locale),
              ],
            ),
          ],
        ),
        if (_busy) _BusyOverlay(label: l10n.imBusyReading),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.row, required this.locale});
  final ImportPreviewRow row;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final issue = row.issue;
    final day = row.spentOn == null
        ? '—'
        : DateFormat('dd/MM/yyyy').format(DateTime.parse(row.spentOn!));
    return Opacity(
      opacity: issue == null ? 1 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '${row.row}',
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.note.isEmpty ? '—' : row.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: spRowTitle(context),
                  ),
                  Text(
                    [
                      day,
                      if (row.category.isNotEmpty) row.category,
                    ].join(' · '),
                    style: spRowSub(context),
                  ),
                  if (issue != null)
                    Text(
                      importIssueLabel(l10n, issue),
                      style: cl.text.caption.copyWith(
                        color:
                            issue == ImportIssue.duplicate ||
                                issue == ImportIssue.income
                            ? cl.colors.inkMuted
                            : cl.colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ClTabularText(
              row.amount == null ? '—' : money(locale, row.amount!.abs()),
              style: spRowTitle(context).copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list of choices with a radio; returns the choice wrapped in a record (null is a choice).
class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.current,
    required this.options,
  });

  final String title;
  final T current;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        Flexible(
          child: SingleChildScrollView(
            child: SpGroup(
              children: [
                for (final (value, label) in options)
                  ClPressable(
                    onPressed: () => Navigator.of(context).pop((value,)),
                    semanticLabel: label,
                    selected: value == current,
                    pressedOpacity: ClPressable.surfaceOpacity,
                    child: Padding(
                      padding: const EdgeInsets.all(ClSpace.s4),
                      child: Row(
                        children: [
                          Expanded(child: Text(label, style: cl.text.body)),
                          ClRadio(selected: value == current),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

// ---------- Result ----------

class SpendingImportResultScreen extends ConsumerWidget {
  const SpendingImportResultScreen({required this.importId, super.key});
  final String importId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final scope = watchSpending(ref);
    if (scope == null) return ColoredBox(color: cl.colors.cloud);
    final im = ref
        .watch(spendingImportProvider((scope.babyId, importId)))
        .value;
    if (im == null) {
      return SpPage(children: [SpTitle(l10n.imTitle)]);
    }
    Widget icon(ClIcons i, Color soft, Color ink) => Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: ClIcon(i, size: 30, color: ink),
      ),
    );
    final c = im.counts;
    final details = [
      if (c.duplicates > 0) l10n.imDuplicates(c.duplicates),
      if (c.income > 0) l10n.imIncome(c.income),
      if (c.errors > 0) l10n.imErrors(c.errors),
    ];
    final undoUntil = im.undoUntil;
    return SpPage(
      children: [
        const SizedBox(height: ClSpace.s6),
        ...switch (im.status) {
          ImportStatus.analyzing || ImportStatus.ready => [
            icon(ClIcons.journal, cl.colors.surface2, cl.colors.ink),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.imStatusReady,
              textAlign: TextAlign.center,
              style: cl.text.title2,
            ),
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.imContinueReview,
              expand: true,
              onPressed: () => context.pushReplacement(
                '${Routes.spendingImport}/${im.id}/review',
              ),
            ),
          ],
          ImportStatus.queued || ImportStatus.importing => [
            // The bar below shows the progress; no endless spinner here.
            icon(ClIcons.download, cl.colors.mintSoft, cl.colors.mintText),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.imImporting,
              textAlign: TextAlign.center,
              style: cl.text.title2,
            ),
            const SizedBox(height: ClSpace.s3),
            ShareBar(
              share: im.progress / 100,
              color: cl.colors.mintDeep,
              height: 10,
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.imProgress(im.imported, c.ready),
              textAlign: TextAlign.center,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s4),
            SpBanner(icon: ClIcons.bell, text: l10n.imCanClose, mint: true),
          ],
          ImportStatus.done => [
            icon(ClIcons.check, cl.colors.mintSoft, cl.colors.mintText),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.imDone(im.imported),
              key: const Key('imDone'),
              textAlign: TextAlign.center,
              style: cl.text.title2,
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.imSkipped(details.join(', ')),
                textAlign: TextAlign.center,
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              ),
            ],
            const SizedBox(height: ClSpace.s2),
            Text(
              l10n.imEmailSent,
              textAlign: TextAlign.center,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: l10n.imSeeSpending,
              expand: true,
              onPressed: () => context.go(Routes.spending),
            ),
            if (im.canUndo(DateTime.now()) && undoUntil != null) ...[
              const SizedBox(height: ClSpace.s2),
              ClButton(
                key: const Key('imUndo'),
                label: l10n.imUndo(DateFormat('dd/MM').format(undoUntil)),
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => _undo(context, ref, scope, im),
              ),
            ],
            if (im.issues.isNotEmpty) ...[
              const SizedBox(height: ClSpace.s6),
              ClSectionHeader(title: l10n.imIssues),
              const SizedBox(height: ClSpace.s2),
              SpGroup(
                children: [
                  for (final (row, issue) in im.issues.take(100))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ClSpace.s4,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              l10n.imRow(row),
                              style: spRowSub(context),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              importIssueLabel(l10n, issue),
                              style: cl.text.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
          ImportStatus.failed => [
            icon(ClIcons.alert, cl.colors.errorSoft, cl.colors.error),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.imFailedTitle,
              textAlign: TextAlign.center,
              style: cl.text.title2,
            ),
            const SizedBox(height: ClSpace.s2),
            Text(
              importFailureLabel(l10n, im.failure ?? ''),
              textAlign: TextAlign.center,
              style: cl.text.body.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s6),
            ClButton(
              label: l10n.imTryAgain,
              expand: true,
              onPressed: () => context.pushReplacement(Routes.spendingImport),
            ),
            // Part was written before it failed: it can be taken back.
            if (im.canUndo(DateTime.now()) && undoUntil != null) ...[
              const SizedBox(height: ClSpace.s2),
              ClButton(
                label: l10n.imUndo(DateFormat('dd/MM').format(undoUntil)),
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () => _undo(context, ref, scope, im),
              ),
            ],
          ],
          ImportStatus.undone => [
            icon(ClIcons.retry, cl.colors.surface2, cl.colors.ink),
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.imUndoneTitle,
              textAlign: TextAlign.center,
              style: cl.text.title2,
            ),
          ],
        },
      ],
    );
  }

  Future<void> _undo(
    BuildContext context,
    WidgetRef ref,
    SpendingScope scope,
    SpendingImport im,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final sure = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.imUndoTitle),
          Text(
            l10n.imUndoBody(im.imported),
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            key: const Key('imUndoConfirm'),
            label: l10n.imUndoConfirm(im.imported),
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      final removed = await ref
          .read(spendingImportRepositoryProvider)
          .undo(scope.babyId, im.id);
      toaster.show(message: l10n.imUndone(removed));
    } on ImportException catch (e) {
      toaster.show(message: importFailureLabel(l10n, e.reason));
    } on Object {
      toaster.show(message: l10n.imFailGeneric);
    }
  }
}
