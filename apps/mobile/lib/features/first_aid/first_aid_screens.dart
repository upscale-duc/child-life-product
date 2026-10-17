import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import 'first_aid_models.dart';
import 'first_aid_modes.dart';
import 'first_aid_repository.dart';
import 'first_aid_widgets.dart';

/// Sơ cứu (Figma v1.1 7b index, 7c search, saved, TH01–TH24 / 7d / 7e situation pages; D-058).
/// Everything renders from the pack kept on the device, so it works without a network.

// ---------- Chrome ----------

class _FaPage extends StatelessWidget {
  const _FaPage({required this.children, this.trailing, this.bottom});

  final List<Widget> children;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: SizedBox(
                height: ClSpace.tapMin,
                child: Row(
                  children: [
                    FaRoundButton(
                      icon: ClIcons.back,
                      label: l10n.a11yBack,
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
              ),
            ),
            Expanded(
              // Built in full (not lazily) so "Đọc to" can scroll to any step.
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s4,
                  ClSpace.s4,
                  (bottom == null ? media.padding.bottom : 0) + ClSpace.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

Widget _loading(BuildContext context) => Scaffold(
  backgroundColor: context.cl.colors.cloud,
  body: const SizedBox.shrink(),
);

// ---------- 7b Sơ cứu ----------

class FirstAidHomeScreen extends ConsumerStatefulWidget {
  const FirstAidHomeScreen({super.key});

  @override
  ConsumerState<FirstAidHomeScreen> createState() => _FirstAidHomeScreenState();
}

class _FirstAidHomeScreenState extends ConsumerState<FirstAidHomeScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    if (pack == null) return _loading(context);
    final baby = ref.watch(faBabyProvider(l10n));
    final ordered = pack.ordered(baby?.months);
    final cpr = pack.cprSituation;
    final categories = [
      for (final c in pack.categories)
        if (_category == null || _category == c.id) c,
    ];

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClPressable(
        onPressed: onTap,
        selected: selected,
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cl.colors.ink : cl.colors.surface,
            borderRadius: BorderRadius.circular(ClRadius.pill),
            border: selected ? null : Border.all(color: cl.colors.separator),
          ),
          child: Text(
            label,
            style: cl.text.label.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? cl.colors.surface : cl.colors.ink,
            ),
          ),
        ),
      ),
    );

    return _FaPage(
      trailing: FaRoundButton(
        key: const Key('faSavedList'),
        icon: ClIcons.bookmark,
        label: l10n.faSaved,
        onPressed: () => context.push(Routes.firstAidSaved),
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.faTitle,
            style: cl.text.largeTitle.copyWith(fontSize: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.faSubtitle,
          style: cl.text.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: cl.colors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        // Khẩn cấp: call, or start CPR.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cl.colors.dangerSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.faEmergencyQuestion,
                style: cl.text.bodyStrong.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cl.colors.danger,
                ),
              ),
              const SizedBox(height: 10),
              FaCallButton(
                number: pack.emergencyNumber,
                country: pack.localCountry,
                expand: true,
                onPressed: () => unawaited(callEmergency(context, ref)),
              ),
              if (cpr != null) ...[
                const SizedBox(height: 10),
                ClPressable(
                  key: const Key('faStartCpr'),
                  onPressed: () => context.push(
                    '${Routes.firstAidSituation}/${cpr.id}?v=${cpr.defaultVariant(baby?.months).id}',
                  ),
                  semanticLabel: l10n.faStartCpr,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cl.colors.surface,
                      borderRadius: BorderRadius.circular(ClRadius.pill),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      l10n.faStartCpr,
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cl.colors.danger,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClPressable(
          key: const Key('faSearch'),
          onPressed: () => context.push(Routes.firstAidSearch),
          semanticLabel: l10n.faSearchHint,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cl.colors.controlBorder),
            ),
            child: Row(
              children: [
                ClIcon(ClIcons.search, size: 18, color: cl.colors.inkMuted),
                const SizedBox(width: 10),
                Text(
                  l10n.faSearchHint,
                  style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              chip(
                l10n.faAll,
                _category == null,
                () => setState(() => _category = null),
              ),
              for (final c in pack.categories)
                chip(
                  c.title.of(context),
                  _category == c.id,
                  () => setState(() => _category = c.id),
                ),
            ],
          ),
        ),
        for (final c in categories) ...[
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              c.title.of(context),
              style: cl.text.headline.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (c.id == categories.first.id && baby?.ageLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.faSortedFor(baby!.name, baby.ageLabel!),
              style: cl.text.label.copyWith(
                fontSize: 13,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          _CategoryBody(
            category: c,
            situations: [
              for (final s in ordered)
                if (s.category == c.id) s,
            ],
          ),
        ],
      ],
    );
  }
}

class _CategoryBody extends StatelessWidget {
  const _CategoryBody({required this.category, required this.situations});
  final FaCategory category;
  final List<FaSituation> situations;

  @override
  Widget build(BuildContext context) {
    void open(FaSituation s) =>
        context.push('${Routes.firstAidSituation}/${s.id}');
    if (category.layout == FaLayout.grid) {
      return Column(
        children: [
          for (var i = 0; i < situations.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FaSituationCard(
                      situation: situations[i],
                      onTap: () => open(situations[i]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < situations.length
                        ? FaSituationCard(
                            situation: situations[i + 1],
                            onTap: () => open(situations[i + 1]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return FaGroup(
      children: [
        for (final s in situations)
          FaSituationRow(situation: s, onTap: () => open(s)),
      ],
    );
  }
}

// ---------- 7c Tìm kiếm ----------

class FirstAidSearchScreen extends ConsumerStatefulWidget {
  const FirstAidSearchScreen({super.key});

  @override
  ConsumerState<FirstAidSearchScreen> createState() =>
      _FirstAidSearchScreenState();
}

class _FirstAidSearchScreenState extends ConsumerState<FirstAidSearchScreen> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    if (pack == null) return _loading(context);
    final results = faSearch(pack, _query.text);
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('faQuery'),
                      controller: _query,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      style: cl.text.body.copyWith(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: l10n.faSearchHint,
                        filled: true,
                        fillColor: cl.colors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClIcon(
                            ClIcons.search,
                            size: 18,
                            color: cl.colors.inkMuted,
                          ),
                        ),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : ClPressable(
                                onPressed: _query.clear,
                                semanticLabel: l10n.a11yClose,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: ClIcon(
                                    ClIcons.close,
                                    size: 16,
                                    color: cl.colors.inkMuted,
                                  ),
                                ),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: cl.colors.mintDeep,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: cl.colors.controlBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: cl.colors.mintDeep,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClPressable(
                    onPressed: () => context.pop(),
                    semanticLabel: l10n.actionCancel,
                    child: Text(
                      l10n.actionCancel,
                      style: cl.text.label.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cl.colors.mintText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s4,
                  ClSpace.s4,
                  media.padding.bottom + ClSpace.s8,
                ),
                children: [
                  if (_query.text.trim().isNotEmpty) ...[
                    Text(
                      l10n.faResults(results.length),
                      style: cl.text.label.copyWith(
                        fontSize: 13,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: ClSpace.s2),
                    if (results.isEmpty)
                      Text(
                        l10n.faNoResults(pack.emergencyNumber),
                        style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                      )
                    else
                      FaGroup(
                        children: [
                          for (final r in results)
                            FaSituationRow(
                              situation: r.situation,
                              subline: r.snippet.of(context),
                              onTap: () => context.push(
                                '${Routes.firstAidSituation}/${r.situation.id}',
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    l10n.faQuickSearch,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in pack.quickSearch)
                        ClPressable(
                          onPressed: () {
                            final text = q.of(context);
                            _query.value = TextEditingValue(
                              text: text,
                              selection: TextSelection.collapsed(
                                offset: text.length,
                              ),
                            );
                          },
                          semanticLabel: q.of(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cl.colors.surface,
                              borderRadius: BorderRadius.circular(
                                ClRadius.pill,
                              ),
                              border: Border.all(color: cl.colors.separator),
                            ),
                            child: Text(
                              q.of(context),
                              style: cl.text.label.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

// ---------- Đã lưu ----------

class FirstAidSavedScreen extends ConsumerWidget {
  const FirstAidSavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    if (pack == null) return _loading(context);
    final saved = [
      for (final id in ref.watch(firstAidSavedProvider).value ?? const [])
        ?pack.situation(id),
    ];
    return _FaPage(
      children: [
        Text(l10n.faSaved, style: cl.text.largeTitle.copyWith(fontSize: 30)),
        const SizedBox(height: ClSpace.s4),
        if (saved.isEmpty)
          Text(
            l10n.faSavedEmpty,
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          )
        else
          FaGroup(
            children: [
              for (final s in saved)
                FaSituationRow(
                  situation: s,
                  onTap: () =>
                      context.push('${Routes.firstAidSituation}/${s.id}'),
                ),
            ],
          ),
      ],
    );
  }
}

// ---------- TH01–TH24, 7d / 7e: a situation ----------

class FirstAidSituationScreen extends ConsumerStatefulWidget {
  const FirstAidSituationScreen({
    required this.situationId,
    this.variantId,
    super.key,
  });
  final String situationId;
  final String? variantId;

  @override
  ConsumerState<FirstAidSituationScreen> createState() =>
      _FirstAidSituationScreenState();
}

class _FirstAidSituationScreenState
    extends ConsumerState<FirstAidSituationScreen> {
  String? _variant;

  /// The part being read aloud: -1 the page head, 0… the steps, null when not reading.
  int? _reading;
  var _readRun = 0;
  final _stepKeys = <GlobalKey>[];
  late final FirstAidDevice _device;

  @override
  void initState() {
    super.initState();
    // Read now: dispose() must not touch ref.
    _device = ref.read(firstAidDeviceProvider);
  }

  @override
  void dispose() {
    _readRun++;
    unawaited(_device.stopSpeaking());
    super.dispose();
  }

  /// "Đọc to hướng dẫn": reads the head, every step (scrolling to it) and the callouts. The
  /// sentences are built first so nothing reads the context after a pause.
  Future<void> _readAloud(FaSituation s, FaVariant v) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    String t(FaText x) => x.pick(locale);
    final head = [
      t(s.title),
      t(s.lead),
      if (v.banner != null) t(v.banner!),
    ].join('. ');
    final steps = [
      for (final (i, st) in v.steps.indexed)
        l10n.faSpeakStep(i + 1, t(st.title), t(st.body)),
    ];
    final callouts = [
      for (final c in v.callouts) [t(c.heading), ...c.items.map(t)].join('. '),
    ];
    final run = ++_readRun;
    bool stale() => !mounted || run != _readRun;
    setState(() => _reading = -1);
    await _device.keepAwake(true);
    await _device.speak(head, locale);
    for (final (i, line) in steps.indexed) {
      if (stale()) return;
      setState(() => _reading = i);
      final target = i < _stepKeys.length ? _stepKeys[i].currentContext : null;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: 0.15,
          duration: const Duration(milliseconds: 350),
        );
      }
      if (stale()) return;
      await _device.speak(line, locale);
    }
    for (final line in callouts) {
      if (stale()) return;
      await _device.speak(line, locale);
    }
    if (stale()) return;
    await _device.keepAwake(false);
    if (!stale()) setState(() => _reading = null);
  }

  void _stopReading() {
    _readRun++;
    unawaited(_device.stopSpeaking());
    unawaited(_device.keepAwake(false));
    setState(() => _reading = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final pack = ref.watch(firstAidPackProvider).value;
    if (pack == null) return _loading(context);
    final s = pack.situation(widget.situationId);
    if (s == null) {
      return _FaPage(children: [Text(l10n.faNotFound, style: cl.text.body)]);
    }
    final baby = ref.watch(faBabyProvider(l10n));
    final variant =
        s.variant(_variant ?? widget.variantId) ??
        s.defaultVariant(baby?.months);
    final category = pack.category(s.category)!;
    final saved = (ref.watch(firstAidSavedProvider).value ?? const []).contains(
      s.id,
    );
    final calling = ref.watch(firstAidCallStartedProvider) != null;
    final protocol = pack.protocol(variant.cpr);
    final (tagBg, tagInk) = faToneColors(context, category.tone);
    final title = s.title.of(context);
    while (_stepKeys.length < variant.steps.length) {
      _stepKeys.add(GlobalKey());
    }
    final reading = _reading != null;

    Future<void> toggleSaved() async {
      final toaster = ClToaster.of(context);
      await toggleFirstAidSaved(ref, s.id);
      toaster.show(message: saved ? l10n.faUnsavedToast : l10n.faSavedToast);
    }

    void toggleReading() =>
        reading ? _stopReading() : unawaited(_readAloud(s, variant));

    // Revision 2: emergencies get the big call button and a speaker; other pages read aloud.
    final bottom = _BottomBar(
      children: s.emergency
          ? [
              Expanded(child: FaCallBar(number: pack.emergencyNumber)),
              const SizedBox(width: 10),
              _SpeakerButton(reading: reading, onPressed: toggleReading),
            ]
          : [
              Expanded(
                child: _ReadAloudButton(
                  reading: reading,
                  onPressed: toggleReading,
                ),
              ),
            ],
    );

    return _FaPage(
      trailing: s.emergency
          ? (calling
                ? null
                : FaCallButton(
                    number: pack.emergencyNumber,
                    small: true,
                    onPressed: () => unawaited(callEmergency(context, ref)),
                  ))
          : FaRoundButton(
              key: const Key('faBookmark'),
              icon: saved ? ClIcons.bookmarkFill : ClIcons.bookmark,
              color: saved ? cl.colors.mintText : null,
              label: saved ? l10n.faUnsave : l10n.faSave,
              onPressed: () => unawaited(toggleSaved()),
            ),
      bottom: bottom,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            FaTag(category.title.of(context), background: tagBg, ink: tagInk),
            if (s.monitoring)
              FaTag(
                l10n.faMonitoring,
                background: cl.colors.surface2,
                ink: cl.colors.inkMuted,
              ),
            FaTag(
              l10n.faOffline,
              background: cl.colors.surface2,
              ink: cl.colors.inkMuted,
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        Semantics(
          header: true,
          child: Text(
            title,
            style: cl.text.largeTitle.copyWith(fontSize: 30, height: 1.2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.lead.of(context),
          style: cl.text.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: cl.colors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        FaImage(variant.hero ?? s.hero),
        // TH01: the beat plays by itself while the page is open (revision 2).
        if (protocol != null) ...[
          const SizedBox(height: ClSpace.s4),
          FaMetronomeCard(protocol: protocol, paused: reading),
        ],
        if (calling && s.emergency) ...[
          const SizedBox(height: ClSpace.s3),
          FaTellOperatorCard(situation: s),
        ],
        if (variant.banner != null) ...[
          const SizedBox(height: ClSpace.s4),
          _Banner(variant.banner!.of(context)),
        ],
        if (s.variants.length > 1) ...[
          const SizedBox(height: ClSpace.s4),
          _VariantSwitch(
            situation: s,
            selected: variant,
            onChanged: (v) {
              if (reading) _stopReading();
              setState(() => _variant = v.id);
            },
          ),
        ],
        if (variant.steps.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s4),
          Semantics(
            header: true,
            child: Text(
              l10n.faFollowSteps,
              style: cl.text.headline.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final (i, step) in variant.steps.indexed) ...[
            const SizedBox(height: ClSpace.s3),
            _StepCard(
              key: _stepKeys[i],
              index: i + 1,
              step: step,
              active: _reading == i,
            ),
          ],
        ],
        if (s.seizureTimer) ...[
          const SizedBox(height: ClSpace.s3),
          const _SeizureTimer(),
        ],
        for (final c in variant.callouts) ...[
          const SizedBox(height: ClSpace.s4),
          FaCalloutBox(callout: c),
        ],
        const SizedBox(height: ClSpace.s4),
        Text(
          _footer(context, pack, l10n),
          style: cl.text.caption.copyWith(
            color: cl.colors.inkMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Normal pages: "Đọc to hướng dẫn" (outlined, full width) / "Dừng đọc".
class _ReadAloudButton extends StatelessWidget {
  const _ReadAloudButton({required this.reading, required this.onPressed});
  final bool reading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final label = reading ? l10n.faStopReading : l10n.faReadAloud;
    return ClPressable(
      key: const Key('faReadAloud'),
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: reading ? cl.colors.mintSoft : cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(
            color: reading ? cl.colors.mintDeep : cl.colors.controlBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(
              reading ? ClIcons.stop : ClIcons.speaker,
              size: 22,
              color: reading ? cl.colors.mintText : cl.colors.ink,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: cl.text.bodyStrong.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: reading ? cl.colors.mintText : cl.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emergency pages: the small speaker next to "Gọi 115" (56 × 52, outlined).
class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.reading, required this.onPressed});
  final bool reading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      key: const Key('faReadAloud'),
      onPressed: onPressed,
      semanticLabel: reading ? l10n.faStopReading : l10n.faReadAloudShort,
      child: Container(
        width: 56,
        height: 52,
        decoration: BoxDecoration(
          color: reading ? cl.colors.mintSoft : cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(
            color: reading ? cl.colors.mintDeep : cl.colors.controlBorder,
          ),
        ),
        alignment: Alignment.center,
        child: ClIcon(
          reading ? ClIcons.stop : ClIcons.speaker,
          size: 22,
          color: reading ? cl.colors.mintText : cl.colors.ink,
        ),
      ),
    );
  }
}

/// The disclaimer; it names a review only once one is recorded (P-141).
String _footer(BuildContext context, FirstAidPack pack, AppLocalizations l10n) {
  final review = pack.review;
  if (review == null) return l10n.faDisclaimer;
  final month = DateFormat(
    'MM/yyyy',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(review.reviewedOn);
  return '${l10n.faDisclaimer} ${l10n.faReviewed(review.reviewer, month)}';
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        12,
        ClSpace.s4,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(children: children),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: ClIcon(ClIcons.alert, size: 16, color: cl.colors.ink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: cl.text.label.copyWith(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Dưới 1 tuổi | Từ 1 tuổi" / "Không có dị vật | Có dị vật" (the design's own segmented style).
class _VariantSwitch extends StatelessWidget {
  const _VariantSwitch({
    required this.situation,
    required this.selected,
    required this.onChanged,
  });
  final FaSituation situation;
  final FaVariant selected;
  final ValueChanged<FaVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cl.colors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final v in situation.variants)
            Expanded(
              child: ClPressable(
                onPressed: () => onChanged(v),
                selected: v.id == selected.id,
                semanticLabel: v.label?.of(context) ?? '',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: v.id == selected.id ? cl.colors.surface : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    v.label?.of(context) ?? '',
                    textAlign: TextAlign.center,
                    style: cl.text.label.copyWith(
                      fontSize: 14,
                      fontWeight: v.id == selected.id
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: v.id == selected.id
                          ? cl.colors.ink
                          : cl.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.step,
    this.active = false,
    super.key,
  });
  final int index;
  final FaStep step;

  /// Being read aloud: outlined so the eye finds it.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cl.shadows.card,
        border: active ? Border.all(color: cl.colors.mintDeep, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cl.colors.mintDeep,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: cl.text.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cl.colors.onMintDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title.of(context),
                      style: cl.text.bodyStrong.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.body.of(context),
                      style: cl.text.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Revision 2: counts are static labels ("× 5 lần"), nothing to tap.
          if (step.count != null || step.chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 42),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (step.count != null)
                    FaTag(
                      l10n.faCountTimes(step.count!),
                      background: cl.colors.mintSoft,
                      ink: cl.colors.mintText,
                    ),
                  for (final c in step.chips)
                    FaTag(
                      c.label.of(context),
                      background: c.mint
                          ? cl.colors.mintSoft
                          : cl.colors.surface2,
                      ink: c.mint ? cl.colors.mintText : cl.colors.inkMuted,
                    ),
                ],
              ),
            ),
          ],
          if (step.image != null) ...[
            const SizedBox(height: 12),
            FaImage(step.image!),
          ],
        ],
      ),
    );
  }
}

/// "Không được làm" (negative), "Đưa bé đi viện ngay khi" (warning), "Vàng da sinh lý" (positive).
class FaCalloutBox extends StatelessWidget {
  const FaCalloutBox({required this.callout, super.key});
  final FaCallout callout;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final (bg, disc, onDisc, icon, heading, dot) = switch (callout.tone) {
      FaCalloutTone.negative => (
        cl.colors.dangerSoft,
        cl.colors.danger,
        cl.colors.onDanger,
        ClIcons.close,
        cl.colors.danger,
        cl.colors.danger,
      ),
      FaCalloutTone.warning => (
        cl.colors.sunshineSoft,
        cl.colors.sunshine,
        cl.colors.ink,
        ClIcons.alert,
        cl.colors.ink,
        cl.colors.ink,
      ),
      FaCalloutTone.positive => (
        cl.colors.mintSoft,
        cl.colors.mintDeep,
        cl.colors.onMintDeep,
        ClIcons.check,
        cl.colors.mintText,
        cl.colors.mintDeep,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
                child: ClIcon(icon, size: 14, color: onDisc),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  callout.heading.of(context),
                  style: cl.text.bodyStrong.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: heading,
                  ),
                ),
              ),
            ],
          ),
          for (final item in callout.items) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.of(context),
                    style: cl.text.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// TH04 "Bấm giờ cơn giật": on the page only, never logged (P-141).
class _SeizureTimer extends StatefulWidget {
  const _SeizureTimer();

  @override
  State<_SeizureTimer> createState() => _SeizureTimerState();
}

class _SeizureTimerState extends State<_SeizureTimer> {
  Duration _elapsed = Duration.zero;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_tick != null) {
      _tick!.cancel();
      setState(() => _tick = null);
    } else if (_elapsed > Duration.zero) {
      setState(() => _elapsed = Duration.zero);
    } else {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final label = _tick != null
        ? l10n.faTimerStop
        : _elapsed > Duration.zero
        ? l10n.faTimerReset
        : l10n.faTimerStart;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: cl.shadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cl.colors.sunshineSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClIcon(ClIcons.clock, size: 20, color: cl.colors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.faSeizureTimer,
                  style: cl.text.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$m:$s',
                  style: cl.text.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          ClButton(
            key: const Key('faTimer'),
            label: label,
            style: _tick != null
                ? ClButtonStyle.secondary
                : ClButtonStyle.primary,
            onPressed: _toggle,
          ),
        ],
      ),
    );
  }
}
