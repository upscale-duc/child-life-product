import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../app/route_guard.dart';
import '../../l10n/app_localizations.dart';
import '../keepsakes/keepsake_catalog.dart';
import '../keepsakes/keepsake_occasions.dart';
import '../keepsakes/keepsake_resume.dart' show keepCardDraft;
import '../keepsakes/milestone_card_screens.dart';
import '../baby/baby_repository.dart' show babyPrivateProfileProvider;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../memories/memory_models.dart';
import '../memories/memory_repository.dart' show mediaProvider;
import '../premium/premium_gate.dart' show ensureTemplateAllowed;
import '../rhythm/milestone_screen.dart' show occasionFor;

/// Thiệp cột mốc for a family milestone (D-076 #14): from MS01 "Giữ khoảnh khắc này?" and from
/// a saved Mốc phát triển record. Opens MM11 (the editor) with a template of the chosen tier and
/// the milestone preselected (its day, its tagged photos first, the saved card tagged with it);
/// a Cao cấp template goes through MO02 first (`ensureTemplateAllowed`): a family with
/// `templates.premium` (beta or paid) goes straight on, one without it gets the honest gate and
/// stays where it was, where the Cơ bản card is still one tap away. Without a tier (or a template
/// of it) the template library (MM10) opens, with the milestone kept.
///
/// [navigate] opens a location in the Kỷ niệm tab: from a screen above the tab shell (MS01) it
/// must leave that screen first (`closeFlow`), never push the tab's page on top of it.
typedef CardNavigate = void Function(String location, Object? extra);

/// The Thiệp cột mốc occasion of a family milestone: the one whose preset it is (`p_rolls_over`),
/// else the one its words name ("lần đầu lẫy"), else none (a custom card with its own title).
Occasion? occasionForMilestone(MilestoneRef m) =>
    Occasion.values.where((o) => o.milestoneId == m.id).firstOrNull ??
    occasionFor(m.name);

/// MM10 with the milestone's occasion chosen.
String cardLibraryLocation(MilestoneRef m) {
  final o = occasionForMilestone(m);
  return o == null
      ? Routes.milestoneCard
      : '${Routes.milestoneCard}?occasion=${o.wire}';
}

/// The family's card templates of one tier, best first (portrait, the format every card has).
KeepsakeTemplate? cardTemplateOf(
  KeepsakeCatalog? catalog, {
  required bool premium,
}) => catalog?.cards
    .where(
      (t) =>
          t.premium == premium &&
          t.layouts.containsKey(KeepsakeFormat.portrait),
    )
    .firstOrNull;

/// The first value of [provider], listened while it loads (an unlistened stream provider is
/// paused); null after a few seconds without one (offline with nothing cached).
Future<T?> _first<T>(
  WidgetRef ref,
  ProviderListenable<Future<T>> provider,
) async {
  final hold = ref.listenManual(provider, (_, _) {});
  try {
    return await hold.read().timeout(const Duration(seconds: 4));
  } on Object {
    return null;
  } finally {
    hold.close();
  }
}

/// Opens the card for [milestone]: [premium] null → MM10; else MM11 with that tier.
Future<void> openMilestoneCard(
  BuildContext context,
  WidgetRef ref, {
  required MilestoneRef milestone,
  required bool? premium,
  required CardNavigate navigate,
}) async {
  final l10n = AppLocalizations.of(context);
  final library = cardLibraryLocation(milestone);
  if (premium == null) {
    navigate(library, milestone);
    return;
  }
  // Read, never watched: this runs from a tap, not while building.
  final me = ref.read(selectedMembershipProvider);
  final dob = me != null && me.canViewBabyInfo
      ? (await _first(
          ref,
          babyPrivateProfileProvider(me.babyId).future,
        ))?.dateOfBirth
      : null;
  if (!context.mounted) return;
  if (me == null || dob == null) {
    navigate(library, milestone);
    return;
  }
  final catalog = await _first(ref, keepsakeCatalogProvider.future);
  if (!context.mounted) return;
  final template = cardTemplateOf(catalog, premium: premium);
  if (template == null) {
    navigate(library, milestone);
    return;
  }
  final media =
      await _first(ref, mediaProvider((me.babyId, true)).future) ??
      const <MediaItem>[];
  if (!context.mounted) return;
  final fits = occasionForMilestone(milestone);
  // No occasion fits (a custom milestone): the card says its own name.
  final own = fits == null;
  final occasion = fits ?? suggestedOccasion(dob, milestone.date);
  final draft = CardDraft(
    babyId: me.babyId,
    occasion: occasion,
    date: milestone.date,
    format: KeepsakeFormat.portrait,
    template: template,
    palette: template.palette,
    quote: own ? l10n.ksAchieveAny : occasion.quote(l10n),
    photos: [
      for (final m in defaultPhotos(
        media,
        occasion,
        milestone.date,
        count: template.photosMax,
        milestoneId: milestone.id,
      ))
        photoOf(m),
    ],
    milestone: milestone,
    ownTitle: own,
  );
  final ok = await ensureTemplateAllowed(
    context,
    ref,
    template: template,
    catalog: catalog,
    babyId: me.babyId,
    // MO03: the same template, photos and milestone after a purchase.
    keep: () => keepCardDraft(ref, draft),
  );
  if (!ok || !context.mounted) return;
  navigate(Routes.milestoneCardEdit, draft);
}
