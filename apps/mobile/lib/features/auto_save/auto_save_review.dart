import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/route_guard.dart';
import '../analytics/product_analytics.dart';
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
final alreadySavedProvider = Provider.autoDispose<Set<String>>((ref) {
  final view = ref.watch(autoSaveProvider);
  final out = <String>{};
  final byBaby = <String, Set<int>>{};
  for (final c in view.state.pending) {
    final seconds = byBaby[c.match.babyId] ??= {
      for (final m
          in ref.watch(completeMediaProvider((c.match.babyId, true))).value ??
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

/// The week pill's "Tất cả các tuần" (not a week of age, which starts at 0).
const _allWeeks = -1;

// ---------- AS07 Gợi ý chờ duyệt ----------

class AutoSaveReviewScreen extends ConsumerStatefulWidget {
  const AutoSaveReviewScreen({super.key});

  @override
  ConsumerState<AutoSaveReviewScreen> createState() =>
      _AutoSaveReviewScreenState();
}

class _AutoSaveReviewScreenState extends ConsumerState<AutoSaveReviewScreen> {
  final _measuredBabies = <String>{};
  final _selected = <String>{};
  final _known = <String>{};
  var _filter = _Filter.all;

  /// "Đã có trong Kỷ niệm" is folded until opened (D-123).
  var _savedOpen = false;

  /// The week of age being reviewed (P-171), when the person chose one; otherwise the newest
  /// week that still has suggestions (owner, 2026-10-23: newest week first).
  int? _week;

  /// Items one "Tải lên" may hold (D-070), from `publicConfig/limits`.
  var _cap = 200;

  /// What this review can tick: its items. "Đã có" ones too: it is a guess (same capture second
  /// as a memory) and can be wrong (owner, 2026-10-26), so they start unticked but can be picked.
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
    final already = ref.watch(alreadySavedProvider);
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
    if (view.loaded && onlyBaby != null && _measuredBabies.add(onlyBaby)) {
      final reporter = ref.read(productAnalyticsReporterProvider);
      final locale = Localizations.localeOf(context).languageCode == 'en'
          ? 'en'
          : 'vi';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            reporter?.observe(
              'photo_review_opened',
              babyId: onlyBaby,
              platform: productAnalyticsPlatform,
              locale: locale,
            ),
          );
        }
      });
    }
    // AS07, D-123 rework (owner, 2026-10-26: "làm đi làm lại vẫn ko đúng và khó hiểu. hãy phân
    // tích lại ui/ux"): one unit everywhere. Every photo or video is a tile and every count is
    // a count of files, so the chips, the ticks and "Tiếp tục với n mục" always agree. Near-copies
    // are laid out together under "n ảnh giống nhau" (the clearest pre-ticked); the items the app
    // thinks are already in Kỷ niệm wait, folded, at the end (a guess, so they can be ticked).
    // No sheet: the ticks on the tiles are the state.
    final byWeek = <int, int>{};
    if (dob != null) {
      // What waits and is not yet in Kỷ niệm ("Đã có" has its own section).
      for (final g in everything) {
        final n = g.items.where((c) => !already.contains(c.asset.id)).length;
        byWeek.update(
          ageWeekOf(dob, g.captureAt),
          (x) => x + n,
          ifAbsent: () => n,
        );
      }
    }
    // Newest week of age first; "Trước sinh" (week 0) last (owner, 2026-10-23).
    final pendingWeeks = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));
    // "Tất cả các tuần" (owner, 2026-10-26): every week in one review, still one upload of at
    // most [_cap]; a week stays the default (P-171).
    final week = dob == null || pendingWeeks.isEmpty
        ? null
        : _week == _allWeeks && pendingWeeks.length > 1
        ? _allWeeks
        : byWeek.containsKey(_week)
        ? _week!
        : pendingWeeks.first;
    final scoped = week == null || week == _allWeeks
        ? everything
        : [
            for (final g in everything)
              if (ageWeekOf(dob!, g.captureAt) == week) g,
          ];
    final doneWeeks = onlyBaby == null
        ? const <int>{}
        : ref.watch(reviewedWeeksProvider)[onlyBaby] ?? const <int>{};
    final weekChips = {...pendingWeeks, ...doneWeeks}.toList()
      ..sort((a, b) => b.compareTo(a));
    final groups = _round(scoped, already);
    _live = {
      for (final g in groups)
        for (final c in g.items) c.asset.id,
    };
    _learn(groups, already);
    final all = [for (final g in groups) ...g.items];
    // The counts on screen are of what is not yet in Kỷ niệm (owner, 2026-10-26: "bạn lại bắt
    // user tính toán nữa"); "Đã có" is counted in its own section and adds on top when ticked.
    final waiting = [
      for (final c in all)
        if (!already.contains(c.asset.id)) c,
    ];
    final photos = waiting.where((c) => !c.asset.video).length;
    final babies = {for (final c in all) c.match.babyId};
    final name = joinNames(l10n, [
      for (final id in babies)
        ref.watch(babyProvider(id)).value?.nickname ?? '',
    ]);
    final chosen = [
      for (final c in all)
        if (_selected.contains(c.asset.id)) c,
    ];
    final chosenVideos = chosen.where((c) => c.asset.video).length;
    final bytes = chosen.fold<int>(0, (n, c) => n + c.asset.estimatedBytes);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now();
    bool isNew(Candidate c) => _keep(c) && !already.contains(c.asset.id);

    // Day sections, newest first, of what is new; "Đã có" waits at the end.
    final days = <DateTime, List<SuggestionGroup>>{};
    for (final g in groups) {
      if (!g.items.any(isNew)) continue;
      final d = g.captureAt;
      (days[DateTime(d.year, d.month, d.day)] ??= []).add(g);
    }
    final saved = [
      for (final c in all)
        if (_keep(c) && already.contains(c.asset.id)) c,
    ];
    String dayLabel(DateTime d) {
      final date = DateFormat('dd/MM', locale).format(d);
      final today = DateTime(now.year, now.month, now.day);
      if (d == today) return l10n.autoSaveDayToday(date);
      if (d == today.subtract(const Duration(days: 1))) {
        return l10n.autoSaveDayYesterday(date);
      }
      return date;
    }

    Widget tile(Candidate c, {bool best = false}) {
      final id = c.asset.id;
      final done = already.contains(id);
      final cloud = !(ref.watch(libraryLocalProvider(id)).value ?? true);
      return Stack(
        fit: StackFit.expand,
        children: [
          LibraryTile(
            assetId: id,
            video: c.asset.video,
            durationMs: c.asset.durationMs,
            dimmed: done && !_selected.contains(id),
            selected: _selected.contains(id),
            onTap: () => _openViewer(all, all.indexOf(c)),
            badge: cloud
                ? AutoSaveTag(l10n.autoSaveInCloud, warm: true)
                : best
                ? AutoSaveTag(l10n.autoSaveBest, warm: true)
                : null,
          ),
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

    Widget grid(List<Widget> tiles) => GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: tiles,
    );

    // A group of near-copies: all of them, the clearest first and tagged, in one tinted block
    // whose header says how many are ticked and ticks the rest (or keeps only the clearest).
    Widget copies(SuggestionGroup g, List<Candidate> items) {
      final ticked = items.where((c) => _selected.contains(c.asset.id)).length;
      final allOn = ticked == items.length;
      return Container(
        key: Key('autoSaveGroup:${g.best.asset.id}'),
        margin: const EdgeInsets.only(top: ClSpace.s2),
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s2,
          ClSpace.s1,
          ClSpace.s2,
          ClSpace.s2,
        ),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.control + 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.autoSaveGroupTitle(items.length, ticked),
                    style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                // A text link, so the header keeps one line.
                ClPressable(
                  key: Key('autoSaveGroupToggle:${g.best.asset.id}'),
                  semanticLabel: allOn
                      ? l10n.autoSaveGroupBestOnly
                      : l10n.autoSaveGroupAll,
                  onPressed: () => setState(() {
                    if (allOn) {
                      _selected.removeAll([
                        for (final c in items)
                          if (c != g.best) c.asset.id,
                      ]);
                    } else {
                      _add([for (final c in items) c.asset.id]);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClSpace.s1,
                      vertical: ClSpace.s2,
                    ),
                    child: Text(
                      allOn
                          ? l10n.autoSaveGroupBestOnly
                          : l10n.autoSaveGroupAll,
                      style: cl.text.label.copyWith(
                        color: cl.colors.mintText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            grid([for (final c in items) tile(c, best: c == g.best)]),
          ],
        ),
      );
    }

    String weekLabel(int w) => w == _allWeeks
        ? l10n.autoSaveAllWeeks(byWeek.values.fold<int>(0, (n, c) => n + c))
        : switch (byWeek[w]) {
            null => l10n.autoSaveWeekDone(w),
            final n when w == 0 => l10n.autoSaveWeekBefore(n),
            final n => l10n.autoSaveWeek(w, n),
          };
    String kindLabel(_Filter f) => switch (f) {
      _Filter.all => l10n.autoSaveFilterAll(waiting.length),
      _Filter.photos => l10n.autoSaveFilterPhotos(photos),
      _Filter.videos => l10n.autoSaveFilterVideos(waiting.length - photos),
    };
    Future<void> choose<T>(
      String title,
      List<T> options,
      T current,
      String Function(T) label,
      bool Function(T) enabled,
      void Function(T) pick,
    ) async {
      final picked = await showClSheet<T>(
        context: context,
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: title),
            Flexible(
              child: SingleChildScrollView(
                child: ClCardGroup(
                  color: sheet.cl.colors.surface2,
                  children: [
                    for (final o in options)
                      ClOptionRow(
                        title: label(o),
                        selected: o == current,
                        onTap: enabled(o)
                            ? () => Navigator.of(sheet).pop(o)
                            : () {},
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      if (picked != null && mounted) setState(() => pick(picked));
    }

    // Each week in words and a bar: how much of it is already in Kỷ niệm, how much waits
    // (owner, 2026-10-26: "nên hiển thị mỗi tuần có bao nhiêu hình trong kỷ niệm rồi bao nhiêu
    // hình chưa … toàn số vậy cũng khó hiểu").
    Future<void> chooseWeek() async {
      final savedByWeek = <int, int>{};
      if (onlyBaby != null && dob != null) {
        for (final m
            in ref.read(completeMediaProvider((onlyBaby, true))).value ??
                const <MediaItem>[]) {
          if (m.deleted) continue;
          final w = ageWeekOf(dob, m.captureAt);
          savedByWeek[w] = (savedByWeek[w] ?? 0) + 1;
        }
      }
      final picked = await showClSheet<int>(
        context: context,
        builder: (sheet) {
          final l = AppLocalizations.of(sheet);
          final c = sheet.cl;
          String title(int w) {
            if (w == 0) return l.autoSaveWeekRowBefore;
            final r = ageWeekRange(dob!, w);
            final end = DateFormat('d/M', locale).format(r.last);
            final start = r.first.month == r.last.month
                ? '${r.first.day}'
                : DateFormat('d/M', locale).format(r.first);
            return l.autoSaveWeekRowTitle(w, '$start–$end');
          }

          Widget bar(int saved, int waiting) => ClipRRect(
            borderRadius: BorderRadius.circular(ClRadius.pill),
            child: SizedBox(
              height: 6,
              child: Row(
                // Stretched, or the empty coloured boxes collapse to no height.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (saved > 0)
                    Expanded(
                      flex: saved,
                      child: ColoredBox(color: c.colors.mint),
                    ),
                  if (waiting > 0)
                    Expanded(
                      flex: waiting,
                      child: ColoredBox(color: c.colors.sunshine),
                    ),
                ],
              ),
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l.autoSaveWeekSheet),
              Flexible(
                child: SingleChildScrollView(
                  child: ClCardGroup(
                    color: c.colors.surface2,
                    children: [
                      if (pendingWeeks.length > 1)
                        ClOptionRow(
                          key: const Key('autoSaveWeek:all'),
                          title: l.autoSaveAllWeeksRow,
                          subtitle: l.autoSaveWeekRowProgress(
                            savedByWeek.values.fold<int>(0, (n, c) => n + c),
                            byWeek.values.fold<int>(0, (n, c) => n + c),
                          ),
                          detail: bar(
                            savedByWeek.values.fold<int>(0, (n, c) => n + c),
                            byWeek.values.fold<int>(0, (n, c) => n + c),
                          ),
                          selected: week == _allWeeks,
                          onTap: () => Navigator.of(sheet).pop(_allWeeks),
                        ),
                      for (final w in weekChips)
                        ClOptionRow(
                          key: Key('autoSaveWeek:$w'),
                          title: title(w),
                          subtitle: switch ((byWeek[w], savedByWeek[w] ?? 0)) {
                            (null, final s) => l.autoSaveWeekRowDone(s),
                            (final n?, 0) => l.autoSaveWeekRowWaiting(n),
                            (final n?, final s) => l.autoSaveWeekRowProgress(
                              s,
                              n,
                            ),
                          },
                          detail: bar(savedByWeek[w] ?? 0, byWeek[w] ?? 0),
                          selected: w == week,
                          // A sent week has nothing left to choose.
                          onTap: byWeek[w] == null
                              ? () {}
                              : () => Navigator.of(sheet).pop(w),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
      if (picked != null && mounted) setState(() => _week = picked);
    }

    Future<void> chooseKind() => choose<_Filter>(
      l10n.autoSaveKindSheet,
      _Filter.values,
      _filter,
      kindLabel,
      (_) => true,
      (f) => _filter = f,
    );

    final children = <Widget>[
      // One row of pills, as on Kỷ niệm Ảnh (owner, 2026-10-26: "hai cái tabbar đi liền nhau
      // … chiếm nhiều diện tích"): the week and the kind each open their own choice.
      if (week != null || all.isNotEmpty) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              if (week != null) ...[
                ClFilterPill(
                  key: const Key('autoSaveWeekPill'),
                  icon: ClIcons.cake,
                  label: weekLabel(week),
                  onTap: pendingWeeks.length < 2 && weekChips.length < 2
                      ? null
                      : chooseWeek,
                ),
                const SizedBox(width: 6),
              ],
              if (all.isNotEmpty)
                ClFilterPill(
                  key: const Key('autoSaveFilter'),
                  icon: ClIcons.camera,
                  label: kindLabel(_filter),
                  onTap: chooseKind,
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
      // Often reached from a reminder sent on the phone's last report (owner, 2026-10-25:
      // "chỉ cần show message cho thân thiện"): say the photos are handled, offer Kỷ niệm.
      if (all.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s6),
          child: Column(
            children: [
              ClIcon(ClIcons.check, size: 32, color: cl.colors.mintText),
              const SizedBox(height: ClSpace.s3),
              Text(
                l10n.autoSaveReviewDoneTitle,
                textAlign: TextAlign.center,
                style: cl.text.bodyStrong,
              ),
              const SizedBox(height: ClSpace.s1),
              Text(
                l10n.autoSaveReviewDoneBody,
                textAlign: TextAlign.center,
                style: cl.text.body.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(height: ClSpace.s4),
              ClButton(
                label: l10n.autoSaveReviewOpenMemories,
                style: ClButtonStyle.secondary,
                onPressed: () => context.go(Routes.memories),
              ),
            ],
          ),
        ),
      for (final e in days.entries) ...[
        Text(dayLabel(e.key), style: cl.text.bodyStrong),
        const SizedBox(height: ClSpace.s2),
        // Single items as a grid, then each group of near-copies in its own block.
        grid([
          for (final g in e.value)
            for (final c in g.items.where(isNew))
              if (g.items.where(isNew).length == 1) tile(c),
        ]),
        for (final g in e.value)
          if (g.items.where(isNew).length > 1)
            copies(
              g,
              [
                g.best,
                for (final c in g.items)
                  if (c != g.best) c,
              ].where(isNew).toList(),
            ),
        const SizedBox(height: ClSpace.s4),
      ],
      if (saved.isNotEmpty) ...[
        ClPressable(
          key: const Key('autoSaveSavedSection'),
          semanticLabel: l10n.autoSaveSavedSection(saved.length),
          onPressed: () => setState(() => _savedOpen = !_savedOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.autoSaveSavedSection(saved.length),
                        style: cl.text.bodyStrong,
                      ),
                      Text(
                        l10n.autoSaveSavedHint,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ClIcon(
                  _savedOpen ? ClIcons.chevronDown : ClIcons.chevronRight,
                  size: 18,
                  color: cl.colors.inkMuted,
                ),
              ],
            ),
          ),
        ),
        if (_savedOpen) ...[
          const SizedBox(height: ClSpace.s2),
          grid([for (final c in saved) tile(c)]),
        ],
        const SizedBox(height: ClSpace.s4),
      ],
      if (all.isNotEmpty)
        Text(
          l10n.autoSaveLegend,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
    ];

    // "Bỏ chọn tất cả" to pick a few by hand; once nothing is ticked, "Chọn tất cả" ticks every
    // new item (not "Đã có"). Both follow the Ảnh / Video filter.
    final inView = [
      for (final c in all)
        if (_keep(c)) c.asset.id,
    ];
    final anyPicked = inView.any(_selected.contains);
    final selectLabel = anyPicked
        ? l10n.autoSaveDeselectAll
        : l10n.autoSaveSelectAll;

    return AutoSavePage(
      title: l10n.autoSaveReviewTitle(name),
      trailing: inView.isEmpty
          ? null
          : ClPressable(
              key: const Key('autoSaveSelectAll'),
              semanticLabel: selectLabel,
              onPressed: () => setState(
                () => anyPicked
                    ? _selected.removeAll(inView)
                    : _add([
                        for (final c in all)
                          if (isNew(c)) c.asset.id,
                      ]),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                child: Text(
                  selectLabel,
                  style: cl.text.label.copyWith(color: cl.colors.mintText),
                ),
              ),
            ),
      // What to do, once: the clearest are ticked. The total and the check time live on Tự lưu.
      subtitle: all.isEmpty ? null : l10n.autoSaveReviewTicked,
      bottom: all.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // What goes up, as icons and numbers ("Đã chọn n" is the button's).
                MergeSemantics(
                  child: Semantics(
                    label: l10n.autoSaveChosen(
                      chosen.length,
                      chosen.length - chosenVideos,
                      chosenVideos,
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        key: const Key('autoSaveChosenStats'),
                        children: [
                          for (final (icon, n) in [
                            (ClIcons.camera, chosen.length - chosenVideos),
                            (ClIcons.video, chosenVideos),
                          ]) ...[
                            ClIcon(icon, size: 16, color: cl.colors.inkMuted),
                            const SizedBox(width: ClSpace.s1),
                            Text('$n', style: cl.text.bodyStrong),
                            const SizedBox(width: ClSpace.s4),
                          ],
                          const Spacer(),
                          Text(
                            '~ ${formatBytes(bytes, locale)}',
                            style: cl.text.label.copyWith(
                              color: cl.colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Only what this upload leaves out of the chosen week (the per-upload limit);
                // other weeks wait in their own chips. Counted in files, like everything here.
                if (scoped.fold<int>(0, (n, g) => n + g.items.length) >
                    all.length)
                  Text(
                    l10n.autoSaveRoundRest(
                      scoped.fold<int>(0, (n, g) => n + g.items.length) -
                          all.length,
                      _cap,
                    ),
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
                            final sent = {for (final c in all) c.asset.id};
                            for (final w
                                in week == _allWeeks
                                    ? [
                                        // Weeks this upload covers in full.
                                        for (final w in pendingWeeks)
                                          if (everything
                                              .where(
                                                (g) =>
                                                    ageWeekOf(
                                                      dob!,
                                                      g.captureAt,
                                                    ) ==
                                                    w,
                                              )
                                              .every(
                                                (g) => g.items.every(
                                                  (c) =>
                                                      sent.contains(c.asset.id),
                                                ),
                                              ))
                                            w,
                                      ]
                                    : [week]) {
                              ref
                                  .read(reviewedWeeksProvider.notifier)
                                  .add(onlyBaby, w);
                            }
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

  /// Each file while it is made ready for upload (owner, 2026-10-26: "đang chuẩn bị 104 file thì
  /// người dùng muốn được xem mỗi file đó chuẩn bị gì và đang như thế nào"); null = waiting.
  /// Null before "Tải lên".
  Map<String, ApprovePrep?>? _prep;
  var _sending = const <Candidate>[];
  var _prepFinished = false;

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
    setState(() {
      _sending = [...items]
        ..sort((a, b) => a.asset.captureAt.compareTo(b.asset.captureAt));
      _prep = {for (final c in items) c.asset.id: null};
      _prepFinished = false;
    });
    final n = await ref
        .read(autoSaveProvider.notifier)
        .approve(
          chosen: items,
          reviewed: reviewed,
          audience: _audience,
          notifyFamily: _notify,
          onItem: (id, state) {
            if (mounted) setState(() => _prep?[id] = state);
          },
        );
    if (!mounted) return;
    // Whatever never reached the queue could not be prepared.
    setState(() {
      _prep = {
        for (final e in _prep!.entries)
          e.key: e.value == ApprovePrep.queued
              ? ApprovePrep.queued
              : ApprovePrep.failed,
      };
      _prepFinished = true;
    });
    toaster.show(message: l10n.autoSaveQueued(n));
    // With files that could not be read, stay so the person sees which; otherwise go on.
    if (!_prep!.values.contains(ApprovePrep.failed)) _leave();
  }

  void _leave() {
    // Another week still waits (P-171): straight back to the review, not the home.
    final decided = {for (final c in widget.decision.reviewed) c.asset.id};
    final more = ref
        .read(autoSaveProvider)
        .state
        .pending
        .any((c) => !decided.contains(c.asset.id));
    context.go(more ? Routes.autoSaveReview : Routes.autoSave);
  }

  Widget _preparing(AppLocalizations l10n, ClTheme cl, String locale) {
    final prep = _prep!;
    final done = prep.values
        .where((v) => v != null && v != ApprovePrep.working)
        .length;
    final queued = prep.values.where((v) => v == ApprovePrep.queued).length;
    final failed = prep.values.where((v) => v == ApprovePrep.failed).length;
    return AutoSavePage(
      title: l10n.autoSavePrepTitle(done, prep.length),
      bottom: !_prepFinished
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (failed > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: ClSpace.s2),
                    child: Text(
                      l10n.autoSavePrepSummary(queued, failed),
                      key: const Key('autoSavePrepSummary'),
                      textAlign: TextAlign.center,
                      style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                    ),
                  ),
                ClButton(
                  key: const Key('autoSavePrepDone'),
                  label: l10n.autoSavePrepDone,
                  expand: true,
                  onPressed: _leave,
                ),
              ],
            ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ClRadius.pill),
          child: LinearProgressIndicator(
            value: prep.isEmpty ? 0 : done / prep.length,
            minHeight: 6,
            color: cl.colors.mintDeep,
            backgroundColor: cl.colors.surface2,
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            for (final c in _sending)
              Padding(
                key: Key('autoSavePrep:${c.asset.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s3,
                  vertical: ClSpace.s2,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 40,
                      child: LibraryTile(
                        assetId: c.asset.id,
                        video: c.asset.video,
                        radius: 6,
                      ),
                    ),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'dd/MM · HH:mm',
                          locale,
                        ).format(c.asset.captureAt),
                        style: cl.text.label,
                      ),
                    ),
                    const SizedBox(width: ClSpace.s2),
                    Text(
                      switch (prep[c.asset.id]) {
                        null => l10n.autoSavePrepWaiting,
                        ApprovePrep.working => l10n.autoSavePrepWorking,
                        ApprovePrep.queued => l10n.autoSavePrepQueued,
                        ApprovePrep.failed => l10n.autoSavePrepFailed,
                      },
                      style: cl.text.caption.copyWith(
                        color: switch (prep[c.asset.id]) {
                          ApprovePrep.failed => cl.colors.error,
                          ApprovePrep.queued => cl.colors.mintText,
                          _ => cl.colors.inkMuted,
                        },
                        fontWeight: prep[c.asset.id] == ApprovePrep.working
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final chosen = widget.decision.chosen;
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_prep != null) return _preparing(l10n, cl, locale);
    final videos = chosen.where((c) => c.asset.video).length;
    final babies = {for (final c in chosen) c.match.babyId}.toList();
    final names = joinNames(l10n, [
      for (final id in babies)
        ref.watch(babyProvider(id)).value?.nickname ?? '',
    ]);
    final storageAsync = babies.isEmpty
        ? null
        : ref.watch(familyStorageProvider(babies.first));
    final storage = storageAsync?.value;
    // Owner, 2026-10-26: "hết bộ nhớ lại cho chuẩn bị file": nothing is prepared or uploaded
    // before the family's space is known (a read that failed still lets the server decide).
    final checking = storage == null && (storageAsync?.isLoading ?? false);
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
    // Nothing fits: no upload at all, the way out is more space (Premium v2 or Dung lượng).
    final full = short && fit.isEmpty;
    final way = babies.isEmpty
        ? StorageWayOut.manage
        : storageWayOut(ref, babies.first);

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
          if (full)
            ClButton(
              key: const Key('autoSaveAddSpace'),
              label: storageWayOutLabel(ref, l10n, babies.first, way),
              expand: true,
              onPressed: () => openStorageWayOut(
                context,
                ref,
                babies.first,
                way,
                autoSave: true,
              ),
            )
          else
            ClButton(
              key: const Key('autoSaveUpload'),
              label: checking
                  ? l10n.autoSaveCheckingSpace
                  : short
                  ? l10n.autoSaveUploadFit(fit.length)
                  : l10n.autoSaveUploadCount(chosen.length),
              expand: true,
              onPressed: checking
                  ? null
                  : () => unawaited(_upload(short ? fit : chosen)),
            ),
          if (short && !full)
            ClButton(
              key: const Key('autoSaveAddSpace'),
              label: storageWayOutLabel(ref, l10n, babies.first, way),
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: () => openStorageWayOut(
                context,
                ref,
                babies.first,
                way,
                autoSave: true,
              ),
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
                      durationMs: c.asset.durationMs,
                      radius: 6,
                    ),
                  ),
                ),
              if (chosen.length > 6)
                Text('+${chosen.length - 6}', style: cl.text.bodyStrong),
            ],
          ),
        ),
        if (short) ...[
          const SizedBox(height: ClSpace.s3),
          // First, right under the files: what is short and by how much (owner, 2026-10-26: it sat
          // under the form, half hidden). The buttons below are the way out.
          MeNotice(
            key: const Key('autoSaveNoRoom'),
            tone: MeTone.error,
            icon: ClIcons.alert,
            title: full
                ? l10n.autoSaveFullTitle
                : l10n.autoSaveShortTitle(fit.length, chosen.length),
            body: [
              full
                  ? l10n.autoSaveFullBody(
                      chosen.length,
                      formatBytes(need, locale),
                    )
                  : l10n.autoSaveShortBody(
                      formatBytes(need, locale),
                      formatBytes(left < 0 ? 0 : left, locale),
                    ),
              // D-125: Premium is named before the button that opens it.
              if (way == StorageWayOut.premium) l10n.autoSavePremiumSpaceNote,
            ].join(' '),
          ),
        ],
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
