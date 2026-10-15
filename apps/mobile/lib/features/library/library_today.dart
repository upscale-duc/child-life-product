import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../rhythm/rhythm_models.dart' show Interest;
import '../today/today_for_baby.dart';
import 'content_calc.dart';
import 'content_models.dart';
import 'content_repository.dart';
import 'library_routes.dart';
import 'library_widgets.dart';
import 'stage_screens.dart' show lbVisibleStages;

/// Hôm nay · "Dành cho bé hôm nay" small cards from Giai đoạn của bé and Thư viện chăm bé
/// (D-076 #4, #5, #7), fed to `articleForBabyCardsProvider` in `today/today_for_baby.dart`:
///
/// 1. the current stage ("Giai đoạn của bé · 3–4 tuần"), or, for a parent when the date of birth
///    is unknown, "Thêm ngày sinh của bé" (2c on Hôm nay);
/// 2. up to two care articles for the baby's age, newest first.
///
/// Only published content: nothing shows while nothing is published.
final lbForBabyCardsProvider = Provider.family<List<ForBabyCard>, ForBabyQuery>(
  (ref, q) {
    final baby = ref.watch(lbBabyProvider);
    if (baby == null || baby.babyId != q.babyId) return const [];
    final l10n = lookupAppLocalizations(Locale(q.languageCode));
    final stages = lbVisibleStages(ref.watch(lbStagesProvider).value, baby);
    final articles = <LbArticle>[
      for (final a
          in ref.watch(lbArticlesProvider).value?.items ?? const <LbArticle>[])
        if (a.library == LbLibrary.care) a,
    ];
    final dob = baby.dob;
    final cards = <ForBabyCard>[];
    if (dob == null) {
      if (baby.canAddDob && stages.isNotEmpty) {
        cards.add(
          ForBabyCard(
            id: 'stage:no-dob',
            kicker: l10n.lbStagesTitle,
            title: l10n.lbNoDobTitle,
            action: l10n.lbNoDobAction,
            icon: ClIcons.cake,
            tone: ForBabyTone.sunshine,
            interest: Interest.milestones,
            onOpen: (context) =>
                context.push('${Routes.babyEdit}/${baby.babyId}'),
          ),
        );
      }
      return cards;
    }
    final stage = lbStageFor(stages, dob, baby.today);
    if (stage != null) {
      cards.add(
        ForBabyCard(
          id: 'stage:${stage.id}',
          kicker: l10n.lbTodayStageKicker(lbStageLabel(l10n, stage.age)),
          title: stage.title.pick(Locale(q.languageCode)),
          action: l10n.lbTodayStageAction,
          icon: ClIcons.cake,
          tone: ForBabyTone.sunshine,
          interest: Interest.milestones,
          onOpen: (context) => context.push(LbRoutes.stage(stage.id)),
        ),
      );
    }
    final weeks = lbAgeIn(LbUnit.week, dob, baby.today);
    for (final a in lbRecent(lbForAge(articles, weeks)).take(2)) {
      cards.add(
        ForBabyCard(
          id: 'article:${a.id}',
          kicker: [
            lbTopicLabel(l10n, a.topic),
            l10n.lbMinutes(a.readingMinutes),
          ].join(' · '),
          title: a.title.pick(Locale(q.languageCode)),
          action: l10n.lbTodayRead,
          icon: ClIcons.journal,
          tone: switch (a.topic) {
            LbTopic.sleep => ForBabyTone.sleep,
            LbTopic.feeding => ForBabyTone.peach,
            LbTopic.development => ForBabyTone.growth,
            _ => ForBabyTone.mint,
          },
          interest: switch (a.topic) {
            LbTopic.sleep => Interest.sleep,
            LbTopic.feeding => Interest.feeding,
            LbTopic.development => Interest.milestones,
            _ => null,
          },
          onOpen: (context) => context.push(LbRoutes.articleOf(a.id)),
        ),
      );
    }
    return cards;
  },
);
