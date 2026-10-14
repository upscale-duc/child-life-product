import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'rhythm_actions.dart';
import 'rhythm_repository.dart';
import 'rhythm_widgets.dart';

/// "Tuần này của {bé}" detail (R0, Q-067): what families often notice at this age, things to
/// try, when to ask a doctor, sources and the review label. Free in every plan state; no
/// schedule ("mỗi bé mỗi khác").
class AgeCardScreen extends ConsumerWidget {
  const AgeCardScreen({required this.cardId, super.key});
  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final content = ref.watch(rhythmContentProvider);
    final card = content.value?.ageCard(cardId);
    final tips = card?.tips.of(locale) ?? const <String>[];
    final watch = card?.watchFor.of(locale) ?? const <String>[];
    return OnboardingScaffold(
      topBar: Align(
        alignment: Alignment.centerLeft,
        child: RhRoundIcon(
          icon: ClIcons.back,
          label: l10n.a11yBack,
          onPressed: () => leaveRhythm(context),
        ),
      ),
      content: [
        if (card == null && !content.isLoading)
          RhCard(
            child: Text(l10n.rhActivityMissing, style: cl.text.bodyStrong),
          ),
        if (card != null) ...[
          RhPill(label: l10n.rhAgeFree, icon: ClIcons.cake),
          const SizedBox(height: ClSpace.s3),
          Semantics(
            header: true,
            child: Text(
              card.title.of(locale),
              style: cl.text.title2.copyWith(color: cl.colors.ink),
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Text(card.body.of(locale), style: cl.text.body.copyWith(height: 1.5)),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s4),
            RhCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RhCardHeading(l10n.rhAgeTips),
                  const SizedBox(height: ClSpace.s2),
                  RhBullets(tips),
                ],
              ),
            ),
          ],
          if (watch.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ClSpace.s4),
              decoration: BoxDecoration(
                color: cl.colors.sunshineSoft,
                borderRadius: BorderRadius.circular(rhCardRadius),
              ),
              // Ink on soft warm fills, also in Night care.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rhAgeWatch,
                    style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
                  ),
                  const SizedBox(height: ClSpace.s2),
                  RhBullets(watch, color: cl.colors.ink),
                ],
              ),
            ),
          ],
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.rhAgeEach,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s2),
          RhReviewNote(card.review),
          if (card.sources.isNotEmpty) ...[
            const SizedBox(height: ClSpace.s1),
            Text(
              '${l10n.rhSources}: ${card.sources.map((s) => s.label).join(' · ')}',
              style: cl.text.caption.copyWith(
                color: cl.colors.inkMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
