import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart' show SafePush;
import '../../app/route_guard.dart';
import '../assistant/assistant_models.dart' show AssistantScope;
import '../assistant/assistant_screens.dart' show assistantLocation;
import '../memories/media_bytes.dart';
import '../memories/memory_models.dart';
import '../premium/billing_models.dart';
import '../premium/purchase_resume.dart';
import 'keepsake_card_view.dart';
import 'keepsake_catalog.dart';
import 'keepsake_occasions.dart';
import 'memory_story_screens.dart' show VideoDraft;
import 'milestone_card_screens.dart' show CardDraft;

/// MO03 / M17: card and video drafts kept across a purchase (`ResumeDrafts`), and the way back
/// to them once the purchase is verified and `getCapabilities` gives `templates.premium`.

/// Keeps [draft] for the purchase about to start; the record goes to `startPurchase`.
PurchaseResume keepCardDraft(WidgetRef ref, CardDraft draft) => PurchaseResume(
  kind: ResumeKind.card,
  templateId: draft.template.id,
  draftRef: ref.read(resumeDraftsProvider).keep(draft, cardDraftToJson(draft)),
);

PurchaseResume keepVideoDraft(WidgetRef ref, VideoDraft draft) =>
    PurchaseResume(
      kind: ResumeKind.video,
      templateId: draft.template.id,
      draftRef: ref
          .read(resumeDraftsProvider)
          .keep(draft, videoDraftToJson(draft)),
    );

Map<String, Object?> _palette(KeepsakePalette p) => {
  'background': p.background.toARGB32(),
  'ink': p.ink.toARGB32(),
  'accent': p.accent.toARGB32(),
};

KeepsakePalette? _paletteOf(Object? j) {
  if (j is! Map) return null;
  final b = j['background'], i = j['ink'], a = j['accent'];
  if (b is! int || i is! int || a is! int) return null;
  return KeepsakePalette(background: Color(b), ink: Color(i), accent: Color(a));
}

/// A card photo by where it lives: Kỷ niệm storage or a file picked from the phone.
Map<String, Object?>? _photo(CardPhoto? p) {
  if (p == null) return null;
  final where = switch (p.image) {
    StorageImage(:final path) => {'storage': path},
    FileImage(:final file) => {'file': file.path},
    _ => null,
  };
  if (where == null) return null;
  return {
    ...where,
    'x': p.align.x,
    'y': p.align.y,
    'zoom': p.zoom,
    'takenAt': p.takenAt?.toIso8601String(),
  };
}

CardPhoto? _photoOf(Object? j) {
  if (j is! Map) return null;
  final ImageProvider? image = j['storage'] is String
      ? StorageImage(j['storage'] as String)
      : j['file'] is String
      ? FileImage(File(j['file'] as String))
      : null;
  if (image == null) return null;
  return CardPhoto(
    image,
    align: Alignment(
      (j['x'] as num?)?.toDouble() ?? 0,
      (j['y'] as num?)?.toDouble() ?? 0,
    ),
    zoom: (j['zoom'] as num?)?.toDouble() ?? 1,
    takenAt: DateTime.tryParse('${j['takenAt']}'),
  );
}

Map<String, Object?> cardDraftToJson(CardDraft d) => {
  'babyId': d.babyId,
  'occasion': d.occasion.wire,
  'date': d.date.toIso8601String(),
  'format': d.format.name,
  'templateId': d.template.id,
  'palette': _palette(d.palette),
  'quote': d.quote,
  'photos': [for (final p in d.photos) _photo(p)],
  'slot': d.slot,
  // D-076 #14: the family milestone the card is for.
  'milestone': d.milestone?.toJson(),
  'ownTitle': d.ownTitle,
};

/// The card draft again, with its template from [catalog]; null when the template is gone.
CardDraft? cardDraftFromJson(Map<String, Object?> j, KeepsakeCatalog catalog) {
  final template = catalog.templates
      .where((t) => t.id == j['templateId'])
      .firstOrNull;
  final occasion = Occasion.fromWire(j['occasion'] as String?);
  final date = DateTime.tryParse('${j['date']}');
  final format = KeepsakeFormat.values.asNameMap()[j['format']];
  if (template == null ||
      occasion == null ||
      date == null ||
      format == null ||
      j['babyId'] is! String) {
    return null;
  }
  return CardDraft(
    babyId: j['babyId']! as String,
    occasion: occasion,
    date: date,
    format: format,
    template: template,
    palette: _paletteOf(j['palette']) ?? template.palette,
    quote: j['quote'] as String? ?? '',
    photos: [for (final p in (j['photos'] as List? ?? const [])) _photoOf(p)],
    slot: (j['slot'] as num?)?.toInt() ?? 0,
    milestone: MilestoneRef.fromJson(j['milestone']),
    ownTitle: j['ownTitle'] == true,
  );
}

Map<String, Object?> videoDraftToJson(VideoDraft d) => {
  'babyId': d.babyId,
  'templateId': d.template.id,
  'occasion': d.occasion?.wire,
  'mediaIds': d.mediaIds,
  'outputLocale': ?d.outputLocale,
  'title': d.title,
  'message': d.message,
  'audience': d.audience.name,
};

VideoDraft? videoDraftFromJson(
  Map<String, Object?> j,
  KeepsakeCatalog catalog,
) {
  final template = catalog.templates
      .where((t) => t.id == j['templateId'])
      .firstOrNull;
  if (template == null || j['babyId'] is! String) return null;
  return VideoDraft(
    babyId: j['babyId']! as String,
    template: template,
    occasion: Occasion.fromWire(j['occasion'] as String?),
    mediaIds: [
      for (final m in (j['mediaIds'] as List? ?? const []))
        if (m is String) m,
    ],
    outputLocale: j['outputLocale'] as String?,
    title: j['title'] as String?,
    message: j['message'] as String?,
    audience: Audience.values.asNameMap()[j['audience']] ?? Audience.parents,
  );
}

/// The template's name for PR02 Success: the kept draft's, else the catalog's.
String? resumeTemplateName(WidgetRef ref, PurchaseResume r, Locale locale) {
  final live = r.draftRef == null
      ? null
      : ref.read(resumeDraftsProvider).live(r.draftRef!);
  KeepsakeTemplate? fromCatalog() {
    try {
      return ref
          .read(keepsakeCatalogProvider)
          .value
          ?.templates
          .where((t) => t.id == r.templateId)
          .firstOrNull;
    } on Object {
      return null;
    }
  }

  final t = switch (live) {
    CardDraft(:final template) => template,
    VideoDraft(:final template) => template,
    _ => fromCatalog(),
  };
  return t?.name.of(locale);
}

/// The draft under [resume]: the live one of this run, else rebuilt from the saved copy.
Future<Object?> loadResumeDraft(
  ProviderContainer container,
  PurchaseResume resume,
) async {
  final key = resume.draftRef;
  if (key == null) return null;
  final drafts = container.read(resumeDraftsProvider);
  final live = drafts.live(key);
  if (live != null) return live;
  final saved = drafts.saved(key);
  if (saved == null) return null;
  // Listened while it loads: an unlistened stream provider is paused.
  final hold = container.listen(keepsakeCatalogProvider.future, (_, _) {});
  final KeepsakeCatalog catalog;
  try {
    catalog = await hold.read();
  } finally {
    hold.close();
  }
  return switch (resume.kind) {
    ResumeKind.card => cardDraftFromJson(saved, catalog),
    ResumeKind.video => videoDraftFromJson(saved, catalog),
    ResumeKind.rhythm || ResumeKind.assistant => null,
  };
}

/// Entry A after a purchase: Nhịp lớn lên (extract 30 open question, answered here), unless
/// the parent is already in it.
void landInRhythm(GoRouter router) {
  final here = router.routerDelegate.currentConfiguration.uri.path;
  if (here == Routes.rhythm || here.startsWith('${Routes.rhythm}/')) return;
  unawaited(router.push(Routes.rhythm));
}

/// After a verified purchase (PR02 "Tiếp tục") when no template flow is waiting for the paywall:
/// back to the exact template with the same photos (MO03), or Nhịp lớn lên for entry A. Without
/// the draft (cleared, template withdrawn) the template library opens, so nothing dead-ends.
Future<void> resumeAfterPurchase(
  GoRouter router,
  ProviderContainer container,
  PurchaseResume resume,
) async {
  if (resume.kind == ResumeKind.rhythm) {
    landInRhythm(router);
    return;
  }
  // The chat's kept question (CH23): back to that chat, which resumes it once.
  if (resume.kind == ResumeKind.assistant) {
    if (AssistantScope.fromKey(resume.draftRef) case final scope?) {
      unawaited(router.push(assistantLocation(scope)));
    }
    return;
  }
  final draft = await loadResumeDraft(container, resume);
  if (resume.draftRef case final key?) {
    container.read(resumeDraftsProvider).drop(key);
  }
  // D-076 nav: the paywall has just closed onto whatever opened it, possibly a page above the
  // tabs (MS01, a Nhịp lớn lên screen); these Kỷ niệm pages then open as overlay twins on top of
  // it (Back returns there), never as a second tab shell.
  switch (draft) {
    case CardDraft():
      container.read(justResumedProvider.notifier).set(draft.template.id);
      unawaited(router.pushSafe(Routes.milestoneCardEdit, extra: draft));
    case VideoDraft():
      container.read(justResumedProvider.notifier).set(draft.template.id);
      unawaited(router.pushSafe(Routes.memoryStoryPhotos, extra: draft));
    default:
      unawaited(
        router.pushSafe(
          resume.kind == ResumeKind.video
              ? Routes.memoryStory
              : Routes.milestoneCard,
        ),
      );
  }
}
