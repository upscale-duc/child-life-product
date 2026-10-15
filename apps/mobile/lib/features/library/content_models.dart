import 'package:flutter/widgets.dart';

import '../baby/baby_models.dart' show MemberRole;

/// Thư viện chăm bé (Figma v1.1 4a–4f) and Giai đoạn của bé (2a–2c, formerly "Thẻ theo tuổi",
/// renamed by D-076 #5): editorial content written in the portal and published one document per
/// item to `contentArticles/{id}` and `contentStages/{id}` (shapes: `contentArticleSchema` and
/// `contentStageSchema` in `packages/contracts/src/content.ts`).
///
/// Bodies are a closed set of plain-text blocks (paragraph, heading, bullets, callout, image): no
/// HTML, no WebView, no links the app did not build. An unknown block is dropped on its own, so an
/// older app still reads the rest; an item missing its essentials is skipped. Nothing here is
/// about a child.

/// A text in both app languages (D-012).
@immutable
class LbText {
  const LbText(this.vi, this.en);
  final String vi;
  final String en;

  String of(BuildContext context) => pick(Localizations.localeOf(context));

  /// The reader's language, else the other one.
  String pick(Locale locale) {
    final en = locale.languageCode == 'en';
    final first = en ? this.en : vi;
    return first.isNotEmpty ? first : (en ? vi : this.en);
  }

  static LbText? parse(Object? j) {
    if (j is! Map) return null;
    final vi = j['vi'] is String ? (j['vi'] as String).trim() : '';
    final en = j['en'] is String ? (j['en'] as String).trim() : '';
    if (vi.isEmpty && en.isEmpty) return null;
    return LbText(vi, en);
  }
}

/// `{vi: [...], en: [...]}` lists ("Bé đang thế nào", keywords).
@immutable
class LbTextList {
  const LbTextList(this.vi, this.en);
  final List<String> vi;
  final List<String> en;

  static const empty = LbTextList([], []);

  List<String> pick(Locale locale) {
    final en = locale.languageCode == 'en';
    final first = en ? this.en : vi;
    return first.isNotEmpty ? first : (en ? vi : this.en);
  }

  static LbTextList parse(Object? j) {
    if (j is! Map) return empty;
    List<String> of(Object? v) => [
      if (v is List)
        for (final s in v)
          if (s is String && s.trim().isNotEmpty) s.trim(),
    ];
    return LbTextList(of(j['vi']), of(j['en']));
  }
}

/// The six topics of 4a in order (`articleTopics`); the colours and icons are the app's.
enum LbTopic {
  feeding('feeding'),
  sleep('sleep'),
  teething('teething'),
  illness('illness'),
  dailyCare('daily_care'),
  development('development');

  const LbTopic(this.wire);
  final String wire;

  static LbTopic? parse(Object? j) =>
      values.where((t) => t.wire == j).firstOrNull;
}

/// `contentLibraries`: Chăm bé, Ăn dặm (5f, not built in the app yet).
enum LbLibrary { care, solids }

/// Who signed the item off (`contentReviewSchema`); null = engineering draft (D-073 #2).
@immutable
class LbReview {
  const LbReview({
    required this.reviewer,
    required this.credential,
    required this.reviewedOn,
  });
  final String reviewer;
  final String credential;
  final DateTime reviewedOn;

  static LbReview? parse(Object? j) {
    if (j is! Map) return null;
    final reviewer = j['reviewer'];
    final credential = j['credential'];
    final on = j['reviewedOn'] is String
        ? DateTime.tryParse(j['reviewedOn'] as String)
        : null;
    if (reviewer is! String ||
        reviewer.isEmpty ||
        credential is! String ||
        on == null) {
      return null;
    }
    return LbReview(reviewer: reviewer, credential: credential, reviewedOn: on);
  }
}

@immutable
class LbSource {
  const LbSource(this.label, this.url);
  final String label;
  final String url;

  static List<LbSource> list(Object? j) => [
    if (j is List)
      for (final s in j)
        if (s is Map && s['label'] is String && s['url'] is String)
          LbSource(s['label'] as String, s['url'] as String),
  ];
}

/// An image in `content/library/{id}.webp` with its alt text.
@immutable
class LbImage {
  const LbImage(this.id, this.alt);
  final String id;
  final LbText? alt;

  static final _id = RegExp(r'^[a-z0-9-]{2,48}_[a-f0-9]{8}$');
  static bool validId(Object? id) => id is String && _id.hasMatch(id);

  static LbImage? parse(Object? j) {
    if (j is! Map || !validId(j['image'])) return null;
    return LbImage(j['image'] as String, LbText.parse(j['alt']));
  }
}

// ---------- Body blocks (4d) ----------

/// `calloutTones`: "Khi nào nên hỏi bác sĩ" (sunshine), a plain note, a tip.
enum LbCalloutTone { doctor, note, tip }

@immutable
sealed class LbBlock {
  const LbBlock();

  /// One language's block; unknown or malformed blocks are null and skipped.
  static LbBlock? parse(Object? j) {
    if (j is! Map) return null;
    String? s(String k) {
      final v = j[k];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    switch (j['type']) {
      case 'paragraph':
        final t = s('text');
        return t == null ? null : LbParagraph(t);
      case 'heading':
        final t = s('text');
        return t == null ? null : LbHeading(t);
      case 'bullets':
        final items = [
          if (j['items'] is List)
            for (final i in j['items']! as List)
              if (i is String && i.trim().isNotEmpty) i.trim(),
        ];
        return items.isEmpty ? null : LbBullets(items);
      case 'callout':
        final t = s('text');
        if (t == null) return null;
        final tone = switch (j['tone']) {
          'note' => LbCalloutTone.note,
          'tip' => LbCalloutTone.tip,
          _ => LbCalloutTone.doctor,
        };
        return LbCallout(tone: tone, title: s('title'), text: t);
      case 'image':
        if (!LbImage.validId(j['image'])) return null;
        return LbFigure(
          image: j['image']! as String,
          caption: s('caption'),
          alt: s('alt'),
        );
    }
    return null;
  }
}

class LbParagraph extends LbBlock {
  const LbParagraph(this.text);
  final String text;
}

class LbHeading extends LbBlock {
  const LbHeading(this.text);
  final String text;
}

class LbBullets extends LbBlock {
  const LbBullets(this.items);
  final List<String> items;
}

class LbFigure extends LbBlock {
  const LbFigure({required this.image, this.caption, this.alt});
  final String image;
  final String? caption;
  final String? alt;
}

class LbCallout extends LbBlock {
  const LbCallout({required this.tone, required this.text, this.title});
  final LbCalloutTone tone;
  final String? title;
  final String text;
}

// ---------- Articles (4a–4f) ----------

final _articleId = RegExp(r'^art_[a-z0-9_]{2,60}$');
final _stageId = RegExp(r'^stg_[a-z0-9_]{2,40}$');
final _milestoneId = RegExp(r'^[a-z][a-z0-9_]{1,63}$');

bool lbArticleId(String id) => _articleId.hasMatch(id);

/// Ages in completed weeks from the date of birth, `to` exclusive (`ageWeeks`).
@immutable
class LbWeeks {
  const LbWeeks(this.from, this.to);
  final int from;
  final int to;

  /// 4b: an article matches an age band when the ranges overlap.
  bool overlaps(int from, int to) => this.from < to && from < this.to;

  bool holds(int weeks) => weeks >= from && weeks < to;
}

@immutable
class LbArticle {
  const LbArticle({
    required this.id,
    required this.library,
    required this.topic,
    required this.weeks,
    required this.readingMinutes,
    required this.title,
    required this.body,
    this.summary,
    this.cover,
    this.keywords = LbTextList.empty,
    this.related = const [],
    this.milestoneIds = const [],
    this.sources = const [],
    this.review,
    this.illustrative = true,
    this.revision = 1,
    this.publishedAt,
    this.firstPublishedAt,
  });

  final String id;
  final LbLibrary library;
  final LbTopic topic;
  final LbWeeks weeks;
  final int readingMinutes;
  final LbText title;
  final LbText? summary;
  final LbImage? cover;

  /// Blocks per language (`body.vi`, `body.en`).
  final ({List<LbBlock> vi, List<LbBlock> en}) body;
  final LbTextList keywords;
  final List<String> related;
  final List<String> milestoneIds;
  final List<LbSource> sources;
  final LbReview? review;

  /// "Nội dung minh hoạ · chờ chuyên môn duyệt" until a qualified reviewer signs it.
  final bool illustrative;

  /// Grows on every publish: the 4f "đã được cập nhật" banner compares it with the saved one.
  final int revision;
  final DateTime? publishedAt;

  /// "Mới cập nhật" sorts by the latest publish; this is the first.
  final DateTime? firstPublishedAt;

  List<LbBlock> blocksFor(Locale locale) {
    final en = locale.languageCode == 'en';
    final first = en ? body.en : body.vi;
    return first.isNotEmpty ? first : (en ? body.vi : body.en);
  }

  /// Everything searchable, both languages.
  Iterable<String> searchTexts() sync* {
    yield* [title.vi, title.en];
    if (summary != null) yield* [summary!.vi, summary!.en];
    yield* keywords.vi;
    yield* keywords.en;
    for (final b in [...body.vi, ...body.en]) {
      switch (b) {
        case LbParagraph(:final text) || LbHeading(:final text):
          yield text;
        case LbBullets(:final items):
          yield* items;
        case LbCallout(:final text, :final title):
          yield text;
          if (title != null) yield title;
        case LbFigure(:final caption):
          if (caption != null) yield caption;
      }
    }
  }

  /// A published article the app can show, else null.
  static LbArticle? fromDoc(String id, Map<String, Object?>? j) {
    if (j == null || !_articleId.hasMatch(id)) return null;
    if (j['status'] != 'published') return null;
    final title = LbText.parse(j['title']);
    final topic = LbTopic.parse(j['topic']);
    final age = j['ageWeeks'];
    final minutes = j['readingMinutes'];
    if (title == null || topic == null || age is! Map) return null;
    final from = age['from'];
    final to = age['to'];
    if (from is! num || to is! num || to <= from) return null;
    final body = j['body'] is Map ? j['body']! as Map : const {};
    List<LbBlock> blocks(Object? v) => [
      if (v is List)
        for (final b in v) ?LbBlock.parse(b),
    ];
    final review = LbReview.parse(j['review']);
    final revision = j['revision'];
    return LbArticle(
      id: id,
      library: j['library'] == 'solids' ? LbLibrary.solids : LbLibrary.care,
      topic: topic,
      weeks: LbWeeks(from.toInt(), to.toInt()),
      readingMinutes: minutes is num && minutes >= 1 ? minutes.toInt() : 1,
      title: title,
      summary: LbText.parse(j['summary']),
      cover: LbImage.parse(j['cover']),
      body: (vi: blocks(body['vi']), en: blocks(body['en'])),
      keywords: LbTextList.parse(j['keywords']),
      related: [
        if (j['relatedArticleIds'] is List)
          for (final r in j['relatedArticleIds']! as List)
            if (r is String && _articleId.hasMatch(r) && r != id) r,
      ],
      milestoneIds: [
        if (j['milestoneIds'] is List)
          for (final r in j['milestoneIds']! as List)
            if (r is String && _milestoneId.hasMatch(r)) r,
      ],
      sources: LbSource.list(j['sources']),
      review: review,
      // Never trust a "reviewed" flag without the review itself (P-141).
      illustrative: j['illustrative'] != false || review == null,
      revision: revision is num ? revision.toInt() : 1,
      publishedAt: lbDate(j['publishedAt']),
      firstPublishedAt: lbDate(j['firstPublishedAt']),
    );
  }
}

/// ISO timestamp, DateTime or Firestore Timestamp.
DateTime? lbDate(Object? j) {
  if (j is DateTime) return j;
  if (j is String) return DateTime.tryParse(j);
  if (j == null) return null;
  try {
    // ignore: avoid_dynamic_calls
    final d = (j as dynamic).toDate();
    return d is DateTime ? d : null;
  } on Object {
    return null;
  }
}

// ---------- Stages: Giai đoạn của bé (2a / 2b) ----------

enum LbUnit { week, month }

/// Completed weeks or months from the date of birth, `to` exclusive (`stageAgeSchema`).
@immutable
class LbStageAge {
  const LbStageAge(this.unit, this.from, this.to);
  final LbUnit unit;
  final int from;
  final int to;

  /// The last included value: "0–2 tuần" for weeks 0..2 (`stageAgeLabel`).
  int get last => to - 1;

  static const _daysPerMonth = 30.4375;

  /// Approximate day span (`stageAgeDays`), for ordering and the narrowest match.
  ({double from, double to}) get days {
    final k = unit == LbUnit.week ? 7.0 : _daysPerMonth;
    return (from: from * k, to: to * k);
  }
}

@immutable
class LbStage {
  const LbStage({
    required this.id,
    required this.age,
    required this.title,
    this.doing = LbTextList.empty,
    this.tryThis = LbTextList.empty,
    this.articleIds = const [],
    this.milestoneIds = const [],
    this.audience = const {...MemberRole.values},
    this.cover,
    this.sources = const [],
    this.review,
    this.illustrative = true,
    this.revision = 1,
    this.publishedAt,
  });

  final String id;
  final LbStageAge age;
  final LbText title;

  /// "Bé đang thế nào" (≤ 3).
  final LbTextList doing;

  /// "Ba mẹ có thể thử" (≤ 3).
  final LbTextList tryThis;
  final List<String> articleIds;
  final List<String> milestoneIds;

  /// B06 "Hiện với": the roles that see this stage.
  final Set<MemberRole> audience;
  final LbImage? cover;
  final List<LbSource> sources;
  final LbReview? review;
  final bool illustrative;
  final int revision;
  final DateTime? publishedAt;

  static LbStage? fromDoc(String id, Map<String, Object?>? j) {
    if (j == null || !_stageId.hasMatch(id)) return null;
    if (j['status'] != 'published') return null;
    final title = LbText.parse(j['title']);
    final age = j['age'];
    if (title == null || age is! Map) return null;
    final unit = switch (age['unit']) {
      'week' => LbUnit.week,
      'month' => LbUnit.month,
      _ => null,
    };
    final from = age['from'];
    final to = age['to'];
    if (unit == null || from is! num || to is! num || to <= from) return null;
    final review = LbReview.parse(j['review']);
    final revision = j['revision'];
    final audience = {
      if (j['audience'] is List)
        for (final r in j['audience']! as List)
          ?MemberRole.values.where((m) => m.name == r).firstOrNull,
    };
    return LbStage(
      id: id,
      age: LbStageAge(unit, from.toInt(), to.toInt()),
      title: title,
      doing: LbTextList.parse(j['doing']),
      tryThis: LbTextList.parse(j['tryThis']),
      articleIds: [
        if (j['articleIds'] is List)
          for (final r in j['articleIds']! as List)
            if (r is String && _articleId.hasMatch(r)) r,
      ],
      milestoneIds: [
        if (j['milestoneIds'] is List)
          for (final r in j['milestoneIds']! as List)
            if (r is String && _milestoneId.hasMatch(r)) r,
      ],
      audience: audience.isEmpty ? {...MemberRole.values} : audience,
      cover: LbImage.parse(j['cover']),
      sources: LbSource.list(j['sources']),
      review: review,
      illustrative: j['illustrative'] != false || review == null,
      revision: revision is num ? revision.toInt() : 1,
      publishedAt: lbDate(j['publishedAt']),
    );
  }
}
