import 'content_models.dart';

/// Pure rules of Thư viện chăm bé and Giai đoạn của bé, mirroring `content.ts` so the app and
/// the server agree on ages (`ageInUnit`, `stageFor`, `sortStages`, `articleOverlapsWeeks`).

/// Completed weeks or calendar months between [dob] and [today] (local dates), at least 0.
/// A month is complete on the same day of the month, or the month's last day when shorter.
int lbAgeIn(LbUnit unit, DateTime dob, DateTime today) {
  final b = DateTime.utc(dob.year, dob.month, dob.day);
  final t = DateTime.utc(today.year, today.month, today.day);
  final days = t.difference(b).inDays;
  if (days <= 0) return 0;
  if (unit == LbUnit.week) return days ~/ 7;
  var months = (t.year - b.year) * 12 + (t.month - b.month);
  final lastOfThisMonth = DateTime.utc(t.year, t.month + 1, 0).day;
  if (t.day < (b.day < lastOfThisMonth ? b.day : lastOfThisMonth)) months -= 1;
  return months < 0 ? 0 : months;
}

bool lbStageHolds(LbStage s, DateTime dob, DateTime today) {
  if (DateTime(
    today.year,
    today.month,
    today.day,
  ).isBefore(DateTime(dob.year, dob.month, dob.day))) {
    return false;
  }
  final n = lbAgeIn(s.age.unit, dob, today);
  return n >= s.age.from && n < s.age.to;
}

/// 2a "Bé đang ở đây": the narrowest stage holding the age, then the later start.
LbStage? lbStageFor(List<LbStage> stages, DateTime dob, DateTime today) {
  final hits = [
    for (final s in stages)
      if (lbStageHolds(s, dob, today)) s,
  ];
  hits.sort((a, b) {
    final x = a.age.days;
    final y = b.age.days;
    final byWidth = (x.to - x.from).compareTo(y.to - y.from);
    return byWidth != 0 ? byWidth : y.from.compareTo(x.from);
  });
  return hits.firstOrNull;
}

/// 2a order: by start age, then by end.
List<LbStage> lbSortStages(Iterable<LbStage> stages) =>
    [...stages]..sort((a, b) {
      final x = a.age.days;
      final y = b.age.days;
      final byFrom = x.from.compareTo(y.from);
      return byFrom != 0 ? byFrom : x.to.compareTo(y.to);
    });

/// Where a stage sits against the baby's age (2a: past rows are muted).
enum LbStageTime { past, current, future }

LbStageTime lbStageTime(
  LbStage s,
  LbStage? current,
  DateTime dob,
  DateTime today,
) {
  if (current != null && s.id == current.id) return LbStageTime.current;
  final n = lbAgeIn(s.age.unit, dob, today);
  return n >= s.age.to ? LbStageTime.past : LbStageTime.future;
}

// ---------- 4b / 4c search and filters ----------

/// 4c "Độ tuổi": 0–3, 3–6, 6–12 tháng, 1–2 tuổi, in completed weeks (`to` exclusive).
enum LbAgeBand {
  m0to3(0, 13),
  m3to6(13, 26),
  m6to12(26, 52),
  y1to2(52, 104);

  const LbAgeBand(this.fromWeeks, this.toWeeks);
  final int fromWeeks;
  final int toWeeks;
}

/// 4c "Thời gian đọc": under 3, 3–6, over 6 minutes.
enum LbReadTime {
  short,
  medium,
  long;

  bool holds(int minutes) => switch (this) {
    LbReadTime.short => minutes < 3,
    LbReadTime.medium => minutes >= 3 && minutes <= 6,
    LbReadTime.long => minutes > 6,
  };
}

enum LbSort { relevant, newest, shortest }

/// What 4b shows: a query and the 4c facets (several values in one facet = any of them).
class LbFilter {
  const LbFilter({
    this.query = '',
    this.topics = const {},
    this.ages = const {},
    this.times = const {},
    this.sort = LbSort.relevant,
  });

  final String query;
  final Set<LbTopic> topics;
  final Set<LbAgeBand> ages;
  final Set<LbReadTime> times;
  final LbSort sort;

  int get count => topics.length + ages.length + times.length;
  bool get isEmpty => query.trim().isEmpty && count == 0;

  LbFilter copyWith({
    String? query,
    Set<LbTopic>? topics,
    Set<LbAgeBand>? ages,
    Set<LbReadTime>? times,
    LbSort? sort,
  }) => LbFilter(
    query: query ?? this.query,
    topics: topics ?? this.topics,
    ages: ages ?? this.ages,
    times: times ?? this.times,
    sort: sort ?? this.sort,
  );

  bool matchesFacets(LbArticle a) =>
      (topics.isEmpty || topics.contains(a.topic)) &&
      (ages.isEmpty ||
          ages.any((b) => a.weeks.overlaps(b.fromWeeks, b.toWeeks))) &&
      (times.isEmpty || times.any((t) => t.holds(a.readingMinutes)));

  /// Matching articles, best first.
  List<LbArticle> apply(Iterable<LbArticle> articles) {
    final words = lbFold(query).split(' ').where((w) => w.isNotEmpty).toList();
    final scored = <(LbArticle, int)>[];
    for (final a in articles) {
      if (!matchesFacets(a)) continue;
      if (words.isEmpty) {
        scored.add((a, 0));
        continue;
      }
      final score = lbScore(a, words);
      if (score > 0) scored.add((a, score));
    }
    int newest(LbArticle a, LbArticle b) => (b.publishedAt ?? DateTime(2000))
        .compareTo(a.publishedAt ?? DateTime(2000));
    scored.sort(
      (x, y) => switch (sort) {
        LbSort.relevant =>
          y.$2 != x.$2 ? y.$2.compareTo(x.$2) : newest(x.$1, y.$1),
        LbSort.newest => newest(x.$1, y.$1),
        LbSort.shortest =>
          x.$1.readingMinutes != y.$1.readingMinutes
              ? x.$1.readingMinutes.compareTo(y.$1.readingMinutes)
              : newest(x.$1, y.$1),
      },
    );
    return [for (final (a, _) in scored) a];
  }
}

/// Every query word must appear somewhere; title and keyword hits weigh more than the body.
int lbScore(LbArticle a, List<String> words) {
  // Padded so a query word matches the start of a word ("ngu" finds "ngủ", not "nhũng").
  final title = ' ${lbFold('${a.title.vi} ${a.title.en}')}';
  final keys = ' ${lbFold([...a.keywords.vi, ...a.keywords.en].join(' '))}';
  final rest = ' ${lbFold(a.searchTexts().join(' '))}';
  var score = 0;
  for (final word in words) {
    final w = ' $word';
    if (title.contains(w)) {
      score += 5;
    } else if (keys.contains(w)) {
      score += 3;
    } else if (rest.contains(w)) {
      score += 1;
    } else {
      return 0;
    }
  }
  return score;
}

const _marks = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final _fold = {
  for (final MapEntry(:key, :value) in _marks.entries)
    for (final c in value.split('')) c: key,
};

final _word = RegExp(r'^[a-z0-9]$');

/// Lower case, without Vietnamese marks, punctuation as spaces: "Ngủ ngày" finds "ngu ngay".
String lbFold(String s) {
  final out = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final f = _fold[c] ?? c;
    out.write(_word.hasMatch(f) ? f : ' ');
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// "Hợp với {bé}" (4a): care articles whose range holds the age in completed weeks.
List<LbArticle> lbForAge(Iterable<LbArticle> articles, int weeks) => [
  for (final a in articles)
    if (a.weeks.holds(weeks)) a,
];

/// "Mới cập nhật" (4a): latest publish first.
List<LbArticle> lbRecent(Iterable<LbArticle> articles) => [...articles]
  ..sort(
    (a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(
      a.publishedAt ?? DateTime(2000),
    ),
  );

/// 4d "Bài tiếp theo" (D-087, P-166 #3g): the guide after [a] in its library and age band, in
/// reading order (the Ăn dặm group, then the topic, the age, the first publish). The band is the
/// one of [bands] (`[from, to)` weeks) that holds the article's first week; the order wraps
/// around, and guides in [skip] (the related list already shown) are passed over. Null when the
/// band has no other guide.
LbArticle? lbNextGuide(
  Iterable<LbArticle> all,
  LbArticle a, {
  required List<(int, int)> bands,
  Set<String> skip = const {},
}) {
  final band = bands
      .where((b) => a.weeks.from >= b.$1 && a.weeks.from < b.$2)
      .firstOrNull;
  bool inBand(LbArticle x) => band == null
      ? x.weeks.overlaps(a.weeks.from, a.weeks.to)
      : x.weeks.from >= band.$1 && x.weeks.from < band.$2;
  final order = [
    for (final x in all)
      if (x.library == a.library && (x.id == a.id || inBand(x))) x,
  ]..sort(_readingOrder);
  final at = order.indexWhere((x) => x.id == a.id);
  if (at < 0) return null;
  for (var i = 1; i < order.length; i++) {
    final next = order[(at + i) % order.length];
    if (!skip.contains(next.id)) return next;
  }
  return null;
}

int _readingOrder(LbArticle x, LbArticle y) {
  final far = DateTime(9999);
  for (final c in [
    (x.subtopic?.index ?? 99).compareTo(y.subtopic?.index ?? 99),
    x.topic.index.compareTo(y.topic.index),
    x.weeks.from.compareTo(y.weeks.from),
    (x.firstPublishedAt ?? far).compareTo(y.firstPublishedAt ?? far),
  ]) {
    if (c != 0) return c;
  }
  return x.id.compareTo(y.id);
}

// ---------- 4d reading layouts (D-087, P-166 #3) ----------

/// A "Hiểu lầm thường gặp" bullet: "A → B → C" is the myth, why it is wrong and what to do
/// instead; "A → B" the myth and what to do instead. Null for any other bullet.
({String myth, String? why, String instead})? lbMyth(String item) {
  final parts = [for (final p in item.split('→')) p.trim()];
  if (parts.length < 2 || parts.length > 3 || parts.any((p) => p.isEmpty)) {
    return null;
  }
  return parts.length == 3
      ? (myth: parts[0], why: parts[1], instead: parts[2])
      : (myth: parts[0], why: null, instead: parts[1]);
}

final _step = RegExp(r'^(?:Bước|Step)\s+(\d{1,2})\s*·\s*(\S.*)$', dotAll: true);

/// A step-guide bullet "Bước 3 · …" (en "Step 3 · …"): its number and the rest.
({int n, String text})? lbStep(String item) {
  final m = _step.firstMatch(item);
  return m == null ? null : (n: int.parse(m.group(1)!), text: m.group(2)!);
}

final _leadIn = RegExp(r'^([^:\n]{1,40}):\s+(\S.*)$', dotAll: true);

/// The lead-in before the first ": " when it is at most 40 characters ("Chỗ ngồi: chọn ghế…"),
/// shown in semibold; null otherwise ("8:00" has no space after the colon).
({String lead, String rest})? lbLeadIn(String item) {
  final m = _leadIn.firstMatch(item);
  return m == null ? null : (lead: m.group(1)!.trim(), rest: m.group(2)!);
}
