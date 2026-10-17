import 'package:flutter/widgets.dart';

/// Sơ cứu trẻ em (Figma v1.1 7a–7i, TH01–TH24; D-058). The guide is editorial content from the
/// portal: `publicConfig/content_firstAid` holds one pack (shape in
/// `packages/contracts/src/first-aid.ts`). Parsing is strict per item: anything malformed makes the
/// whole pack invalid, so the app keeps its last good copy rather than showing half a step.
@immutable
class FaText {
  const FaText(this.vi, this.en);
  final String vi;
  final String en;

  String of(BuildContext context) => pick(Localizations.localeOf(context));
  String pick(Locale locale) => locale.languageCode == 'en' ? en : vi;

  static FaText parse(Object? j) {
    final m = j! as Map;
    return FaText(m['vi']! as String, m['en']! as String);
  }

  Map<String, String> toJson() => {'vi': vi, 'en': en};
}

enum FaLayout { grid, list }

enum FaTone { danger, sunshine, mint }

enum FaCalloutTone { negative, warning, positive }

enum FaCprRole { compressions, breaths }

@immutable
class FaCategory {
  const FaCategory({
    required this.id,
    required this.title,
    required this.layout,
    required this.tone,
  });
  final String id;
  final FaText title;
  final FaLayout layout;
  final FaTone tone;

  static FaCategory parse(Map j) => FaCategory(
    id: j['id']! as String,
    title: FaText.parse(j['title']),
    layout: FaLayout.values.byName(j['layout']! as String),
    tone: FaTone.values.byName(j['tone']! as String),
  );
}

@immutable
class FaChip {
  const FaChip(this.label, {required this.mint});
  final FaText label;
  final bool mint;
}

@immutable
class FaStep {
  const FaStep({
    required this.title,
    required this.body,
    this.image,
    this.chips = const [],
    this.count,
    this.cprRole,
  });
  final FaText title;
  final FaText body;
  final String? image;
  final List<FaChip> chips;

  /// Tap-to-count dots ("Vỗ lưng 5 lần").
  final int? count;
  final FaCprRole? cprRole;

  static FaStep parse(Map j) => FaStep(
    title: FaText.parse(j['title']),
    body: FaText.parse(j['body']),
    image: j['image'] as String?,
    chips: [
      for (final c in j['chips']! as List)
        FaChip(FaText.parse((c as Map)['label']), mint: c['tone'] == 'mint'),
    ],
    count: (j['count'] as num?)?.toInt(),
    cprRole: switch (j['cprRole']) {
      'compressions' => FaCprRole.compressions,
      'breaths' => FaCprRole.breaths,
      _ => null,
    },
  );
}

@immutable
class FaCallout {
  const FaCallout({
    required this.tone,
    required this.heading,
    required this.items,
  });
  final FaCalloutTone tone;
  final FaText heading;
  final List<FaText> items;

  static FaCallout parse(Map j) => FaCallout(
    tone: FaCalloutTone.values.byName(j['tone']! as String),
    heading: FaText.parse(j['heading']),
    items: [for (final i in j['items']! as List) FaText.parse(i)],
  );
}

/// Months, from inclusive, to exclusive (null = no end).
typedef FaAge = ({int from, int? to});

FaAge? _age(Object? j) {
  if (j == null) return null;
  final m = j as Map;
  return (from: (m['from']! as num).toInt(), to: (m['to'] as num?)?.toInt());
}

bool faAgeContains(FaAge age, int months) =>
    months >= age.from && (age.to == null || months < age.to!);

@immutable
class FaVariant {
  const FaVariant({
    required this.id,
    this.label,
    this.ageMonths,
    this.hero,
    this.banner,
    required this.steps,
    required this.callouts,
    this.cpr,
  });
  final String id;
  final FaText? label;
  final FaAge? ageMonths;
  final String? hero;
  final FaText? banner;
  final List<FaStep> steps;
  final List<FaCallout> callouts;

  /// "infant" / "child": opens CPR mode (7i) instead of the plain step mode.
  final String? cpr;

  static FaVariant parse(Map j) => FaVariant(
    id: j['id']! as String,
    label: j['label'] == null ? null : FaText.parse(j['label']),
    ageMonths: _age(j['ageMonths']),
    hero: j['hero'] as String?,
    banner: j['banner'] == null ? null : FaText.parse(j['banner']),
    steps: [for (final s in j['steps']! as List) FaStep.parse(s as Map)],
    callouts: [
      for (final c in j['callouts']! as List) FaCallout.parse(c as Map),
    ],
    cpr: j['cpr'] as String?,
  );
}

@immutable
class FaSituation {
  const FaSituation({
    required this.id,
    required this.category,
    required this.emergency,
    required this.monitoring,
    required this.title,
    required this.lead,
    required this.keywords,
    required this.icon,
    required this.hero,
    this.ageMonths,
    this.byAge = false,
    required this.variants,
    this.seizureTimer = false,
  });
  final String id;
  final String category;
  final bool emergency;
  final bool monitoring;
  final FaText title;
  final FaText lead;
  final List<FaText> keywords;
  final String icon;
  final String hero;
  final FaAge? ageMonths;

  /// Variants by age ("Dưới 1 tuổi" / "Từ 1 tuổi") rather than by condition.
  final bool byAge;
  final List<FaVariant> variants;
  final bool seizureTimer;

  /// The variant to open first: the selected baby's age band when the variants are by age.
  FaVariant defaultVariant(int? months) {
    if (byAge && months != null) {
      for (final v in variants) {
        if (v.ageMonths != null && faAgeContains(v.ageMonths!, months)) {
          return v;
        }
      }
    }
    return variants.first;
  }

  FaVariant? variant(String? id) {
    for (final v in variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  static FaSituation parse(Map j) => FaSituation(
    id: j['id']! as String,
    category: j['category']! as String,
    emergency: j['emergency']! as bool,
    monitoring: j['monitoring']! as bool,
    title: FaText.parse(j['title']),
    lead: FaText.parse(j['lead']),
    keywords: [for (final k in j['keywords']! as List) FaText.parse(k)],
    icon: j['icon']! as String,
    hero: j['hero']! as String,
    ageMonths: _age(j['ageMonths']),
    byAge: j['variantKind'] == 'age',
    variants: [
      for (final v in j['variants']! as List) FaVariant.parse(v as Map),
    ],
    seizureTimer: j['tool'] == 'seizureTimer',
  );
}

@immutable
class FaCpr {
  const FaCpr({
    required this.id,
    required this.ratePerMinute,
    required this.compressions,
    required this.breaths,
    required this.compressionText,
    this.image,
  });
  final String id;
  final int ratePerMinute;
  final int compressions;
  final int breaths;
  final FaText compressionText;
  final String? image;

  static FaCpr parse(Map j) => FaCpr(
    id: j['id']! as String,
    ratePerMinute: (j['ratePerMinute']! as num).toInt(),
    compressions: (j['compressions']! as num).toInt(),
    breaths: (j['breaths']! as num).toInt(),
    compressionText: FaText.parse(j['compressionText']),
    image: j['image'] as String?,
  );
}

@immutable
class FaReview {
  const FaReview({required this.reviewer, required this.reviewedOn});
  final String reviewer;
  final DateTime reviewedOn;
}

@immutable
class FirstAidPack {
  const FirstAidPack({
    required this.version,
    required this.emergencyNumber,
    required this.categories,
    required this.situations,
    required this.cpr,
    required this.quickSearch,
    this.review,
  });

  final String version;
  final String emergencyNumber;
  final List<FaCategory> categories;
  final List<FaSituation> situations;
  final List<FaCpr> cpr;
  final List<FaText> quickSearch;
  final FaReview? review;

  FaSituation? situation(String id) {
    for (final s in situations) {
      if (s.id == id) return s;
    }
    return null;
  }

  FaCategory? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  FaCpr? protocol(String? id) {
    for (final c in cpr) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The situation whose variants open CPR mode (the 7b "Bắt đầu hồi sức tim phổi" button).
  FaSituation? get cprSituation {
    for (final s in situations) {
      if (s.variants.any((v) => v.cpr != null)) return s;
    }
    return null;
  }

  /// Every picture the guide shows, downloaded together for offline use.
  Set<String> get images => {
    for (final s in situations) ...[
      s.icon,
      s.hero,
      for (final v in s.variants) ...[
        ?v.hero,
        for (final st in v.steps) ?st.image,
      ],
    ],
    for (final c in cpr) ?c.image,
  };

  /// Situations in index order for a baby of [months]: those outside their age band (newborn
  /// pages for an older baby) move to the end of their group, otherwise the pack's order stays.
  List<FaSituation> ordered(int? months) {
    if (months == null) return situations;
    bool fits(FaSituation s) =>
        s.ageMonths == null || faAgeContains(s.ageMonths!, months);
    return [
      for (final c in categories) ...[
        ...situations.where((s) => s.category == c.id && fits(s)),
        ...situations.where((s) => s.category == c.id && !fits(s)),
      ],
    ];
  }

  /// The guide's text names no country's number: `{emergency}` (ambulance) and `{poison}` (poison
  /// line) are filled from the pack. With no poison line known, `{poison}` is the emergency number.
  static Object? fillTokens(Object? j, String emergency, {String? poison}) =>
      switch (j) {
        String s =>
          s
              .replaceAll('{emergency}', emergency)
              .replaceAll('{poison}', poison ?? emergency),
        Map m => {
          for (final e in m.entries)
            e.key: fillTokens(e.value, emergency, poison: poison),
        },
        List l => [for (final x in l) fillTokens(x, emergency, poison: poison)],
        _ => j,
      };

  /// `publicConfig/content_firstAid` → the pack, or null when absent or malformed.
  static FirstAidPack? fromDoc(Map<String, Object?>? doc) {
    if (doc == null) return null;
    try {
      final raw = doc['pack']! as Map;
      final p = fillTokens(raw, raw['emergencyNumber']! as String) as Map;
      final review = p['review'] as Map?;
      final pack = FirstAidPack(
        version: doc['version']! as String,
        emergencyNumber: p['emergencyNumber']! as String,
        categories: [
          for (final c in p['categories']! as List) FaCategory.parse(c as Map),
        ],
        situations: [
          for (final s in p['situations']! as List) FaSituation.parse(s as Map),
        ],
        cpr: [for (final c in p['cpr']! as List) FaCpr.parse(c as Map)],
        quickSearch: [
          for (final q in p['quickSearch']! as List) FaText.parse(q),
        ],
        review: review == null
            ? null
            : FaReview(
                reviewer: review['reviewer']! as String,
                reviewedOn: DateTime.parse(review['reviewedOn']! as String),
              ),
      );
      if (pack.situations.isEmpty ||
          pack.situations.any((s) => pack.category(s.category) == null)) {
        return null;
      }
      return pack;
    } on Object {
      return null;
    }
  }
}

/// Diacritic-insensitive matching for search ("sot" finds "sốt").
String faFold(String s) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final out = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    var plain = ch;
    for (final g in groups.entries) {
      if (g.value.contains(ch)) {
        plain = g.key;
        break;
      }
    }
    out.write(plain);
  }
  return out.toString();
}

/// Search over title, keywords, lead and body text (7c), title matches first. Returns the
/// situation with the snippet to show under it (the matching passage, or the lead).
List<({FaSituation situation, FaText snippet})> faSearch(
  FirstAidPack pack,
  String query,
) {
  final q = faFold(query.trim());
  if (q.isEmpty) return const [];
  bool has(FaText t) => faFold(t.vi).contains(q) || faFold(t.en).contains(q);
  final ranked = <(int, FaSituation, FaText)>[];
  for (final s in pack.situations) {
    FaText? hit;
    var rank = 9;
    if (has(s.title)) {
      rank = 0;
      hit = s.lead;
    } else {
      for (final k in s.keywords) {
        if (has(k)) {
          rank = 1;
          hit = s.lead;
          break;
        }
      }
    }
    if (hit == null && has(s.lead)) {
      rank = 2;
      hit = s.lead;
    }
    if (hit == null) {
      outer:
      for (final v in s.variants) {
        for (final st in v.steps) {
          if (has(st.title) || has(st.body)) {
            hit = has(st.body) ? st.body : st.title;
            break outer;
          }
        }
        for (final c in v.callouts) {
          for (final i in c.items) {
            if (has(i)) {
              hit = i;
              break outer;
            }
          }
        }
      }
      rank = 3;
    }
    if (hit != null) ranked.add((rank, s, hit));
  }
  ranked.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final r in ranked) (situation: r.$2, snippet: r.$3)];
}
