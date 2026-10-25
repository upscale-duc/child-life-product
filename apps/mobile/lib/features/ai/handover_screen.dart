import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../care/care_duty.dart';
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
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
import '../rhythm/personal_day_pages.dart' show PersonalHeading;
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_actions.dart';
import '../rhythm/rhythm_calc.dart' show isoOf;
import '../rhythm/rhythm_home.dart' show RhHealthCard;
import '../rhythm/rhythm_labels.dart';
import '../rhythm/rhythm_models.dart' show FeedbackKind, RecFeedback;
import '../rhythm/rhythm_repository.dart';
import '../rhythm/rhythm_widgets.dart';
import 'handover_now.dart';
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
  const HandoverScreen({this.summaryId, this.summaryOpen = false, super.key});

  /// D-093: the handover a family member sent (from its notification); else the latest.
  final String? summaryId;

  /// Whether "Tóm tắt mấy ngày qua" starts open (P-180 v2: folded; tests open it).
  final bool summaryOpen;

  @override
  ConsumerState<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends ConsumerState<HandoverScreen> {
  var _requestId = newAiRequestId();
  SummaryAnswer? _answer;
  AiException? _error;
  var _busy = false;
  var _autoAsked = false;
  var _sending = false;
  late var _summaryOpen = widget.summaryOpen;

  /// Sends marked "seen" from this screen (once each).
  final _seenMarked = <String>{};

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
        widget.summaryId == null &&
        !_autoAsked &&
        !storedAsync.isLoading &&
        (stored == null || stored.language != locale.languageCode)) {
      _autoAsked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_generate(me));
      });
    }

    final picked = widget.summaryId == null
        ? null
        : (storedAsync.value ?? const <SummaryAnswer>[])
              .where((a) => a.id == widget.summaryId)
              .firstOrNull;
    final shown = _answer ?? picked ?? stored;
    final health = healthToday != null || (shown?.health ?? false);
    // P-180 v2: whose handover and how fresh the diary is, not when a summary was made.
    final content = <Widget>[
      title,
      const SizedBox(height: ClSpace.s1),
      Text(
        l10n.hoUpdated(
          baby?.nickname ?? '',
          DateFormat('HH:mm').format(inBabyZone(zone, now)),
        ),
        style: cl.text.label.copyWith(color: cl.colors.inkMuted),
      ),
      const SizedBox(height: ClSpace.s3),
      // P-181: who is caring now, for everyone; tapping it takes or ends a shift.
      CareDutyLine(me: me),
      const SizedBox(height: ClSpace.s3),
    ];
    final healthCard = [
      if (health) ...[
        RhHealthCard(signs: healthToday?.healthSigns ?? const []),
        const SizedBox(height: ClSpace.s3),
      ],
    ];

    if (shown == null) {
      content.addAll([
        ...healthCard,
        HandoverNow(me: me),
        PersonalHeading(l10n.hoSummary),
      ]);
      if (_busy ||
          storedAsync.isLoading ||
          (canGenerate && online && _error == null)) {
        content.add(const _Skeleton());
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
      content.add(HandoverSafety(me: me));
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
    // One line: the days it covers and when it was made (who wrote what is inside).
    final summaryMeta = [
      if (range.isNotEmpty) range,
      if (shown.generatedAt case final at?)
        l10n.aiGeneratedAt(
          '${shortDay(locale, isoOf(inBabyZone(zone, at)))} · '
          '${DateFormat('HH:mm').format(inBabyZone(zone, at))}',
        ),
    ].join(' · ');

    // D-093: sent to me — a banner with who sent it and "Tôi đã nhận bàn giao"; opening it marks
    // it seen for the sender.
    final toMe = [
      for (final s
          in ref
                  .watch(
                    receivedHandoversProvider((babyId: me.babyId, uid: me.uid)),
                  )
                  .value ??
              const <HandoverSend>[])
        if (s.summaryId == shown.id) s,
    ].firstOrNull;
    if (toMe != null && toMe.seenAt == null && _seenMarked.add(toMe.id)) {
      unawaited(
        ref
            .read(aiRepositoryProvider)
            .markHandover(babyId: me.babyId, sendId: toMe.id, received: false)
            .catchError((Object _) {}),
      );
    }
    if (toMe != null) {
      final from = capitalized(who(toMe.senderUid));
      final at = DateFormat('HH:mm').format(inBabyZone(zone, toMe.sentAt));
      content.addAll([
        _ReceivedBanner(title: l10n.aiSentToYou(from, at), note: toMe.note),
        const SizedBox(height: ClSpace.s4),
      ]);
    }

    // What the next person needs first, live from the diary (owner, 2026-10-25); the summary of
    // the last days follows under its own heading.
    content.addAll([...healthCard, HandoverNow(me: me)]);
    // Everything below folds under "Tóm tắt mấy ngày qua" (states, sections, the AI line).
    final summaryStart = content.length;
    var folded = false;
    void fold() {
      if (folded) return;
      folded = true;
      final parts = content.sublist(summaryStart);
      content.removeRange(summaryStart, content.length);
      content.addAll([
        const SizedBox(height: ClSpace.s4),
        _SummaryFold(
          title: l10n.hoSummary,
          meta: summaryMeta,
          open: _summaryOpen,
          onTap: () => setState(() => _summaryOpen = !_summaryOpen),
        ),
        if (_summaryOpen) ...[const SizedBox(height: ClSpace.s3), ...parts],
        HandoverSafety(me: me),
      ]);
    }

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
      fold();
      // The recipient's action is the receipt; sending stays the sender's (owner, 2026-10-25).
      if (toMe != null) {
        content.add(
          _ReceiveAction(
            // P-181: a carer receiving it also takes over ("Tôi nhận trông bé").
            label: familyCan(me, FamilyAction.rhythmFeedback)
                ? l10n.hoTakeOver
                : l10n.pv2Acknowledge,
            receivedAt: toMe.receivedAt == null
                ? null
                : DateFormat(
                    'HH:mm',
                  ).format(inBabyZone(zone, toMe.receivedAt!)),
            onReceived: () => withClProgress(
              context,
              () => ref
                  .read(aiRepositoryProvider)
                  .markHandover(
                    babyId: me.babyId,
                    sendId: toMe.id,
                    received: true,
                  ),
            ),
          ),
        );
        return OnboardingScaffold(topBar: topBar, content: content);
      }
      // D-093 "Gửi cho Jun": everyone else in the family who reads care can be sent it, in
      // either direction; the caregiver comes first ("Gửi cho Jun").
      final candidates =
          members
              .where(
                (m) =>
                    m.uid != me.uid &&
                    m.isActive &&
                    familyCan(m, FamilyAction.historyRead),
              )
              .toList()
            ..sort(
              (a, b) =>
                  (a.role == MemberRole.caregiver ? 0 : 1) -
                  (b.role == MemberRole.caregiver ? 0 : 1),
            );
      final sends = [
        for (final s
            in ref
                    .watch(
                      sentHandoversProvider((babyId: me.babyId, uid: me.uid)),
                    )
                    .value ??
                const <HandoverSend>[])
          if (s.summaryId == shown.id) s,
      ];
      final unsent = [
        for (final m in candidates)
          if (!sends.any((s) => s.recipientUid == m.uid)) m,
      ];
      String name(String uid) => capitalized(
        memberLabel(
          l10n,
          members.where((m) => m.uid == uid).firstOrNull,
          myUid: '',
          uid: uid,
        ),
      );
      String hm(DateTime at) =>
          DateFormat('HH:mm').format(inBabyZone(zone, at));
      // Owner, 2026-10-22: sending is the screen's main action — a full-width button; the
      // report stays a quiet link under it.
      content.addAll([
        const SizedBox(height: ClSpace.s4),
        for (final s in sends) ...[
          _SendStatus(
            line: l10n.aiSentTo(name(s.recipientUid), hm(s.sentAt)),
            state: s.receivedAt != null
                ? l10n.aiSendReceived(name(s.recipientUid), hm(s.receivedAt!))
                : s.seenAt != null
                ? l10n.aiSendSeen(name(s.recipientUid), hm(s.seenAt!))
                : l10n.aiSendNotSeen,
            done: s.receivedAt != null,
          ),
          const SizedBox(height: ClSpace.s2),
        ],
        if (unsent.isNotEmpty && shown.id.isNotEmpty)
          ClButton(
            key: const Key('handoverSend'),
            label: unsent.length == 1
                ? l10n.aiSendTo(memberLabel(l10n, unsent.single, myUid: ''))
                : sends.isEmpty
                ? l10n.aiSendToFamily
                : l10n.aiSendToOther,
            expand: true,
            loading: _sending,
            onPressed: _sending
                ? null
                : () => _send(context, me, shown, unsent, range),
          ),
        Builder(
          builder: (box) => Center(
            child: RhLink(
              label: candidates.isEmpty ? l10n.aiShare : l10n.aiShareOther,
              onTap: () => _share(box, shown, range),
            ),
          ),
        ),
        Center(
          child: RhLink(
            label: l10n.aiReport,
            muted: true,
            onTap: () => _report(context, me, shown),
          ),
        ),
      ]);
    }
    fold();
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

  /// D-093: sends [a] to one member (asked first when there are several). When the push cannot
  /// reach them (no device, switch off) it says so and offers the share sheet.
  /// An optional note before sending; null when the sheet is dismissed.
  Future<String?> _askNote(BuildContext context, String sendLabel) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showClSheet<String>(
      context: context,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          ClSpace.s4,
          ClSpace.s3,
          ClSpace.s4,
          ClSpace.s6 + MediaQuery.viewInsetsOf(sheet).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.aiSendToFamily),
            ClTextField(
              controller: controller,
              placeholder: l10n.hoNoteHint,
              maxLength: 300,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: ClSpace.s3),
            ClButton(
              label: sendLabel,
              expand: true,
              onPressed: () => Navigator.of(sheet).pop(controller.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(
    BuildContext context,
    Membership me,
    SummaryAnswer a,
    List<Membership> unsent,
    String range,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final to = unsent.length == 1
        ? unsent.single
        : await showClSheet<Membership>(
            context: context,
            builder: (sheet) => Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s3,
                ClSpace.s4,
                ClSpace.s6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClSheetHeader(title: l10n.aiSendToFamily),
                  ClCardGroup(
                    color: sheet.cl.colors.surface2,
                    children: [
                      for (final m in unsent)
                        ClListRow(
                          leading: RhInitial(memberLabel(l10n, m, myUid: '')),
                          title: capitalized(memberLabel(l10n, m, myUid: '')),
                          onTap: () => Navigator.of(sheet).pop(m),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
    if (to == null || !mounted || !context.mounted) return;
    // The sender's own words for the next person (owner, 2026-10-25); dismissing cancels.
    final note = await _askNote(
      context,
      l10n.aiSendTo(capitalized(memberLabel(l10n, to, myUid: ''))),
    );
    if (note == null || !mounted) return;
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(aiRepositoryProvider)
          .sendHandover(
            babyId: me.babyId,
            summaryId: a.id,
            recipientUid: to.uid,
            note: note,
          );
      final name = capitalized(memberLabel(l10n, to, myUid: ''));
      if (result.pushable) {
        toaster.show(message: l10n.aiSentToast(name));
      } else if (context.mounted) {
        // Not reachable by push: the handover still waits in the app; offer Zalo & co.
        final box = context.findRenderObject() as RenderBox?;
        toaster.show(
          message: l10n.aiSentNoPush(name),
          actionLabel: l10n.aiShareShort,
          visibleFor: const Duration(seconds: 8),
          onAction: () {
            if (box != null && context.mounted) _share(context, a, range);
          },
        );
      }
    } on AiException {
      toaster.show(message: l10n.aiSendFailed, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
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

/// The summary as it will look, while it is made (owner, 2026-10-22: skeletons, not a
/// spinner line): three section cards of grey lines.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      liveRegion: true,
      label: AppLocalizations.of(context).aiLoading,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ClSkeleton(width: 220, height: 14, radius: 7),
            const SizedBox(height: ClSpace.s4),
            for (var i = 0; i < 3; i++) ...[
              RhCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        ClSkeleton(width: 26, height: 26, radius: 8),
                        SizedBox(width: ClSpace.s2),
                        ClSkeleton(width: 140, height: 16, radius: 8),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s3),
                    const ClSkeleton(height: 12, radius: 6),
                    const SizedBox(height: ClSpace.s2),
                    const ClSkeleton(height: 12, radius: 6),
                    const SizedBox(height: ClSpace.s2),
                    const ClSkeleton(width: 180, height: 12, radius: 6),
                    const SizedBox(height: ClSpace.s3),
                    ClSkeleton(height: 44, radius: ClRadius.control),
                  ],
                ),
              ),
              const SizedBox(height: ClSpace.s3),
            ],
            Text(
              AppLocalizations.of(context).aiLoading,
              textAlign: TextAlign.center,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // Owner, 2026-10-22: one line per activity (its answers as tags), not one per answer.
    final feedback =
        ref.watch(recFeedbackProvider(me.babyId)).value ?? const [];
    final groups = <String, List<SummaryFact>>{};
    for (final f in facts) {
      final row = f.kind == FactKind.feedback
          ? feedback.where((x) => x.id == f.id).firstOrNull
          : null;
      (groups[row == null ? f.id : 'activity:${row.contentId}'] ??= []).add(f);
    }
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
          // The template's text is the same lines as the rows below (owner, 2026-10-24: "nguyên
          // 1 mớ đoạn chữ"); it is shown only when the AI worded it or there are no rows.
          if (answer.aiWorded || facts.isEmpty) ...[
            const SizedBox(height: ClSpace.s2),
            Text(section.text, style: cl.text.body.copyWith(height: 1.45)),
          ],
          // Owner, 2026-10-22: what each source says ("Nằm sấp có người lớn bên cạnh · Có
          // ích · 21/10"), one per line, not four identical "Phản hồi của bạn" chips.
          if (facts.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Container(
              decoration: BoxDecoration(
                color: cl.colors.surface2,
                borderRadius: BorderRadius.circular(ClRadius.control),
              ),
              child: Column(
                children: [
                  for (final (i, g) in groups.values.indexed) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(left: ClSpace.s3),
                        color: cl.colors.separator,
                      ),
                    RecordChip(me: me, facts: g),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The notes behind a sentence, one line per activity or check-in: what it is, its answers as
/// coloured tags ("Có ích", "Mình sẽ thử"), who and when; opens the latest note.
class RecordChip extends ConsumerWidget {
  const RecordChip({required this.me, required this.facts, super.key});
  final Membership me;

  /// Notes about the same thing (one activity's answers), any order.
  final List<SummaryFact> facts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final members =
        ref.watch(familyMembersProvider(me.babyId)).value ??
        const <Membership>[];
    final sorted = [...facts]..sort((a, b) => b.date.compareTo(a.date));
    final latest = sorted.first;
    String person(String uid) => uid == me.uid
        ? l10n.careYou
        : capitalized(
            memberLabel(
              l10n,
              members.where((m) => m.uid == uid).firstOrNull,
              myUid: '',
              uid: uid,
            ),
          );
    final dates = {for (final f in sorted) shortDay(locale, f.date)}.toList();
    final when = dates.length == 1
        ? dates.single
        : l10n.rhDateRange(dates.last, dates.first);
    final who = joinNames(
      l10n,
      {for (final f in sorted) person(f.authorUid ?? '')}.toList(),
    );
    String? title;
    final tags = <(String, Color, Color)>[];
    switch (latest.kind) {
      case FactKind.checkIn:
        final c = (ref.watch(checkInsProvider(me.babyId)).value ?? [])
            .where((x) => x.id == latest.id)
            .firstOrNull;
        if (c != null) title = checkInParts(l10n, c).join(' · ');
      case FactKind.feedback:
        final rows = ref.watch(recFeedbackProvider(me.babyId)).value ?? [];
        final answers = <RecFeedback>[];
        for (final f in sorted) {
          final row = rows.where((x) => x.id == f.id).firstOrNull;
          if (row == null) continue;
          title ??= ref
              .watch(rhythmContentProvider)
              .value
              ?.activity(row.contentId)
              ?.title
              .of(locale);
          answers.add(row);
        }
        // The latest answer is the state (owner, 2026-10-24: "Có ích" beside "Mình sẽ thử" read
        // as a contradiction); an earlier helpful try under a new plan reads "Từng có ích".
        answers.sort(
          (a, b) => '${a.date}${a.createdAt?.toIso8601String() ?? ''}'
              .compareTo('${b.date}${b.createdAt?.toIso8601String() ?? ''}'),
        );
        final latest = answers.lastOrNull?.kind;
        final helpedBefore =
            latest == FeedbackKind.started &&
            answers.any((a) => a.kind == FeedbackKind.helpful);
        if (helpedBefore) {
          tags.add((
            l10n.pv2ChipHelpedBefore,
            cl.colors.surface,
            cl.colors.inkMuted,
          ));
        }
        for (final k in [?latest]) {
          tags.insert(0, switch (k) {
            FeedbackKind.helpful => (
              feedbackKindLabel(l10n, k),
              cl.colors.mintDeep,
              cl.colors.onMintDeep,
            ),
            // Ink on the soft warm fill, also in Night care.
            FeedbackKind.started => (
              feedbackKindLabel(l10n, k),
              cl.colors.sunshineSoft,
              cl.colors.ink,
            ),
            _ => (
              feedbackKindLabel(l10n, k),
              cl.colors.surface,
              cl.colors.inkMuted,
            ),
          });
        }
        title ??= l10n.rhUnknownActivity;
      case FactKind.milestone || FactKind.sleep:
        break;
    }
    title ??= latest.text.isNotEmpty
        ? latest.text
        : switch (latest.kind) {
            FactKind.milestone => l10n.aiChipMilestone(when),
            _ => l10n.aiChipSleep,
          };
    final sub = latest.kind == FactKind.sleep ? null : '$who · $when';
    return ClPressable(
      onPressed: () => latest.kind == FactKind.sleep
          ? context.push(Routes.rhythm)
          : showRecord(context, me, latest),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: [title, for (final t in tags) t.$1, ?sub].join(', '),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s3,
          vertical: 10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.label.copyWith(
                      color: cl.colors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (text, fill, ink) in tags)
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: fill,
                              borderRadius: BorderRadius.circular(
                                ClRadius.pill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  text,
                                  style: cl.text.caption.copyWith(
                                    color: ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (sub != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sub,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 14, color: cl.colors.inkMuted),
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
    // D-093: one sent to me and not opened yet — "Mới", and the row opens that one.
    final waiting =
        (ref
                    .watch(
                      receivedHandoversProvider((
                        babyId: me.babyId,
                        uid: me.uid,
                      )),
                    )
                    .value ??
                const <HandoverSend>[])
            .where((h) => h.seenAt == null)
            .firstOrNull;
    final from = waiting == null
        ? null
        : capitalized(
            memberLabel(
              l10n,
              (ref.watch(familyMembersProvider(me.babyId)).value ?? const [])
                  .where((m) => m.uid == waiting.senderUid)
                  .firstOrNull,
              myUid: me.uid,
              uid: waiting.senderUid,
            ),
          );
    final line = from == null ? sub : l10n.aiSentToYouShort(from);
    return RhCard(
      onTap: () => context.push(
        waiting == null
            ? Routes.rhythmHandover
            : '${Routes.rhythmHandover}?summary=${waiting.summaryId}',
      ),
      semanticLabel: '${l10n.aiHandoverTitle}. $line',
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.aiHandoverTitle,
                        style: cl.text.bodyStrong,
                      ),
                    ),
                    if (waiting != null) ...[
                      const SizedBox(width: ClSpace.s2),
                      Container(
                        key: const Key('handoverNew'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.mintDeep,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          l10n.aiNewBadge,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.onMintDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  style: cl.text.caption.copyWith(
                    color: waiting == null
                        ? cl.colors.inkMuted
                        : cl.colors.mintText,
                    fontWeight: waiting == null ? null : FontWeight.w600,
                  ),
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

/// D-093: "Đã gửi cho Jun · 12:30" and where it is: not opened, seen, acknowledged.
class _SendStatus extends StatelessWidget {
  const _SendStatus({
    required this.line,
    required this.state,
    required this.done,
  });
  final String line;
  final String state;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      key: const Key('handoverSendStatus'),
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: done ? cl.colors.mintSoft : cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.control),
      ),
      child: Row(
        children: [
          ClIcon(
            done ? ClIcons.check : ClIcons.clock,
            size: 18,
            color: done ? cl.colors.mintText : cl.colors.inkMuted,
          ),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line,
                  style: cl.text.label.copyWith(
                    color: cl.colors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  state,
                  style: cl.text.caption.copyWith(
                    color: done ? cl.colors.mintText : cl.colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// D-093: on the recipient's screen — who sent it, and "Tôi đã nhận bàn giao".
class _ReceivedBanner extends StatelessWidget {
  const _ReceivedBanner({required this.title, this.note});
  final String title;

  /// The sender's own words (owner, 2026-10-25), shown under who sent it.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return RhCard(
      key: const Key('handoverReceived'),
      outline: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClIcon(ClIcons.mail, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  title,
                  style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
          if (note case final n?) ...[
            const SizedBox(height: ClSpace.s2),
            Text('“$n”', style: cl.text.body.copyWith(height: 1.45)),
          ],
        ],
      ),
    );
  }
}

/// The recipient's action at the foot of Bàn giao: "Tôi đã nhận bàn giao", then the receipt.
class _ReceiveAction extends StatelessWidget {
  const _ReceiveAction({
    required this.label,
    required this.receivedAt,
    required this.onReceived,
  });
  final String label;
  final String? receivedAt;
  final Future<void> Function() onReceived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (receivedAt case final at?) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClIcon(ClIcons.check, size: 18, color: cl.colors.mintText),
            const SizedBox(width: 6),
            Text(
              l10n.aiYouReceived(at),
              style: cl.text.bodyStrong.copyWith(color: cl.colors.mintText),
            ),
          ],
        ),
      );
    }
    return ClButton(
      key: const Key('handoverAcknowledge'),
      label: label,
      expand: true,
      onPressed: onReceived,
    );
  }
}

/// "Tóm tắt mấy ngày qua": the AI summary behind one row, with its range and time.
class _SummaryFold extends StatelessWidget {
  const _SummaryFold({
    required this.title,
    required this.meta,
    required this.open,
    required this.onTap,
  });
  final String title;
  final String meta;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      key: const Key('handoverSummaryFold'),
      onPressed: onTap,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ClSpace.s4,
          vertical: ClSpace.s3,
        ),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.card),
          border: Border.all(color: cl.colors.separator),
        ),
        child: Row(
          children: [
            ClIcon(ClIcons.spark, size: 18, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: cl.text.body),
                  if (meta.isNotEmpty)
                    Text(
                      meta,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: ClIcon(
                ClIcons.chevronDown,
                size: 18,
                color: cl.colors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
