import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../premium/premium_models.dart';
import '../rhythm/rhythm_access.dart';
import '../rhythm/rhythm_widgets.dart';
import 'ai_models.dart';
import 'ai_repository.dart';

/// Shared pieces of the grounded-AI screens: the AI label, the ST01 state card, "Giải thích
/// thêm" (PS01 / AC01) and the MS01 moment nudge. The screens never depend on AI: the free text
/// they had before stays, and AI text only adds to it.

/// May [me] ask for AI text in this household: the `ai_assist` rollout, `ai.assistance` (group A)
/// and the role (`ai.generate`: Cùng nuôi only, D-072 #2). Consent and quota are the server's.
bool aiAvailable(Capabilities? caps, Membership? me) =>
    caps != null &&
    me != null &&
    caps.features.aiAssist &&
    caps.allows(Capability.aiAssistance) &&
    familyCan(me, FamilyAction.aiGenerate);

/// "✦ Diễn đạt bởi AI từ ghi nhận đã lưu" (SU01): only on AI-worded text.
class AiLabel extends StatelessWidget {
  const AiLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ClIcon(ClIcons.spark, size: 14, color: cl.colors.inkMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: cl.text.caption.copyWith(
              color: cl.colors.inkMuted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// ST01 (594:6967) state card: a white card with a 26 pt icon chip, an uppercase eyebrow, a
/// headline, a muted body and an optional `mint-text` link. [warm]: the "AI chưa phản hồi" chip
/// (sunshine-soft, ink on it).
class AiStateCard extends StatelessWidget {
  const AiStateCard({
    required this.icon,
    required this.title,
    this.eyebrow,
    this.body,
    this.action,
    this.warm = false,
    this.mint = false,
    super.key,
  });

  final ClIcons icon;
  final String? eyebrow;
  final String title;
  final String? body;
  final (String, VoidCallback)? action;
  final bool warm;

  /// A good-news card (new notes since this version): mint-soft chip.
  final bool mint;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final chip = warm
        ? cl.colors.sunshineSoft
        : mint
        ? cl.colors.mintSoft
        : cl.colors.surface2;
    final chipInk = mint ? cl.colors.mintText : cl.colors.ink;
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
                  color: chip,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                // Ink on soft warm fills, also in Night care.
                child: ClIcon(icon, size: 15, color: chipInk),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                // Without an eyebrow the headline sits next to the chip.
                child: eyebrow == null
                    ? Text(title, style: cl.text.bodyStrong)
                    : Text(
                        eyebrow!,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ],
          ),
          if (eyebrow != null) ...[
            const SizedBox(height: ClSpace.s2),
            Text(title, style: cl.text.bodyStrong),
          ] else
            const SizedBox(height: ClSpace.s1),
          if (body != null) ...[
            const SizedBox(height: 2),
            Text(
              body!,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
          ],
          if (action case final a?)
            Align(
              alignment: Alignment.centerLeft,
              child: RhLink(label: a.$1, onTap: a.$2, start: true),
            ),
        ],
      ),
    );
  }
}

/// The sentences of an answer as one paragraph per section.
String summaryText(SummaryAnswer a) =>
    [for (final s in a.sections) s.text].join('\n');

/// "Giải thích thêm" under PS01's "Vì sao gợi ý này" / AC01's reason (kind `explain`). The reason
/// above it is the fallback and never goes away; this only adds AI wording of the same facts, or
/// says why it can't.
class AiExplainBlock extends ConsumerStatefulWidget {
  const AiExplainBlock({
    required this.babyId,
    required this.recommendationId,
    super.key,
  });

  final String babyId;
  final String recommendationId;

  @override
  ConsumerState<AiExplainBlock> createState() => _AiExplainBlockState();
}

class _AiExplainBlockState extends ConsumerState<AiExplainBlock> {
  var _asked = false;
  var _busy = false;
  SummaryAnswer? _answer;
  Object? _error;

  Future<void> _ask() async {
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _asked = true;
      _busy = true;
      _error = null;
    });
    try {
      final a = await ref
          .read(aiRepositoryProvider)
          .generate(
            babyId: widget.babyId,
            kind: AiSummaryKind.explain,
            locale: locale,
            requestId: newAiRequestId(),
            recommendationId: widget.recommendationId,
          );
      if (mounted) setState(() => _answer = a);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _consent() async {
    await context.push(Routes.rhythmAiConsent);
    if (mounted) unawaited(_ask());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    if (!_asked) {
      return Align(
        alignment: Alignment.centerLeft,
        child: RhLink(label: l10n.aiExplainMore, onTap: _ask, start: true),
      );
    }
    if (_busy) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
          child: Row(
            children: [
              CupertinoActivityIndicator(color: cl.colors.inkMuted, radius: 8),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  l10n.aiExplainLoading,
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final a = _answer;
    Widget note(String text, [(String, VoidCallback)? action]) => Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
          if (action case final x?)
            Align(
              alignment: Alignment.centerLeft,
              child: RhLink(label: x.$1, onTap: x.$2, start: true),
            ),
        ],
      ),
    );
    if (a == null || a.health) {
      final consent =
          _error is AiException &&
          (_error! as AiException).gate == GateReason.consentRequired;
      if (consent) {
        return note(l10n.aiExplainConsent, (
          l10n.aiStateConsentAction,
          _consent,
        ));
      }
      return note(
        a == null ? l10n.aiExplainFailed : l10n.aiExplainUnavailable,
        a == null ? (l10n.rhRetry, _ask) : null,
      );
    }
    if (!a.aiWorded) {
      if (a.technicalFailure) {
        return note(l10n.aiExplainFailed, (l10n.rhRetry, _ask));
      }
      switch (a.gate) {
        case GateReason.consentRequired:
          return note(l10n.aiExplainConsent, (
            l10n.aiStateConsentAction,
            _consent,
          ));
        case GateReason.quotaExceeded:
          return note(l10n.aiExplainQuota);
        case null:
          break;
        default:
          if (a.sections.isEmpty) return note(l10n.aiExplainUnavailable);
      }
      if (a.sections.isEmpty) return note(l10n.aiExplainFailed);
    }
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: RhInfoBox(
        icon: a.aiWorded ? ClIcons.spark : ClIcons.journal,
        tone: RhInfoTone.mint,
        label: l10n.aiExplainMore,
        text: summaryText(a),
        child: Padding(
          padding: const EdgeInsets.only(top: ClSpace.s2),
          child: Text(
            a.aiWorded ? l10n.aiWordedShort : l10n.aiTemplateLine,
            style: cl.text.caption.copyWith(
              color: cl.colors.inkMuted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

/// MS01's moment nudge (kind `moment`): once the milestone is saved, a sentence worded from the
/// family's notes under "Giữ khoảnh khắc này?". Nothing shows until there is one; the screen's
/// own copy is the fallback and stays.
class AiMomentNudge extends ConsumerStatefulWidget {
  const AiMomentNudge({
    required this.babyId,
    required this.milestoneId,
    super.key,
  });

  final String babyId;
  final String milestoneId;

  @override
  ConsumerState<AiMomentNudge> createState() => _AiMomentNudgeState();
}

class _AiMomentNudgeState extends ConsumerState<AiMomentNudge> {
  SummaryAnswer? _answer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_ask()));
  }

  Future<void> _ask() async {
    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final a = await ref
          .read(aiRepositoryProvider)
          .generate(
            babyId: widget.babyId,
            kind: AiSummaryKind.moment,
            locale: locale,
            requestId: newAiRequestId(),
            milestoneId: widget.milestoneId,
          );
      if (mounted) setState(() => _answer = a);
    } on Object {
      // The screen's own copy stays; nothing to add.
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _answer;
    if (a == null || a.health || a.sections.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summaryText(a),
            style: cl.text.body.copyWith(color: cl.colors.ink),
          ),
          if (a.aiWorded) ...[
            const SizedBox(height: ClSpace.s1),
            AiLabel(l10n.aiWordedShort),
          ],
        ],
      ),
    );
  }
}
