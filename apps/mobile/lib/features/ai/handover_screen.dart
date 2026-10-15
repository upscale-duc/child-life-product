import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
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
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart'
    show careClockProvider, inBabyZone, onlineProvider;
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../premium/billing_models.dart' show PaywallEntry;
import '../premium/paywall_screen.dart' show openPaywall;
import '../premium/premium_gate.dart' show showGateSheet;
import '../premium/premium_models.dart';
import '../premium/premium_repository.dart';
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_actions.dart';
import '../rhythm/rhythm_calc.dart' show isoOf;
import '../rhythm/rhythm_home.dart' show RhHealthCard;
import '../rhythm/rhythm_labels.dart';
import '../rhythm/rhythm_repository.dart';
import '../rhythm/rhythm_widgets.dart';
import 'ai_models.dart';
import 'ai_repository.dart';
import 'ai_widgets.dart';

/// SU01 (591:6564 / 591:6830) "Bàn giao cho người chăm tiếp" with the ST01 (594:6967) and NL10b
/// (574:1317) states. A Cùng nuôi makes it (`generateSummary`, kind handover; consent and quota
/// are the server's), a caregiver reads the latest stored one (D-072 #2). Three parts, each with
/// readable links to the notes behind it instead of "[F1]"; the AI label only on AI wording.
/// Every gate keeps the free template; only PREMIUM_REQUIRED links to the plan. A health sign
/// today shows the free health route and never AI text. Offline: the last stored version.
class HandoverScreen extends ConsumerStatefulWidget {
  const HandoverScreen({super.key});

  @override
  ConsumerState<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends ConsumerState<HandoverScreen> {
  var _requestId = newAiRequestId();
  SummaryAnswer? _answer;
  AiException? _error;
  var _busy = false;
  var _autoAsked = false;

  Future<void> _generate(Membership me, {bool fresh = false}) async {
    if (_busy) return;
    if (fresh) _requestId = newAiRequestId();
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final a = await ref
          .read(aiRepositoryProvider)
          .generate(
            babyId: me.babyId,
            kind: AiSummaryKind.handover,
            locale: locale,
            requestId: _requestId,
          );
      if (!mounted) return;
      setState(() => _answer = a);
      // Home's entry and the next open read the new one.
      ref.invalidate(handoversProvider(me.babyId));
    } on AiException catch (e) {
      if (mounted) setState(() => _error = e);
    } on Object {
      if (mounted) setState(() => _error = const AiException('unavailable'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _zone(Membership me) =>
      ref.read(babyProvider(me.babyId)).value?.timeZone.zone ??
      'Asia/Ho_Chi_Minh';

  /// To the consent screen; once given, a new attempt.
  Future<void> _toConsent(Membership me) async {
    await context.push(Routes.rhythmAiConsent);
    if (!mounted) return;
    final granted =
        ref.read(aiSettingsProvider(me.uid)).value?.granted ?? false;
    if (granted) unawaited(_generate(me, fresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final topBar = Align(
      alignment: Alignment.centerLeft,
      child: RhRoundIcon(
        icon: ClIcons.back,
        label: l10n.a11yBack,
        onPressed: () => leaveRhythm(context),
      ),
    );
    final title = Semantics(
      header: true,
      child: Text(l10n.aiHandoverTitle, style: cl.text.title2),
    );
    if (me == null) {
      return OnboardingScaffold(topBar: topBar, content: const []);
    }
    if (!familyCan(me, FamilyAction.historyRead)) {
      return OnboardingScaffold(
        topBar: topBar,
        content: [
          title,
          const SizedBox(height: ClSpace.s3),
          RhInfoBox(icon: ClIcons.lock, text: l10n.rhOwnNoAccess),
        ],
      );
    }
    final canGenerate = familyCan(me, FamilyAction.aiGenerate);
    final online = ref.watch(onlineProvider).value ?? true;
    final storedAsync = ref.watch(handoversProvider(me.babyId));
    final stored = latestHandover(
      storedAsync.value ?? const [],
      locale.languageCode,
    );
    final settings = canGenerate
        ? ref.watch(aiSettingsProvider(me.uid)).value
        : null;
    final dataVersion = ref.watch(dataVersionProvider(me.babyId)).value;
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final baby = ref.watch(babyProvider(me.babyId)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
    final today = babyTodayIso(zone, now);
    final healthToday = (ref.watch(checkInsProvider(me.babyId)).value ?? [])
        .where((c) => c.date == today && c.needsHealthSupport)
        .firstOrNull;

    // A Cùng nuôi opening it with nothing stored in this language asks once (idempotent; an
    // unchanged household answers from the cache, free).
    if (canGenerate &&
        online &&
        !_autoAsked &&
        !storedAsync.isLoading &&
        (stored == null || stored.language != locale.languageCode)) {
      _autoAsked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_generate(me));
      });
    }

    final shown = _answer ?? stored;
    final health = healthToday != null || (shown?.health ?? false);
    final content = <Widget>[title];

    if (shown == null) {
      content.add(const SizedBox(height: ClSpace.s4));
      if (health) {
        content.addAll([
          RhHealthCard(signs: healthToday?.healthSigns ?? const []),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      if (_busy || (canGenerate && online && _error == null)) {
        content.add(const _Loading());
      } else if (!online) {
        content.add(
          AiStateCard(
            icon: ClIcons.cloudOff,
            eyebrow: l10n.aiStateOfflineEyebrow,
            title: l10n.aiStateOfflineEmptyTitle,
            body: l10n.aiStateOfflineBody,
          ),
        );
      } else if (_error != null) {
        content.add(
          AiStateCard(
            icon: ClIcons.alert,
            warm: true,
            title: l10n.aiStateFailedTitle,
            body: l10n.aiStateFailedBody,
            action: (l10n.rhRetry, () => _generate(me, fresh: true)),
          ),
        );
      } else {
        content.add(
          AiStateCard(
            icon: ClIcons.journal,
            title: l10n.aiReadEmptyTitle,
            body: l10n.aiReadEmptyBody,
          ),
        );
      }
      return OnboardingScaffold(topBar: topBar, content: content);
    }

    // Subtitle: range · from n notes by Mẹ, Ba, Cô Lan · made at.
    String who(String uid) => memberLabel(
      l10n,
      members.where((m) => m.uid == uid).firstOrNull,
      myUid: me.uid,
      uid: uid,
      sentenceStart: false,
    );
    final from = shown.rangeFrom, to = shown.rangeTo;
    final range = from == null || to == null
        ? ''
        : from == to
        ? shortDay(locale, from)
        : l10n.rhDateRange(shortDay(locale, from), shortDay(locale, to));
    final count = shown.records.isEmpty
        ? shown.facts.length
        : shown.records.length;
    final names = [for (final u in shown.authorUids) who(u)];
    final subtitle = names.isEmpty
        ? l10n.aiHandoverFromCount(range, count)
        : l10n.aiHandoverFrom(range, count, joinNames(l10n, names));
    content.addAll([
      const SizedBox(height: ClSpace.s1),
      if (range.isNotEmpty)
        Text(
          capitalized(subtitle),
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
      if (shown.generatedAt case final at?)
        Text(
          l10n.aiGeneratedAt(
            '${shortDay(locale, isoOf(inBabyZone(zone, at)))} · '
            '${DateFormat('HH:mm').format(inBabyZone(zone, at))}',
          ),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      const SizedBox(height: ClSpace.s4),
    ]);

    // States above the summary.
    final states = <Widget>[];
    if (_busy) states.add(const _Loading());
    if (!online) {
      states.add(
        AiStateCard(
          icon: ClIcons.cloudOff,
          eyebrow: l10n.aiStateOfflineEyebrow,
          title: l10n.aiStateOfflineTitle,
          body: l10n.aiStateOfflineBody,
        ),
      );
    } else if (_error != null && !_busy) {
      states.add(
        AiStateCard(
          icon: ClIcons.alert,
          warm: true,
          eyebrow: l10n.aiStateErrorEyebrow,
          title: l10n.aiStateFailedTitle,
          body: l10n.aiStateFailedBody,
          action: canGenerate
              ? (l10n.rhRetry, () => _generate(me, fresh: true))
              : null,
        ),
      );
    } else if (!_busy &&
        (shown.stale ||
            (dataVersion != null &&
                shown.dataVersion != null &&
                dataVersion > shown.dataVersion!))) {
      states.add(
        AiStateCard(
          icon: ClIcons.spark,
          mint: true,
          title: l10n.aiStateStaleTitle,
          body: canGenerate ? l10n.aiStateStaleBody : l10n.aiStateStaleRead,
          action: canGenerate
              ? (l10n.aiStateStaleAction, () => _generate(me, fresh: true))
              : null,
        ),
      );
    }
    if (!health && canGenerate && shown.method == SummaryMethod.fallback) {
      if (_reasonCard(context, me, shown, settings) case final card?) {
        states.add(card);
      }
    }
    if (health) {
      states.add(RhHealthCard(signs: healthToday?.healthSigns ?? const []));
    }
    for (final (i, s) in states.indexed) {
      if (i > 0) content.add(const SizedBox(height: ClSpace.s3));
      content.add(s);
    }
    if (states.isNotEmpty) content.add(const SizedBox(height: ClSpace.s4));

    // Health: the free route only, never AI text (P-151).
    final showSections = !(health && shown.aiWorded);
    if (health) {
      content.addAll([
        RhNote(l10n.aiHealthBody, icon: ClIcons.alert),
        const SizedBox(height: ClSpace.s3),
      ]);
    }
    if (showSections) {
      if (shown.sections.isEmpty) {
        content.addAll([
          RhInfoBox(icon: ClIcons.journal, text: l10n.aiNoSections),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      for (final s in shown.sections) {
        content.addAll([
          _SectionCard(me: me, answer: shown, section: s),
          const SizedBox(height: ClSpace.s3),
        ]);
      }
      content.add(
        shown.aiWorded
            ? AiLabel(l10n.aiWordedByAi)
            : RhNote(l10n.aiTemplateLine, icon: ClIcons.journal),
      );
      final caregiver = members
          .where(
            (m) =>
                m.uid != me.uid && m.isActive && m.role == MemberRole.caregiver,
          )
          .firstOrNull;
      content.addAll([
        const SizedBox(height: ClSpace.s4),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            _OutlinePill(
              label: l10n.aiReport,
              onTap: () => _report(context, me, shown),
            ),
            if (canGenerate)
              Builder(
                builder: (box) => _OutlinePill(
                  label: caregiver == null
                      ? l10n.aiShare
                      : l10n.aiSendTo(memberLabel(l10n, caregiver, myUid: '')),
                  onTap: () => _share(box, shown, range),
                ),
              ),
          ],
        ),
      ]);
    }
    return OnboardingScaffold(topBar: topBar, content: content);
  }

  /// Why the template is shown, by its reason (ST01); only PREMIUM_REQUIRED links to the plan.
  Widget? _reasonCard(
    BuildContext context,
    Membership me,
    SummaryAnswer a,
    AiSettings? settings,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    if (a.technicalFailure) {
      return AiStateCard(
        icon: ClIcons.alert,
        warm: true,
        eyebrow: l10n.aiStateErrorEyebrow,
        title: l10n.aiStateTemplateTitle,
        body: l10n.aiStateErrorBody,
        action: (l10n.rhRetry, () => _generate(me, fresh: true)),
      );
    }
    final gate = a.gate;
    switch (gate) {
      case null:
        return null;
      case GateReason.consentRequired:
        // Consent given since this version was made: just make it again.
        if (settings?.granted ?? false) {
          return AiStateCard(
            icon: ClIcons.spark,
            eyebrow: l10n.aiStateConsentEyebrow,
            title: l10n.aiStateTemplateTitle,
            action: (l10n.aiStateStaleAction, () => _generate(me, fresh: true)),
          );
        }
        if (settings?.withdrawn ?? false) {
          return AiStateCard(
            icon: ClIcons.spark,
            eyebrow: l10n.aiStateOffEyebrow,
            title: l10n.aiTemplateLine,
            body: l10n.aiStateWithdrawnBody,
            action: (l10n.aiStateWithdrawnAction, () => _toConsent(me)),
          );
        }
        return AiStateCard(
          icon: ClIcons.spark,
          eyebrow: l10n.aiStateConsentEyebrow,
          title: l10n.aiStateTemplateTitle,
          body: l10n.aiStateConsentBody,
          action: (l10n.aiStateConsentAction, () => _toConsent(me)),
        );
      case GateReason.featureDisabled:
        return AiStateCard(
          icon: ClIcons.spark,
          eyebrow: l10n.aiStateOffEyebrow,
          title: l10n.aiTemplateLine,
          body: l10n.aiStateDisabledBody,
        );
      case GateReason.quotaExceeded:
        String when(QuotaWindow w) => w.resetsAt == null
            ? '—'
            : shortDay(locale, isoOf(inBabyZone(_zone(me), w.resetsAt!)));
        final day = a.quotaDay, month = a.quotaMonth;
        final body = day != null && day.exhausted
            ? l10n.aiStateQuotaDay(day.used, day.limit, when(day))
            : month != null && month.exhausted
            ? l10n.aiStateQuotaMonth(month.used, month.limit, when(month))
            : l10n.aiStateQuotaPlain;
        return AiStateCard(
          icon: ClIcons.clock,
          eyebrow: l10n.aiStateQuotaEyebrow,
          title: l10n.aiStateTemplateTitle,
          body: body,
        );
      case GateReason.premiumRequired:
        return AiStateCard(
          icon: ClIcons.spark,
          eyebrow: l10n.aiStateTemplateEyebrow,
          title: l10n.aiStateTemplateTitle,
          body: l10n.aiStatePremiumBody,
          // PR01 from Nhịp lớn lên (entry A).
          action: (
            l10n.rhLearnMoreOptional,
            () => openPaywall(context, entry: PaywallEntry.rhythm),
          ),
        );
      // ROLE_DENIED, REGION_UNAVAILABLE, NOT_MEMBER: explained, never sold.
      case final GateReason other:
        return AiStateCard(
          icon: ClIcons.spark,
          eyebrow: l10n.aiStateTemplateEyebrow,
          title: l10n.aiStateTemplateTitle,
          body: l10n.aiStateOtherBody,
          action: (l10n.rhWhy, () => showGateSheet(context, other)),
        );
    }
  }

  /// "Gửi cho …": the OS share sheet with plain text (no photos).
  Future<void> _share(BuildContext box, SummaryAnswer a, String range) async {
    final l10n = AppLocalizations.of(context);
    final render = box.findRenderObject() as RenderBox?;
    final origin = render == null
        ? null
        : render.localToGlobal(Offset.zero) & render.size;
    final text = [
      range.isEmpty ? l10n.aiHandoverTitle : '${l10n.aiHandoverTitle} · $range',
      for (final s in a.sections) '\n${sectionTitle(l10n, s.kind)}\n${s.text}',
      '\n${a.aiWorded ? l10n.aiShareAiLine : l10n.aiShareTemplateLine}',
    ].join('\n');
    await ref.read(aiShareProvider)(text, l10n.aiHandoverTitle, origin);
  }

  /// "Chưa đúng? Báo lại": one chosen reason, never free text about the child.
  Future<void> _report(
    BuildContext context,
    Membership me,
    SummaryAnswer a,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final problem = await showClSheet<ReportProblem>(
      context: context,
      builder: (sheet) => const _ReportSheet(),
    );
    if (problem == null || !mounted) return;
    try {
      await ref
          .read(aiRepositoryProvider)
          .report(babyId: me.babyId, summaryId: a.id, problem: problem);
      toaster.show(message: l10n.aiReportThanks);
    } on Object {
      toaster.show(message: l10n.aiReportFailed, error: true);
    }
  }
}

String sectionTitle(AppLocalizations l10n, SummarySectionKind k) => switch (k) {
  SummarySectionKind.noticed => l10n.aiSectionNoticed,
  SummarySectionKind.helped => l10n.aiSectionHelped,
  SummarySectionKind.next => l10n.aiSectionNext,
  SummarySectionKind.note => l10n.aiSectionNote,
};

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          CupertinoActivityIndicator(color: cl.colors.inkMuted, radius: 9),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              AppLocalizations.of(context).aiLoading,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// SU01's white outline pill ("Chưa đúng? Báo lại", "Gửi cho Cô Lan").
class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: ClSpace.tapMin),
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(color: cl.colors.controlBorder),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: cl.text.label.copyWith(
              color: cl.colors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the three parts: a tinted icon tile, the heading, the sentence and the notes behind it.
class _SectionCard extends ConsumerWidget {
  const _SectionCard({
    required this.me,
    required this.answer,
    required this.section,
  });
  final Membership me;
  final SummaryAnswer answer;
  final SummarySection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final (tile, ink, icon) = switch (section.kind) {
      SummarySectionKind.noticed => (
        cl.care.sleep.soft,
        cl.care.sleep.ink,
        ClIcons.eye,
      ),
      SummarySectionKind.helped => (
        cl.colors.mintSoft,
        cl.colors.mintText,
        ClIcons.heart,
      ),
      // Ink on soft warm fills, also in Night care.
      SummarySectionKind.next => (
        cl.colors.peachSoft,
        cl.colors.ink,
        ClIcons.arrowRight,
      ),
      SummarySectionKind.note => (
        cl.colors.surface2,
        cl.colors.ink,
        ClIcons.journal,
      ),
    };
    final facts = [for (final id in section.factIds) ?answer.fact(id)];
    return RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: tile,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: ClIcon(icon, size: 15, color: ink),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    sectionTitle(l10n, section.kind),
                    style: cl.text.bodyStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          Text(section.text, style: cl.text.body.copyWith(height: 1.45)),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [for (final f in facts) RecordChip(me: me, fact: f)],
            ),
          ],
        ],
      ),
    );
  }
}

/// A readable link to the note behind a sentence ("Ghi nhận của Ba · 07/10"), never "[F1]".
class RecordChip extends ConsumerWidget {
  const RecordChip({required this.me, required this.fact, super.key});
  final Membership me;
  final SummaryFact fact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final author = members.where((m) => m.uid == fact.authorUid).firstOrNull;
    final mine = fact.authorUid == me.uid;
    final date = shortDay(locale, fact.date);
    final family = memberLabel(l10n, author, myUid: '', uid: fact.authorUid);
    final label = switch (fact.kind) {
      FactKind.checkIn =>
        mine ? l10n.aiChipCheckInMine(date) : l10n.aiChipCheckIn(family, date),
      FactKind.feedback =>
        mine
            ? l10n.aiChipFeedbackMine(date)
            : l10n.aiChipFeedback(family, date),
      FactKind.milestone => l10n.aiChipMilestone(date),
      FactKind.sleep => l10n.aiChipSleep,
    };
    return ClPressable(
      onPressed: () => fact.kind == FactKind.sleep
          ? context.push(Routes.rhythm)
          : showRecord(context, me, fact),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.fromLTRB(4, 4, ClSpace.s2, 4),
        decoration: BoxDecoration(
          color: cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fact.kind == FactKind.sleep)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClIcon(ClIcons.sleep, size: 14, color: cl.colors.ink),
              )
            else
              RhInitial(
                fact.kind == FactKind.milestone && author == null
                    ? '★'
                    : family,
                size: 24,
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cl.text.caption.copyWith(
                  color: cl.colors.mintText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            ClIcon(ClIcons.chevronRight, size: 14, color: cl.colors.mintText),
          ],
        ),
      ),
    );
  }
}

/// The note a link points to, as this phone has it (the check-in with its answers, the feedback
/// with its activity), else the engine's line; feedback opens its activity.
Future<void> showRecord(BuildContext context, Membership me, SummaryFact fact) {
  return showClSheet<void>(
    context: context,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final l10n = AppLocalizations.of(sheet);
        final cl = sheet.cl;
        final locale = Localizations.localeOf(sheet);
        final members =
            ref.watch(familyMembersProvider(me.babyId)).value ??
            const <Membership>[];
        final author = members
            .where((m) => m.uid == fact.authorUid)
            .firstOrNull;
        final who = capitalized(
          memberLabel(l10n, author, myUid: me.uid, uid: fact.authorUid),
        );
        String? body;
        String? note;
        (String, VoidCallback)? action;
        switch (fact.kind) {
          case FactKind.checkIn:
            final c = (ref.watch(checkInsProvider(me.babyId)).value ?? [])
                .where((x) => x.id == fact.id)
                .firstOrNull;
            if (c != null) {
              body = checkInParts(l10n, c).join(' · ');
              note = c.note;
            }
          case FactKind.feedback:
            final f = (ref.watch(recFeedbackProvider(me.babyId)).value ?? [])
                .where((x) => x.id == fact.id)
                .firstOrNull;
            final activity = f == null
                ? null
                : ref.watch(rhythmContentProvider).value?.activity(f.contentId);
            if (f != null) {
              body = [
                activity?.title.of(locale) ?? l10n.rhUnknownActivity,
                feedbackKindLabel(l10n, f.kind),
              ].join(' · ');
              note = f.note;
            }
            if (activity != null) {
              action = (
                l10n.aiRecordOpenActivity,
                () {
                  Navigator.of(sheet).pop();
                  context.push(activityLocation(activity.id));
                },
              );
            }
          case FactKind.milestone || FactKind.sleep:
            break;
        }
        body ??= fact.text.isEmpty ? l10n.aiRecordGone : fact.text;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(
              title: switch (fact.kind) {
                FactKind.checkIn => l10n.aiRecordCheckIn,
                FactKind.feedback => l10n.aiRecordFeedback,
                _ => l10n.aiRecordMilestone,
              },
            ),
            Text(
              l10n.aiRecordWho(who, shortDay(locale, fact.date)),
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            Text(body, style: cl.text.bodyStrong),
            if (note != null && note.trim().isNotEmpty) ...[
              const SizedBox(height: ClSpace.s2),
              Text(
                l10n.rhQuoted(note.trim()),
                style: cl.text.body.copyWith(color: cl.colors.ink),
              ),
            ],
            const SizedBox(height: ClSpace.s4),
            if (action case final a?) ...[
              ClButton(label: a.$1, expand: true, onPressed: a.$2),
              const SizedBox(height: ClSpace.s2),
            ],
            ClButton(
              label: l10n.rhDone,
              expand: true,
              style: ClButtonStyle.secondary,
              onPressed: () => Navigator.of(sheet).pop(),
            ),
            const SizedBox(height: ClSpace.s4),
          ],
        );
      },
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet();

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportProblem? _choice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    String label(ReportProblem p) => switch (p) {
      ReportProblem.wrongFact => l10n.aiProblemWrongFact,
      ReportProblem.wrongPerson => l10n.aiProblemWrongPerson,
      ReportProblem.unsafeAdvice => l10n.aiProblemUnsafe,
      ReportProblem.language => l10n.aiProblemLanguage,
      ReportProblem.other => l10n.aiProblemOther,
    };
    ClIcons icon(ReportProblem p) => switch (p) {
      ReportProblem.wrongFact => ClIcons.journal,
      ReportProblem.wrongPerson => ClIcons.family,
      ReportProblem.unsafeAdvice => ClIcons.alert,
      ReportProblem.language => ClIcons.language,
      ReportProblem.other => ClIcons.edit,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.aiReportTitle),
        Text(
          l10n.aiReportBody,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        for (final p in ReportProblem.values) ...[
          RhOptionRow(
            label: label(p),
            icon: icon(p),
            selected: _choice == p,
            onTap: () => setState(() => _choice = p),
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.aiReportSend,
          expand: true,
          onPressed: _choice == null
              ? null
              : () => Navigator.of(context).pop(_choice),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

/// Home / NL01 entry: a Cùng nuôi opens SU01 to make or read the handover; a caregiver sees it
/// only once one is stored ("Bản mới nhất · 08/10"). Only with the `ai_assist` rollout.
class HandoverEntry extends ConsumerWidget {
  const HandoverEntry({super.key});

  /// Whether [HandoverEntry] draws anything for [me].
  static bool visibleFor(
    WidgetRef ref,
    Membership me,
    Capabilities? caps,
    String language,
  ) {
    if (caps == null || !caps.features.aiAssist) return false;
    if (!familyCan(me, FamilyAction.historyRead)) return false;
    if (familyCan(me, FamilyAction.aiGenerate)) return true;
    final stored = ref.watch(handoversProvider(me.babyId)).value;
    return latestHandover(stored ?? const [], language) != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final caps = ref.watch(selectedCapabilitiesProvider);
    if (me == null || !visibleFor(ref, me, caps, locale.languageCode)) {
      return const SizedBox.shrink();
    }
    final reader = !familyCan(me, FamilyAction.aiGenerate);
    final latest = reader
        ? latestHandover(
            ref.watch(handoversProvider(me.babyId)).value ?? const [],
            locale.languageCode,
          )
        : null;
    final at = latest?.generatedAt;
    final sub = reader && at != null
        ? l10n.aiHandoverEntryLatest(
            shortDay(
              locale,
              isoOf(
                inBabyZone(
                  ref.watch(babyProvider(me.babyId)).value?.timeZone.zone ??
                      'Asia/Ho_Chi_Minh',
                  at,
                ),
              ),
            ),
          )
        : l10n.aiHandoverEntrySub;
    return RhCard(
      onTap: () => context.push(Routes.rhythmHandover),
      semanticLabel: '${l10n.aiHandoverTitle}. $sub',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cl.care.sleep.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: ClIcon(ClIcons.journal, size: 20, color: cl.care.sleep.ink),
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.aiHandoverTitle, style: cl.text.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ],
            ),
          ),
          ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
        ],
      ),
    );
  }
}
