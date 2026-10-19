import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_repository.dart';
import '../me/me_models.dart' show formatBytes;
import '../me/me_repository.dart';
import '../me/me_widgets.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import 'auto_save_controller.dart';
import 'auto_save_engine.dart';
import 'auto_save_widgets.dart';

/// What AS07 hands to AS10: the ticked items and everything that was on screen.
@immutable
class AutoSaveDecision {
  const AutoSaveDecision({required this.chosen, required this.reviewed});
  final List<Candidate> chosen;
  final List<Candidate> reviewed;
}

/// Weeks of age sent on from the review this app run, per baby (P-171): their chip reads
/// "Tuần 3 · xong" once nothing of theirs waits. Not saved; a new run starts from what is pending.
final reviewedWeeksProvider =
    NotifierProvider<ReviewedWeeks, Map<String, Set<int>>>(ReviewedWeeks.new);

class ReviewedWeeks extends Notifier<Map<String, Set<int>>> {
  @override
  Map<String, Set<int>> build() => const {};

  void add(String babyId, int week) => state = {
    ...state,
    babyId: {...?state[babyId], week},
  };
}

/// Library items that are already in the baby's Kỷ niệm, uploaded by anyone ("Đã có", P-150):
/// same baby and the same capture second. Uploads are re-encoded, so bytes cannot be compared.
final _alreadySavedProvider = Provider.autoDispose<Set<String>>((ref) {
  final view = ref.watch(autoSaveProvider);
  final out = <String>{};
  final byBaby = <String, Set<int>>{};
  for (final c in view.state.pending) {
    final seconds = byBaby[c.match.babyId] ??= {
      for (final m
          in ref.watch(mediaProvider((c.match.babyId, true))).value ??
              const <MediaItem>[])
        if (!m.deleted) m.captureAt.millisecondsSinceEpoch ~/ 1000,
    };
    if (seconds.contains(c.asset.captureAt.millisecondsSinceEpoch ~/ 1000)) {
      out.add(c.asset.id);
    }
  }
  return out;
});

/// Whether a library item's original is on the phone ("Trên iCloud" otherwise); replaced in tests.
final libraryLocalProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  id,
) async {
  try {
    final a = await AssetEntity.fromId(id);
    return a == null || await a.isLocallyAvailable(isOrigin: true);
  } on Object {
    return true;
  }
});

enum _Filter { all, photos, videos }

// ---------- AS07 Gợi ý chờ duyệt ----------

class AutoSaveReviewScreen extends ConsumerStatefulWidget {
  const AutoSaveReviewScreen({super.key});

  @override
  ConsumerState<AutoSaveReviewScreen> createState() =>
      _AutoSaveReviewScreenState();
}

class _AutoSaveReviewScreenState extends ConsumerState<AutoSaveReviewScreen> {
  final _selected = <String>{};
  final _known = <String>{};
  final _expanded = <String>{};
  var _filter = _Filter.all;

  /// The week of age being reviewed (P-171), when the person chose one; otherwise the earliest
  /// week that still has suggestions.
  int? _week;

  /// Items one "Tải lên" may hold (D-070), from `publicConfig/limits`.
  var _cap = 200;

  /// What this review can still tick: its items, less those already in Kỷ niệm.
  var _live = <String>{};

  int get _picked => _selected.where(_live.contains).length;

  /// D-070: one review holds at most [_cap] picks. Groups already on screen stay; new ones join,
  /// in order, while their picks fit; the rest wait for the next review.
  List<SuggestionGroup> _round(
    List<SuggestionGroup> groups,
    Set<String> already,
  ) {
    final out = <SuggestionGroup>[];
    var picks = 0;
    var full = false;
    for (final g in groups) {
      final n = g.preselected.where((id) => !already.contains(id)).length;
      final shown = g.items.any((c) => _known.contains(c.asset.id));
      if (!shown && (full || (out.isNotEmpty && picks + n > _cap))) {
        full = true;
        continue;
      }
      out.add(g);
      picks += n;
    }
    return out;
  }

  /// New suggestions (a check still running) arrive with their group's pick ticked.
  void _learn(List<SuggestionGroup> groups, Set<String> already) {
    var picked = _picked;
    for (final g in groups) {
      for (final c in g.items) {
        if (_known.add(c.asset.id) &&
            g.preselected.contains(c.asset.id) &&
            !already.contains(c.asset.id) &&
            picked < _cap) {
          _selected.add(c.asset.id);
          picked++;
        }
      }
    }
  }

  /// Ticks [ids] while there is room; says so once the limit is reached (D-070).
  void _add(Iterable<String> ids) {
    var picked = _picked;
    for (final id in ids) {
      if (_selected.contains(id)) continue;
      if (picked >= _cap) {
        ClToaster.of(
          context,
        ).show(message: AppLocalizations.of(context).autoSaveRoundFull(_cap));
        return;
      }
      _selected.add(id);
      picked++;
    }
  }

  bool _keep(Candidate c) => switch (_filter) {
    _Filter.all => true,
    _Filter.photos => !c.asset.video,
    _Filter.videos => c.asset.video,
  };

  void _toggle(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _add([id]),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final view = ref.watch(autoSaveProvider);
    final already = ref.watch(_alreadySavedProvider);
    _cap =
        ref.watch(publicLimitsProvider).value?.autoSaveItemsPerApprove ?? _cap;
    final everything = view.groups();
    // P-171 (owner, 2026-10-19: "chọn scan hình tuần 1, tuần 2… tuần 1 xong thì đánh dấu
    // xong"): with one baby and a known date of birth, suggestions are reviewed and uploaded a
    // week of age at a time — a lô of 97 videos is too much for one upload — and a week with
    // nothing left reads "xong".
    final onlyBaby = {
      for (final g in everything) g.best.match.babyId,
    }.singleOrNull;
    final dob = onlyBaby == null
        ? null
        : ref.watch(babyPrivateProfileProvider(onlyBaby)).value?.dateOfBirth;
    final byWeek = <int, int>{};
    if (dob != null) {
      for (final g in everything) {
        byWeek.update(
          ageWeekOf(dob, g.captureAt),
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final pendingWeeks = byWeek.keys.toList()..sort();
    final week = dob == null || pendingWeeks.isEmpty
        ? null
        : byWeek.containsKey(_week)
        ? _week!
        : pendingWeeks.first;
    final scoped = week == null
        ? everything
        : [
            for (final g in everything)
              if (ageWeekOf(dob!, g.captureAt) == week) g,
          ];
    final doneWeeks = onlyBaby == null
        ? const <int>{}
        : ref.watch(reviewedWeeksProvider)[onlyBaby] ?? const <int>{};
    final weekChips = {...pendingWeeks, ...doneWeeks}.toList()..sort();
    final groups = _round(scoped, already);
    _live = {
      for (final g in groups)
        for (final c in g.items)
          if (!already.contains(c.asset.id)) c.asset.id,
    };
    _learn(groups, already);
    // Counted as the tiles shown (a group of near-copies is one), so the title, the chips, the
    // days and "Tiếp tục với n mục" agree; the grouped copies are told apart below (owner,
    // 2026-10-15: "4 items mà button nói 3").
    final total = everything.length;
    final all = [for (final g in groups) ...g.items];
    final photos = groups.where((g) => !g.best.asset.video).length;
    final shown = [
      for (final g in groups)
        if (g.items.any(_keep)) g,
    ];
    final babies = {for (final c in all) c.match.babyId};
    final name = joinNames(l10n, [
      for (final id in babies)
        ref.watch(babyProvider(id)).value?.nickname ?? '',
    ]);
    final chosen = [
      for (final c in all)
        if (_selected.contains(c.asset.id) && !already.contains(c.asset.id)) c,
    ];
    final chosenVideos = chosen.where((c) => c.asset.video).length;
    final bytes = chosen.fold<int>(0, (n, c) => n + c.asset.estimatedBytes);
    final merged = groups.fold<int>(0, (n, g) => n + g.items.length - 1);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    final last = view.state.lastScanAt;

    // Day sections, newest first.
    final days = <DateTime, List<SuggestionGroup>>{};
    for (final g in shown) {
      final d = g.captureAt;
      (days[DateTime(d.year, d.month, d.day)] ??= []).add(g);
    }
    String dayLabel(DateTime d) {
      final date = DateFormat('dd/MM', locale).format(d);
      final today = DateTime(now.year, now.month, now.day);
      if (d == today) return l10n.autoSaveDayToday(date);
      if (d == today.subtract(const Duration(days: 1))) {
        return l10n.autoSaveDayYesterday(date);
      }
      return date;
    }

    Widget tile(Candidate c, {SuggestionGroup? group}) {
      final id = c.asset.id;
      final done = already.contains(id);
      final cloud = !(ref.watch(libraryLocalProvider(id)).value ?? true);
      final more = group == null ? 0 : group.items.length - 1;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (more > 0)
            Positioned(
              left: 4,
              top: 4,
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cl.colors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cl.colors.separator),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              right: more > 0 ? 4 : 0,
              bottom: more > 0 ? 4 : 0,
            ),
            child: LibraryTile(
              assetId: id,
              video: c.asset.video,
              durationMs: c.asset.durationMs,
              dimmed: done,
              selected: done ? null : _selected.contains(id),
              onTap: done ? null : () => _openViewer(all, all.indexOf(c)),
              badge: done
                  ? AutoSaveTag(l10n.autoSaveAlready)
                  : cloud
                  ? AutoSaveTag(l10n.autoSaveInCloud, warm: true)
                  : more > 0
                  ? ClPressable(
                      semanticLabel: l10n.autoSaveGroupTitle(
                        group!.items.length,
                        group.items
                            .where((x) => _selected.contains(x.asset.id))
                            .length,
                      ),
                      onPressed: () => setState(
                        () => _expanded.contains(id)
                            ? _expanded.remove(id)
                            : _expanded.add(id),
                      ),
                      child: AutoSaveTag('+$more', dark: true),
                    )
                  : null,
            ),
          ),
          if (!done)
            Positioned(
              top: 0,
              right: 0,
              width: 40,
              height: 40,
              child: ClPressable(
                semanticLabel: _selected.contains(id)
                    ? l10n.autoSaveSelected
                    : l10n.autoSaveSelect,
                selected: _selected.contains(id),
                onPressed: () => _toggle(id),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      );
    }

    final children = <Widget>[
      if (week != null) ...[
        Text(
          l10n.autoSaveWeekHint(name),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final w in weekChips) ...[
                ClFilterChip(
                  label: switch (byWeek[w]) {
                    null => l10n.autoSaveWeekDone(w),
                    final n when w == 0 => l10n.autoSaveWeekBefore(n),
                    final n => l10n.autoSaveWeek(w, n),
                  },
                  selected: w == week,
                  onTap: byWeek[w] == null
                      ? () {}
                      : () => setState(() => _week = w),
                ),
                const SizedBox(width: ClSpace.s2),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
      Text(
        l10n.autoSaveGroupedHint,
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s3),
      Wrap(
        spacing: ClSpace.s2,
        children: [
          ClFilterChip(
            label: l10n.autoSaveFilterAll(groups.length),
            selected: _filter == _Filter.all,
            onTap: () => setState(() => _filter = _Filter.all),
          ),
          ClFilterChip(
            label: l10n.autoSaveFilterPhotos(photos),
            selected: _filter == _Filter.photos,
            onTap: () => setState(() => _filter = _Filter.photos),
          ),
          ClFilterChip(
            label: l10n.autoSaveFilterVideos(groups.length - photos),
            selected: _filter == _Filter.videos,
            onTap: () => setState(() => _filter = _Filter.videos),
          ),
        ],
      ),
      const SizedBox(height: ClSpace.s4),
      if (all.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s6),
          child: Text(
            l10n.autoSaveReviewEmpty,
            textAlign: TextAlign.center,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      for (final e in days.entries) ...[
        Row(
          children: [
            Expanded(child: Text(dayLabel(e.key), style: cl.text.bodyStrong)),
            Text(
              l10n.autoSaveDayCount(
                e.value.where((g) => g.items.any(_keep)).length,
              ),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (final g in e.value)
              if (_keep(g.best)) tile(g.best, group: g),
          ],
        ),
        // An opened group (G-102): every near-copy, the best first.
        for (final g in e.value)
          if (_expanded.contains(g.best.asset.id) && g.items.length > 1)
            Container(
              margin: const EdgeInsets.only(top: ClSpace.s2),
              padding: const EdgeInsets.all(ClSpace.s2),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.card - 8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.autoSaveGroupTitle(
                            g.items.length,
                            g.items
                                .where((x) => _selected.contains(x.asset.id))
                                .length,
                          ),
                          style: cl.text.label,
                        ),
                      ),
                      ClButton(
                        label: l10n.autoSaveGroupAll,
                        style: ClButtonStyle.plain,
                        onPressed: () => setState(
                          () => _add([for (final x in g.items) x.asset.id]),
                        ),
                      ),
                      ClButton(
                        label: l10n.autoSaveGroupCollapse,
                        style: ClButtonStyle.plain,
                        onPressed: () =>
                            setState(() => _expanded.remove(g.best.asset.id)),
                      ),
                    ],
                  ),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    children: [
                      for (final (i, x) in g.items.indexed)
                        LibraryTile(
                          assetId: x.asset.id,
                          video: x.asset.video,
                          radius: 6,
                          selected: _selected.contains(x.asset.id),
                          onTap: () => _toggle(x.asset.id),
                          badge: i == 0
                              ? AutoSaveTag(l10n.autoSaveBest, warm: true)
                              : null,
                        ),
                    ],
                  ),
                ],
              ),
            ),
        const SizedBox(height: ClSpace.s4),
      ],
      if (all.isNotEmpty)
        Text(
          l10n.autoSaveLegend,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
    ];

    // "Bỏ chọn tất cả" to pick a few by hand; once nothing is ticked, "Chọn tất cả" ticks the
    // suggested picks again. Both follow the Ảnh / Video filter.
    final scope = {
      for (final c in all)
        if (_keep(c) && !already.contains(c.asset.id)) c.asset.id,
    };
    final anyPicked = scope.any(_selected.contains);
    final selectLabel = anyPicked
        ? l10n.autoSaveDeselectAll
        : l10n.autoSaveSelectAll;

    return AutoSavePage(
      title: l10n.autoSaveReviewTitle(name),
      trailing: scope.isEmpty
          ? null
          : ClPressable(
              key: const Key('autoSaveSelectAll'),
              semanticLabel: selectLabel,
              onPressed: () => setState(
                () => anyPicked
                    ? _selected.removeAll(scope)
                    : _add([
                        for (final g in groups)
                          for (final id in g.preselected)
                            if (scope.contains(id)) id,
                      ]),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                child: Center(
                  child: Text(
                    selectLabel,
                    style: cl.text.label.copyWith(color: cl.colors.mintText),
                  ),
                ),
              ),
            ),
      subtitle: last == null
          ? null
          : l10n.autoSaveReviewSub(total, checkedAt(context, last, now)),
      bottom: all.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.autoSaveChosen(
                          chosen.length,
                          chosen.length - chosenVideos,
                          chosenVideos,
                        ),
                        style: cl.text.bodyStrong,
                      ),
                    ),
                    Text(
                      '~ ${formatBytes(bytes, locale)}',
                      style: cl.text.body,
                    ),
                  ],
                ),
                if (merged > 0)
                  Text(
                    l10n.autoSaveMerged(merged),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                if (total > all.length)
                  Text(
                    l10n.autoSaveRoundRest(total - all.length, _cap),
                    key: const Key('autoSaveRoundRest'),
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                const SizedBox(height: ClSpace.s2),
                ClButton(
                  label: l10n.autoSaveContinue(chosen.length),
                  expand: true,
                  onPressed: chosen.isEmpty || chosen.length > _cap
                      ? null
                      : () {
                          if (week != null && onlyBaby != null) {
                            ref
                                .read(reviewedWeeksProvider.notifier)
                                .add(onlyBaby, week);
                          }
                          // Only this week's items are decided; other weeks stay pending.
                          context.push(
                            Routes.autoSaveConfirm,
                            extra: AutoSaveDecision(
                              chosen: chosen,
                              reviewed: [for (final c in all) c],
                            ),
                          );
                        },
                ),
              ],
            ),
      children: children,
    );
  }

  Future<void> _openViewer(List<Candidate> items, int start) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _Viewer(
          items: items,
          start: start,
          selected: _selected,
          onToggle: _toggle,
        ),
      ),
    );
    if (mounted) setState(() {});
  }
}

// ---------- AS08 Xem lớn gợi ý / AS09 Ảnh này của ai? ----------

final _bigThumbProvider = FutureProvider.autoDispose.family<Uint8List?, String>((
  ref,
  id,
) async {
  try {
    final a = await AssetEntity.fromId(id);
    // The finished picture, not iOS's quick blurry first pass (owner, 2026-10-14).
    return a?.thumbnailDataWithOption(
      defaultTargetPlatform == TargetPlatform.iOS
          ? ThumbnailOption.ios(
              size: const ThumbnailSize(1200, 1200),
              quality: 90,
              deliveryMode: DeliveryMode.highQualityFormat,
              resizeMode: ResizeMode.exact,
            )
          : const ThumbnailOption(size: ThumbnailSize(1200, 1200), quality: 90),
    );
  } on Object {
    return null;
  }
});

class _Viewer extends ConsumerStatefulWidget {
  const _Viewer({
    required this.items,
    required this.start,
    required this.selected,
    required this.onToggle,
  });

  final List<Candidate> items;
  final int start;
  final Set<String> selected;
  final void Function(String id) onToggle;

  @override
  ConsumerState<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends ConsumerState<_Viewer> {
  late final _page = PageController(initialPage: widget.start);
  late var _items = [...widget.items];
  late var _index = widget.start;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Candidate get _current => _items[_index.clamp(0, _items.length - 1)];

  Future<void> _reject(Candidate c) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final controller = ref.read(autoSaveProvider.notifier);
    final undo = await controller.reject(c);
    toaster.show(
      message: l10n.autoSaveRejected,
      actionLabel: l10n.autoSaveUndo,
      onAction: () => unawaited(controller.undo(undo)),
    );
    if (!mounted) return;
    setState(() {
      _items = [
        for (final x in _items)
          if (x.asset.id != c.asset.id) x,
      ];
      if (_index >= _items.length) _index = _items.length - 1;
    });
    if (_items.isEmpty) Navigator.of(context).pop();
  }

  Future<void> _whose(Candidate c) async {
    final l10n = AppLocalizations.of(context);
    final babies = ref.read(autoSaveProvider).state.babies.keys.toList();
    String? choice = c.match.babyId;
    final result = await showClSheet<String>(
      context: context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, set) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(
              title: l10n.autoSaveWhose,
              onClose: () => Navigator.of(sheet).pop(),
            ),
            for (final id in babies)
              ClOptionRow(
                title: ref.read(babyProvider(id)).value?.nickname ?? '',
                subtitle: id == c.match.babyId
                    ? l10n.autoSaveSuggestedNow
                    : null,
                selected: choice == id,
                onTap: () => set(() => choice = id),
              ),
            ClOptionRow(
              title: l10n.autoSaveNotBaby,
              subtitle: l10n.autoSaveNotBabyHint,
              selected: choice == null,
              onTap: () => set(() => choice = null),
            ),
            const SizedBox(height: ClSpace.s3),
            ClButton(
              label: l10n.autoSaveDone,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(choice ?? ''),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (result.isEmpty) return _reject(c);
    if (result == c.match.babyId) return;
    await ref.read(autoSaveProvider.notifier).reassign(c.asset.id, result);
    if (!mounted) return;
    setState(() {
      _items = [
        for (final x in _items)
          x.asset.id == c.asset.id
              ? Candidate(
                  asset: x.asset,
                  match: FaceMatch(
                    babyId: result,
                    distance: x.match.distance,
                    face: x.match.face,
                  ),
                )
              : x,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (_items.isEmpty) return const SizedBox.shrink();
    final c = _current;
    final on = widget.selected.contains(c.asset.id);
    final when = checkedAt(context, c.asset.captureAt, DateTime.now());
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const ClIcon(
                      ClIcons.close,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.autoSaveViewerPos(_index + 1, _items.length, when),
                      textAlign: TextAlign.center,
                      style: cl.text.label.copyWith(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(ClSpace.s2),
                    child: AutoSaveCheck(selected: on),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final img = ref
                      .watch(_bigThumbProvider(_items[i].asset.id))
                      .value;
                  final poster = img == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Image.memory(img, fit: BoxFit.contain);
                  // A video plays here (owner, 2026-10-15: "xem trước video ko play dc").
                  if (_items[i].asset.video) {
                    return LibraryVideo(
                      assetId: _items[i].asset.id,
                      active: i == _index,
                      poster: poster,
                    );
                  }
                  return img == null
                      ? poster
                      : InteractiveViewer(child: poster);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s3,
                ClSpace.s4,
                ClSpace.s4,
              ),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ClRadius.sheet),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClPressable(
                    semanticLabel: '${l10n.autoSaveFor} ${l10n.autoSaveChange}',
                    onPressed: () => unawaited(_whose(c)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
                      child: Row(
                        children: [
                          Text(
                            l10n.autoSaveFor,
                            style: cl.text.label.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                          const SizedBox(width: ClSpace.s2),
                          Expanded(
                            child: Text(
                              ref
                                      .watch(babyProvider(c.match.babyId))
                                      .value
                                      ?.nickname ??
                                  '',
                              style: cl.text.bodyStrong,
                            ),
                          ),
                          Text(
                            l10n.autoSaveChange,
                            style: cl.text.label.copyWith(
                              color: cl.colors.mintText,
                            ),
                          ),
                          ClIcon(
                            ClIcons.chevronDown,
                            size: 16,
                            color: cl.colors.mintText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Row(
                    children: [
                      Expanded(
                        child: ClButton(
                          label: l10n.autoSaveNotBaby,
                          style: ClButtonStyle.secondary,
                          onPressed: () => unawaited(_reject(c)),
                        ),
                      ),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: ClButton(
                          label: on
                              ? l10n.autoSaveSelected
                              : l10n.autoSaveSelect,
                          icon: on ? ClIcons.check : null,
                          onPressed: () =>
                              setState(() => widget.onToggle(c.asset.id)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- AS10 Kiểm tra trước khi tải / AS18 Không đủ dung lượng ----------

class AutoSaveConfirmScreen extends ConsumerStatefulWidget {
  const AutoSaveConfirmScreen({required this.decision, super.key});
  final AutoSaveDecision decision;

  @override
  ConsumerState<AutoSaveConfirmScreen> createState() =>
      _AutoSaveConfirmScreenState();
}

class _AutoSaveConfirmScreenState extends ConsumerState<AutoSaveConfirmScreen> {
  var _audience = Audience.parents;
  var _notify = false;
  (int, int)? _progress;

  Future<void> _upload(List<Candidate> items) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final chosenIds = {for (final c in widget.decision.chosen) c.asset.id};
    final sending = {for (final c in items) c.asset.id};
    // Ticked items that do not fit stay pending (AS18); unticked ones are done with.
    final reviewed = [
      for (final c in widget.decision.reviewed)
        if (sending.contains(c.asset.id) || !chosenIds.contains(c.asset.id)) c,
    ];
    setState(() => _progress = (0, items.length));
    final n = await ref
        .read(autoSaveProvider.notifier)
        .approve(
          chosen: items,
          reviewed: reviewed,
          audience: _audience,
          notifyFamily: _notify,
          onPrepared: (done, total) {
            if (mounted) setState(() => _progress = (done, total));
          },
        );
    toaster.show(message: l10n.autoSaveQueued(n));
    if (!mounted) return;
    // Another week still waits (P-171): straight back to the review, not the home.
    final decided = {for (final c in widget.decision.reviewed) c.asset.id};
    final more = ref
        .read(autoSaveProvider)
        .state
        .pending
        .any((c) => !decided.contains(c.asset.id));
    context.go(more ? Routes.autoSaveReview : Routes.autoSave);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final chosen = widget.decision.chosen;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final videos = chosen.where((c) => c.asset.video).length;
    final babies = {for (final c in chosen) c.match.babyId}.toList();
    final names = joinNames(l10n, [
      for (final id in babies)
        ref.watch(babyProvider(id)).value?.nickname ?? '',
    ]);
    final storage = babies.isEmpty
        ? null
        : ref.watch(familyStorageProvider(babies.first)).value;
    final need = chosen.fold<int>(0, (n, c) => n + c.asset.estimatedBytes);
    // Photos before videos, best-ranked first, until the space runs out (AS18).
    final ordered = [
      ...chosen.where((c) => !c.asset.video),
      ...chosen.where((c) => c.asset.video),
    ];
    final left = storage == null
        ? null
        : storage.quotaBytes - storage.usedBytes;
    final fit = <Candidate>[];
    if (left != null) {
      var used = 0;
      for (final c in ordered) {
        if (used + c.asset.estimatedBytes > left) break;
        used += c.asset.estimatedBytes;
        fit.add(c);
      }
    }
    final short = left != null && need > left;
    final busy = _progress != null;

    Widget audience(Audience a, ClIcons icon, String title, String hint) =>
        Expanded(
          child: ClPressable(
            selected: _audience == a,
            semanticLabel: '$title, $hint',
            onPressed: () => setState(() {
              _audience = a;
              if (a == Audience.parents) _notify = false;
            }),
            child: Container(
              // Each card fills its half and both match the taller one.
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(ClRadius.card - 8),
                border: Border.all(
                  color: _audience == a
                      ? cl.colors.mintDeep
                      : cl.colors.separator,
                  width: _audience == a ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClIcon(icon, size: 18, color: cl.colors.mintText),
                  const SizedBox(height: ClSpace.s1),
                  Text(title, style: cl.text.bodyStrong),
                  Text(
                    hint,
                    style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        );

    return AutoSavePage(
      title: l10n.autoSaveConfirmTitle,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClButton(
            label: busy
                ? l10n.autoSavePreparing(_progress!.$1, _progress!.$2)
                : short
                ? l10n.autoSaveUploadFit(fit.length)
                : l10n.autoSaveUploadCount(chosen.length),
            expand: true,
            loading: busy,
            onPressed: busy || (short && fit.isEmpty)
                ? null
                : () => unawaited(_upload(short ? fit : chosen)),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            short ? l10n.autoSaveNoRoomFootnote : l10n.autoSaveConfirmFootnote,
            textAlign: TextAlign.center,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ],
      ),
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final c in chosen.take(6))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox.square(
                    dimension: 48,
                    child: LibraryTile(
                      assetId: c.asset.id,
                      video: c.asset.video,
                      radius: 6,
                    ),
                  ),
                ),
              if (chosen.length > 6)
                Text('+${chosen.length - 6}', style: cl.text.bodyStrong),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            MeRow(
              title: l10n.autoSaveSource,
              subtitle: l10n.autoSaveSourceValue(
                chosen.length,
                chosen.length - videos,
                videos,
              ),
            ),
            MeRow(title: l10n.autoSaveBabyRow, value: names),
            MeRow(
              title: l10n.autoSaveSaveTo,
              subtitle: l10n.autoSaveSaveToValue,
            ),
          ],
        ),
        MeSection(l10n.autoSaveWho),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              audience(
                Audience.parents,
                ClIcons.lock,
                l10n.autoSaveParentsOnly,
                l10n.autoSaveParentsOnlyHint,
              ),
              const SizedBox(width: ClSpace.s2),
              audience(
                Audience.family,
                ClIcons.family,
                l10n.autoSaveFamily,
                l10n.autoSaveFamilyHint,
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            ClSettingRow(
              icon: ClIcons.bell,
              title: l10n.autoSaveNotify,
              subtitle: _notify
                  ? l10n.autoSaveNotifyOn
                  : l10n.autoSaveNotifyOff,
              value: _notify,
              onChanged: (on) => setState(() {
                _notify = on;
                if (on) _audience = Audience.family;
              }),
            ),
          ],
        ),
        if (short) ...[
          const SizedBox(height: ClSpace.s3),
          MeNotice(
            tone: MeTone.error,
            icon: ClIcons.alert,
            title: l10n.autoSaveNoRoom(
              chosen.length,
              formatBytes(need, locale),
              formatBytes(left < 0 ? 0 : left, locale),
              fit.length,
            ),
            onTap: () => context.push(Routes.meStorage),
          ),
        ],
        if (storage != null) ...[
          MeSection(l10n.autoSaveStorageAfter),
          AutoSaveCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatBytes(storage.usedBytes + (short ? fit.fold<int>(0, (n, c) => n + c.asset.estimatedBytes) : need), locale)} / ${formatBytes(storage.quotaBytes, locale)}',
                  style: cl.text.bodyStrong.copyWith(
                    color: short ? cl.colors.error : cl.colors.ink,
                  ),
                ),
                const SizedBox(height: ClSpace.s2),
                StorageBar(
                  segments: [storage.usedBytes + (short ? 0 : need)],
                  quota: storage.quotaBytes,
                  full: short,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
