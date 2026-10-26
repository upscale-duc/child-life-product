import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/family_labels.dart';
import '../home/home_shell.dart';
import '../me/me_models.dart' show formatBytes;
import '../me/me_repository.dart';
import '../memories/media_bytes.dart';
import '../memories/media_picker.dart';
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart';
import '../memories/memory_widgets.dart';
import 'auto_save_controller.dart';
import 'auto_save_native.dart';
import 'auto_save_store.dart';
import 'auto_save_widgets.dart';

/// At least this many samples per baby (AS04 "3–5 ảnh").
const autoSaveMinSamples = 3;
const autoSaveMaxSamples = 5;

/// The first check looks back 30 days, or to the birth of the youngest baby when every chosen
/// baby is younger than that (P-150).
DateTime autoSaveScanFrom(
  WidgetRef ref,
  Iterable<String> babyIds,
  DateTime now,
) {
  var from = now.subtract(const Duration(days: 30));
  DateTime? earliest;
  for (final id in babyIds) {
    final dob = ref.read(babyPrivateProfileProvider(id)).value?.dateOfBirth;
    if (dob != null && (earliest == null || dob.isBefore(earliest))) {
      earliest = dob;
    }
  }
  if (earliest != null && earliest.isAfter(from)) from = earliest;
  return from;
}

// ---------- AS02 Giới thiệu ----------

class AutoSaveIntro extends ConsumerWidget {
  const AutoSaveIntro({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final babyId = ref.watch(selectedBabyIdProvider);
    final storage = babyId == null
        ? null
        : ref.watch(familyStorageProvider(babyId)).value;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // D-120: a hint only where it says something the step doesn't.
    Widget step(int n, String title, [String? hint]) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cl.colors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: cl.text.bodyStrong.copyWith(color: cl.colors.mintText),
            ),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.bodyStrong),
                if (hint != null)
                  Text(
                    hint,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return AutoSavePage(
      title: l10n.autoSaveTitle,
      beta: true,
      subtitle: l10n.autoSaveIntroLead,
      bottom: ClButton(
        label: l10n.autoSaveStart,
        expand: true,
        onPressed: () {
          unawaited(
            ref.read(autoSaveProvider.notifier).track('autoSaveSetupStarted'),
          );
          context.push(Routes.autoSaveSetup);
        },
      ),
      children: [
        AutoSaveCard(
          child: Column(
            children: [
              step(1, l10n.autoSaveStep1),
              step(2, l10n.autoSaveStep2, l10n.autoSaveStep2Hint),
              step(3, l10n.autoSaveStep3, l10n.autoSaveStep3Hint),
            ],
          ),
        ),
        Text(
          storage == null
              ? l10n.autoSaveIntroFootnoteNoUsage
              : l10n.autoSaveIntroFootnote(
                  '${formatBytes(storage.usedBytes, locale)} / ${formatBytes(storage.quotaBytes, locale)}',
                ),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

// ---------- AS03 – AS05 ----------

/// What AS03 – AS05 collect; saved only when the parent agrees in AS05.
class _SetupDraft {
  final chosen = <String>[];
  final samples = <String, List<SampleFace>>{};
}

String _name(WidgetRef ref, String babyId) =>
    ref.read(babyProvider(babyId)).value?.nickname ?? '';

/// Each step is a page of its own, pushed on the navigator: the platform's slide and swipe-back
/// (D-013), like every other screen.
Route<void> _stepRoute(Widget page) =>
    MaterialPageRoute<void>(builder: (_) => page);

/// AS03 "Gợi ý ảnh của bé nào?" (route `/memories/auto-save/setup`).
class AutoSaveSetupScreen extends ConsumerStatefulWidget {
  const AutoSaveSetupScreen({super.key});

  @override
  ConsumerState<AutoSaveSetupScreen> createState() =>
      _AutoSaveSetupScreenState();
}

class _AutoSaveSetupScreenState extends ConsumerState<AutoSaveSetupScreen> {
  final _draft = _SetupDraft();

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedBabyIdProvider);
    final session = ref.read(sessionProvider);
    if (session is SessionSignedIn &&
        selected != null &&
        session.membershipFor(selected)?.role == MemberRole.coParent) {
      _draft.chosen.add(selected);
    }
  }

  void _next() => unawaited(
    Navigator.of(
      context,
    ).push(_stepRoute(_SamplesStep(draft: _draft, index: 0))),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final members = session is SessionSignedIn
        ? session.active
        : const <Membership>[];
    final now = DateTime.now();
    return AutoSavePage(
      title: l10n.autoSavePickBabyTitle,
      subtitle: l10n.autoSavePickBabySub,
      bottom: ClButton(
        label: l10n.autoSaveNext,
        expand: true,
        onPressed: _draft.chosen.isEmpty ? null : _next,
      ),
      children: [
        for (final m in members)
          Builder(
            builder: (context) {
              final baby = ref.watch(babyProvider(m.babyId)).value;
              final name = baby?.nickname ?? '';
              final parent = m.role == MemberRole.coParent;
              final on = _draft.chosen.contains(m.babyId);
              final dob = m.canViewBabyInfo
                  ? ref
                        .watch(babyPrivateProfileProvider(m.babyId))
                        .value
                        ?.dateOfBirth
                  : null;
              final detail = [
                if (dob != null) ageShort(l10n, dob, now),
                l10n.autoSaveYouAre(memberRelation(l10n, m)),
              ].join(' · ');
              final row = Container(
                margin: const EdgeInsets.only(bottom: ClSpace.s2),
                padding: const EdgeInsets.all(ClSpace.s3),
                decoration: BoxDecoration(
                  color: parent ? cl.colors.surface : cl.colors.surface2,
                  borderRadius: BorderRadius.circular(ClRadius.card - 6),
                  border: Border.all(
                    color: on ? cl.colors.mintDeep : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cl.colors.mintSoft,
                      child: Text(
                        initialOf(name),
                        style: cl.text.bodyStrong.copyWith(
                          color: cl.colors.mintText,
                        ),
                      ),
                    ),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(
                      child: parent
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: cl.text.bodyStrong),
                                Text(
                                  detail,
                                  style: cl.text.label.copyWith(
                                    color: cl.colors.inkMuted,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '$name · ${m.role == MemberRole.caregiver ? l10n.autoSaveLockedCaregiver : l10n.autoSaveLockedRelative}',
                              style: cl.text.label.copyWith(
                                color: cl.colors.inkMuted,
                              ),
                            ),
                    ),
                    if (parent)
                      _SquareCheck(on: on)
                    else
                      ClIcon(ClIcons.lock, size: 18, color: cl.colors.inkMuted),
                  ],
                ),
              );
              return parent
                  ? ClPressable(
                      semanticLabel: '$name, $detail',
                      selected: on,
                      onPressed: () => setState(
                        () => on
                            ? _draft.chosen.remove(m.babyId)
                            : _draft.chosen.add(m.babyId),
                      ),
                      child: row,
                    )
                  : MergeSemantics(child: row);
            },
          ),
      ],
    );
  }
}

/// AS04 "Chọn vài ảnh rõ mặt {bé}", once per chosen baby.
class _SamplesStep extends ConsumerStatefulWidget {
  const _SamplesStep({required this.draft, required this.index});
  final _SetupDraft draft;
  final int index;

  @override
  ConsumerState<_SamplesStep> createState() => _SamplesStepState();
}

class _SamplesStepState extends ConsumerState<_SamplesStep> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = widget.draft;
    final babyId = draft.chosen[widget.index];
    final picked = draft.samples[babyId] ?? const [];
    return AutoSavePage(
      title: l10n.autoSaveSamplesTitle(_name(ref, babyId)),
      subtitle: l10n.autoSaveSamplesSub,
      bottom: ClButton(
        label: l10n.autoSaveSamplesNext(picked.length),
        expand: true,
        onPressed: () {
          if (picked.length < autoSaveMinSamples) {
            ClToaster.of(context).show(message: l10n.autoSaveSamplesNeed);
            return;
          }
          final last = widget.index + 1 >= draft.chosen.length;
          unawaited(
            Navigator.of(context).push(
              _stepRoute(
                last
                    ? _ConsentStep(draft: draft)
                    : _SamplesStep(draft: draft, index: widget.index + 1),
              ),
            ),
          );
        },
      ),
      children: [
        SamplePicker(
          babyId: babyId,
          name: _name(ref, babyId),
          picked: picked,
          onChanged: (next) => setState(() => draft.samples[babyId] = next),
        ),
      ],
    );
  }
}

/// AS05 "Trước khi bắt đầu" with the face-analysis consent (P-147).
class _ConsentStep extends ConsumerStatefulWidget {
  const _ConsentStep({required this.draft});
  final _SetupDraft draft;

  @override
  ConsumerState<_ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends ConsumerState<_ConsentStep> {
  var _agree = false;
  var _agreeError = false;
  var _busy = false;

  Future<void> _finish() async {
    if (!_agree) {
      setState(() => _agreeError = true);
      return;
    }
    setState(() => _busy = true);
    final chosen = widget.draft.chosen;
    final c = ref.read(autoSaveProvider.notifier);
    final access = await c.requestAccess();
    // P-148 funnel: finished with the consent, and which photo access was given.
    unawaited(c.track('autoSaveSetupDone'));
    unawaited(
      c.track(switch (access) {
        LibraryAccess.full => 'autoSaveAccessFull',
        LibraryAccess.limited => 'autoSaveAccessLimited',
        _ => 'autoSaveAccessDenied',
      }),
    );
    await c.setUp(
      samples: {
        for (final id in chosen) id: widget.draft.samples[id] ?? const [],
      },
      scanFrom: autoSaveScanFrom(ref, chosen, DateTime.now()),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    // Back to the home, which now shows the first check (AS06): this page, one per baby's
    // samples, and AS03.
    var pages = chosen.length + 2;
    Navigator.of(context).popUntil((_) => pages-- == 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final names = joinNames(l10n, [
      for (final id in widget.draft.chosen) _name(ref, id),
    ]);
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ClIcon(ClIcons.check, size: 16, color: cl.colors.mintText),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(child: Text(text, style: cl.text.label)),
        ],
      ),
    );
    Widget card(
      ClIcons icon,
      String title,
      String body, {
      Widget? extra,
      bool accent = false,
    }) => AutoSaveCard(
      border: accent ? cl.colors.mintDeep : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClIcon(icon, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Expanded(child: Text(title, style: cl.text.bodyStrong)),
            ],
          ),
          const SizedBox(height: ClSpace.s1),
          Text(body, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          ?extra,
        ],
      ),
    );
    return AutoSavePage(
      title: l10n.autoSaveConsentTitle,
      subtitle: l10n.autoSaveConsentSub,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_agreeError) ...[
            Text(
              l10n.autoSaveAgreeFirst,
              style: cl.text.label.copyWith(color: cl.colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ClSpace.s2),
          ],
          ClButton(
            label: l10n.autoSaveAllow,
            expand: true,
            loading: _busy,
            onPressed: _busy ? null : _finish,
          ),
          const SizedBox(height: ClSpace.s1),
          ClButton(
            label: l10n.autoSaveLater,
            style: ClButtonStyle.plain,
            onPressed: () => context.go(Routes.memories),
          ),
        ],
      ),
      children: [
        // P-147: the face-analysis consent leads, in plain words, with its own tick.
        card(
          ClIcons.phone,
          l10n.autoSaveFaceTitle(names),
          l10n.autoSaveFaceBody(names),
          accent: true,
          extra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              point(l10n.autoSaveFaceNoPhotos(names)),
              point(l10n.autoSaveFaceNumbers),
              point(l10n.autoSaveFaceNoOne),
              const SizedBox(height: ClSpace.s3),
              ClPressable(
                selected: _agree,
                semanticLabel: l10n.autoSaveFaceAgree(names),
                onPressed: () => setState(() {
                  _agree = !_agree;
                  _agreeError = false;
                }),
                child: Container(
                  padding: const EdgeInsets.all(ClSpace.s3),
                  decoration: BoxDecoration(
                    color: cl.colors.cloud,
                    borderRadius: BorderRadius.circular(ClRadius.control),
                    border: _agreeError
                        ? Border.all(color: cl.colors.error)
                        : null,
                  ),
                  child: Row(
                    children: [
                      _SquareCheck(on: _agree),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Text(
                          l10n.autoSaveFaceAgree(names),
                          style: cl.text.label,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ClSpace.s2),
              ClButton(
                label: l10n.autoSaveWhatKept,
                style: ClButtonStyle.plain,
                onPressed: () => showWhatKeptSheet(context),
              ),
            ],
          ),
        ),
        card(
          ClIcons.memories,
          l10n.autoSaveLibraryTitle,
          l10n.autoSaveLibraryBody(names),
          extra: Padding(
            padding: const EdgeInsets.only(top: ClSpace.s2),
            child: Text(
              l10n.autoSaveLibraryHint,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ),
        card(ClIcons.upload, l10n.autoSaveUploadTitle, l10n.autoSaveUploadBody),
      ],
    );
  }
}

class _SquareCheck extends StatelessWidget {
  const _SquareCheck({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: on ? cl.colors.mintDeep : cl.colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: on ? cl.colors.mintDeep : cl.colors.controlBorder,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: on
          ? ClIcon(ClIcons.check, size: 14, color: cl.colors.onMintDeep)
          : null,
    );
  }
}

/// "Child Life lưu gì?" (P-147): what stays on the phone, what is never kept, what is uploaded.
Future<void> showWhatKeptSheet(BuildContext context) => showClSheet<void>(
  context: context,
  builder: (sheet) {
    final l10n = AppLocalizations.of(sheet);
    final cl = sheet.cl;
    Widget block(ClIcons icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(icon, size: 20, color: cl.colors.mintText),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.autoSaveWhatKept),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                block(
                  ClIcons.phone,
                  l10n.autoSaveKeptHere,
                  l10n.autoSaveKeptHereBody,
                ),
                block(
                  ClIcons.close,
                  l10n.autoSaveKeptNever,
                  l10n.autoSaveKeptNeverBody,
                ),
                block(
                  ClIcons.upload,
                  l10n.autoSaveKeptUp,
                  l10n.autoSaveKeptUpBody,
                ),
                Text(
                  l10n.autoSaveKeptFooter,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

// ---------- AS04 Ảnh mẫu ----------

/// 3–5 sample photos of one baby, from Kỷ niệm or the library. Each pick is checked for a clear
/// face on the phone; only its numbers are kept (P-147).
class SamplePicker extends ConsumerStatefulWidget {
  const SamplePicker({
    required this.babyId,
    required this.name,
    required this.picked,
    required this.onChanged,
    super.key,
  });

  final String babyId;
  final String name;
  final List<SampleFace> picked;
  final ValueChanged<List<SampleFace>> onChanged;

  @override
  ConsumerState<SamplePicker> createState() => _SamplePickerState();
}

class _SamplePickerState extends ConsumerState<SamplePicker> {
  final _checking = <String>{};

  bool _has(String ref) => widget.picked.any((s) => s.ref == ref);

  void _remove(String ref) => widget.onChanged([
    for (final s in widget.picked)
      if (s.ref != ref) s,
  ]);

  Future<void> _add(Future<SampleFace?> Function() make, String ref) async {
    if (widget.picked.length >= autoSaveMaxSamples || _checking.contains(ref)) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _checking.add(ref));
    final sample = await make();
    if (!mounted) return;
    setState(() => _checking.remove(ref));
    if (sample == null) {
      toaster.show(message: l10n.autoSaveSampleNoFace);
      return;
    }
    widget.onChanged([...widget.picked, sample]);
  }

  Future<void> _fromMemories(MediaItem item) async {
    final ref0 = 'm:${item.id}';
    if (_has(ref0)) return _remove(ref0);
    final path = item.paths?.display ?? item.paths?.original ?? item.thumbPath;
    if (path == null) return;
    final c = ref.read(autoSaveProvider.notifier);
    await _add(() async {
      try {
        final file = await mediaBytes.file(path);
        return c.sampleFromFile(item.id, file.path);
      } on Object {
        return null;
      }
    }, ref0);
  }

  Future<void> _fromLibrary() async {
    final picked = await pickFromLibrary(context, ref);
    if (picked == null || !mounted) return;
    final c = ref.read(autoSaveProvider.notifier);
    for (final p in picked) {
      final id = p.assetId;
      if (id == null || _has('a:$id')) continue;
      await _add(() => c.sampleFromLibrary(id), 'a:$id');
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final media =
        ref.watch(completeMediaProvider((widget.babyId, true))).value ??
        const [];
    final photos = [
      for (final m in media)
        if (!m.isVideo && m.isReady && !m.deleted && m.thumbPath != null) m,
    ];
    final byRef = {for (final m in photos) 'm:${m.id}': m};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final s in widget.picked)
                Padding(
                  padding: const EdgeInsets.only(right: ClSpace.s2),
                  child: ClPressable(
                    onPressed: () => _remove(s.ref),
                    semanticLabel: l10n.autoSaveSamplesCount(
                      widget.picked.length,
                    ),
                    child: ClipOval(
                      child: SizedBox.square(
                        dimension: 56,
                        child: byRef[s.ref] != null
                            ? MediaTile(item: byRef[s.ref]!, radius: 28)
                            : s.ref.startsWith('a:')
                            ? LibraryTile(
                                assetId: s.ref.substring(2),
                                radius: 28,
                              )
                            : ColoredBox(color: cl.colors.surface2),
                      ),
                    ),
                  ),
                ),
              if (widget.picked.length < autoSaveMaxSamples)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cl.colors.controlBorder,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(
                    ClIcons.plus,
                    size: 20,
                    color: cl.colors.inkMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.autoSaveSamplesCount(widget.picked.length),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        if (photos.isEmpty)
          Text(
            l10n.autoSaveSamplesEmpty(widget.name),
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          )
        else
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: [
              for (final m in photos.take(60))
                Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaTile(
                      item: m,
                      selecting: true,
                      selected: _has('m:${m.id}'),
                      onTap: () => unawaited(_fromMemories(m)),
                    ),
                    if (_checking.contains('m:${m.id}'))
                      const Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: ClSpace.s3),
        Center(
          child: ClButton(
            label: l10n.autoSaveSamplesFromLibrary,
            style: ClButtonStyle.plain,
            loading: _checking.any((r) => r.startsWith('a:')),
            onPressed: widget.picked.length >= autoSaveMaxSamples
                ? null
                : _fromLibrary,
          ),
        ),
      ],
    );
  }
}

/// AS15 "Thêm ảnh mẫu" and AS19 › a baby: change one baby's samples, or take it out.
class AutoSaveSamplesScreen extends ConsumerStatefulWidget {
  const AutoSaveSamplesScreen({required this.babyId, super.key});
  final String babyId;

  @override
  ConsumerState<AutoSaveSamplesScreen> createState() =>
      _AutoSaveSamplesScreenState();
}

class _AutoSaveSamplesScreenState extends ConsumerState<AutoSaveSamplesScreen> {
  List<SampleFace>? _picked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(autoSaveProvider);
    final name = ref.watch(babyProvider(widget.babyId)).value?.nickname ?? '';
    final picked =
        _picked ?? view.state.babies[widget.babyId]?.picked ?? const [];
    return AutoSavePage(
      title: l10n.autoSaveSamplesOf(name),
      subtitle: l10n.autoSaveSamplesHint,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClButton(
            label: l10n.autoSaveSave,
            expand: true,
            onPressed: () async {
              if (picked.length < autoSaveMinSamples) {
                ClToaster.of(context).show(message: l10n.autoSaveSamplesNeed);
                return;
              }
              final c = ref.read(autoSaveProvider.notifier);
              await c.setSamples(
                widget.babyId,
                picked,
                autoSaveScanFrom(ref, [widget.babyId], DateTime.now()),
              );
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          ClButton(
            label: l10n.autoSaveRemoveBaby(name),
            style: ClButtonStyle.plain,
            onPressed: () async {
              await ref
                  .read(autoSaveProvider.notifier)
                  .removeBaby(widget.babyId);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      children: [
        SamplePicker(
          babyId: widget.babyId,
          name: name,
          picked: picked,
          onChanged: (next) => setState(() => _picked = next),
        ),
      ],
    );
  }
}
