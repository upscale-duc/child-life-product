import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/route_guard.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../keepsakes/keepsake_nudges.dart';
import '../nutrition/nutrition_routes.dart';
import '../nutrition/nutrition_state.dart';
import '../solids/solids_personal.dart';
import '../solids/solids_routes.dart';
import '../solids/solids_suggest.dart';
import '../today/today_for_baby.dart';
import '../vaccines/vaccine_format.dart';
import 'personalization_v2_repository.dart';
import 'rhythm_models.dart';
import 'rhythm_repository.dart';
import 'rhythm_access.dart';

/// P-172 F1: compose local module results; no meal payload leaves the device for ranking.
final personalizedSourceCardsProvider =
    Provider.family<List<ForBabyCard>, ForBabyQuery>((ref, query) {
      final me = ref.watch(selectedMembershipProvider);
      if (me == null ||
          me.babyId != query.babyId ||
          me.uid != query.uid ||
          !familyCan(me, FamilyAction.historyRead)) {
        return [];
      }
      final locale = Locale(query.languageCode);
      final l = lookupAppLocalizations(locale);
      final day = ref
          .watch(
            personalDayProvider((
              babyId: query.babyId,
              uid: query.uid,
              locale: query.languageCode,
            )),
          )
          .value;
      final cards = <ForBabyCard>[];
      if (day != null) {
        if (day.health) {
          return [
            ForBabyCard(
              id: 'health:today',
              kicker: l.rhHealthCardTitle,
              title: l.rhHealthCardBody,
              action: l.rhHealthCardAction,
              priority: 0,
              essential: true,
              icon: ClIcons.alert,
              onOpen: (c) => c.push(Routes.rhythmHealth),
            ),
          ];
        }
        for (final work
            in day.work
                .where(
                  (w) =>
                      DateTime.tryParse(
                        '${w['dueAt']}',
                      )?.isBefore(DateTime.parse('${day.data['expiresAt']}')) ??
                      false,
                )
                .take(1)) {
          cards.add(
            ForBabyCard(
              id: 'work:${work['id']}',
              kicker: l.pv2Work,
              title: '${work['title']}',
              action: l.pv2Open,
              priority: 1,
              essential: true,
              icon: ClIcons.clock,
              onOpen: (c) => c.push(Routes.personalDay),
            ),
          );
        }
        final content = ref.watch(rhythmContentProvider).value;
        for (final id in day.activityIds) {
          final a = content?.activity(id);
          if (a == null ||
              a.status != ContentStatus.published ||
              day.data['contentVersion'] != content?.version) {
            continue;
          }
          cards.add(
            ForBabyCard(
              id: id,
              kicker: '${a.durationMin} ${l.pv2Minutes}',
              title: a.title.of(locale),
              action: l.pv2OpenActivity,
              priority: 2,
              interest: a.interests.firstOrNull,
              onOpen: (c) => c.push('${Routes.rhythmActivity}/$id'),
            ),
          );
        }
        if (day.patterns.isNotEmpty) {
          final p = day.patterns.first;
          cards.add(
            ForBabyCard(
              id: 'pattern:${p['kind']}',
              kicker: l.pv2Patterns,
              title: '${p['lowMinutes']}–${p['highMinutes']} ${l.pv2Minutes}',
              action: l.pv2Open,
              priority: 3,
              icon: ClIcons.clock,
              onOpen: (c) => c.push(Routes.personalDay),
            ),
          );
        }
      }
      final solids = ref
          .watch(sdSuggestionsProvider(query.languageCode))
          .firstOrNull;
      if (solids != null) {
        cards.add(
          ForBabyCard(
            id: 'solids:${solids.id}',
            kicker: l.sdSectionToday,
            title: solids.title,
            action: solids.action,
            priority: solids.card.rule == SdRule.s1 ? 0 : 2,
            essential: solids.card.rule == SdRule.s1,
            interest: Interest.feeding,
            icon: ClIcons.feed,
            onOpen: (c) => c.push(SdRoutes.home),
          ),
        );
      }
      final nutrition = ref.watch(nuDataProvider);
      final rule =
          nutrition?.signals.growth.firstOrNull ??
          nutrition?.signals.milk ??
          nutrition?.signals.noMeasurement;
      if (rule != null) {
        cards.add(
          ForBabyCard(
            id: 'nutrition:${rule.id}',
            kicker: l.nuTitle,
            title: rule.banner.pick(locale),
            action: l.pv2Open,
            priority: 2,
            interest: Interest.nutrition,
            icon: ClIcons.ruler,
            onOpen: (c) => c.push(
              rule.isGrowth ? NuRoutes.growth(rule.id) : NuRoutes.home,
            ),
          ),
        );
      }
      final vaccines = ref.watch(vaccineBookProvider(me));
      if (vaccines is VaccineBookReady) {
        final group = vaccines.book.nextGroup;
        if (group != null &&
            group.date.difference(vaccines.book.today).inDays <= 7) {
          cards.add(
            ForBabyCard(
              id: 'vaccine:${group.months}',
              kicker: l.vxTitle,
              title: vxGroupLine(
                l,
                query.languageCode,
                group.items,
                vaccines.book.plan,
              ),
              action: l.pv2Open,
              priority: 1,
              essential: true,
              interest: Interest.vaccines,
              icon: ClIcons.bell,
              onOpen: (c) => c.push('${Routes.vaccineAge}/${group.months}'),
            ),
          );
        }
      }
      for (final nudge
          in ref
              .watch(nudgePlanProvider)
              .nudges
              .where((n) => n.babyId == query.babyId)
              .take(1)) {
        cards.add(
          ForBabyCard(
            id: 'occasion:${nudge.occasion.wire}',
            kicker: l.ksNudgeTodayBody,
            title: nudge.occasion.title(l),
            action: l.pv2Open,
            priority: 5,
            interest: Interest.moments,
            icon: ClIcons.heart,
            onOpen: (c) => c.push(
              nudge.kind == NudgeKind.lookBack
                  ? Routes.memories
                  : '${Routes.milestoneCard}?occasion=${nudge.occasion.wire}',
            ),
          ),
        );
      }
      return cards;
    });
