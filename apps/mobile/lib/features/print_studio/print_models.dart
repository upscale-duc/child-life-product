import 'package:flutter/foundation.dart';
import '../memories/memory_models.dart';

const printSizes = {
  '10x15': (100, 150),
  '13x18': (130, 180),
  '15x21': (150, 210),
  '15x15': (150, 150),
  '20x20': (200, 200),
};

/// Owns only media ids and edited copy. Original assets remain in Kỷ niệm.
@immutable
class PrintDesign {
  const PrintDesign({
    required this.name,
    required this.title,
    required this.date,
    this.product = 'trio',
    this.size = '13x18',
    this.style = 'minimal',
    this.frame = 'white',
    this.occasion = 'hundred',
    this.message = '',
    this.birthDetails = '',
    this.showBirthDetails = true,
    this.mediaIds = const [],
    this.pageTitles = const [],
    this.pageLayouts = const [],
    this.pagePhotos = const [],
    this.pageSubtitles = const [],
    this.pages = 24,
    this.locale = 'vi',
  });
  final String product,
      size,
      style,
      frame,
      occasion,
      name,
      title,
      date,
      message,
      birthDetails,
      locale;
  final bool showBirthDetails;
  final List<String> mediaIds, pageTitles, pageLayouts, pageSubtitles;
  final List<List<int>> pagePhotos;
  final int pages;
  bool get isBook => product == 'book';
  int get count => isBook
      ? pages
      : product == 'five'
      ? 5
      : product == 'trio'
      ? 3
      : 1;
  String bookLayout(int page) => page < pageLayouts.length
      ? pageLayouts[page]
      : page == 1
      ? 'text'
      : page > 0 && page.isEven
      ? 'collage'
      : 'portrait';
  int layoutPage(int page) => isBook
      ? page
      : page < pageLayouts.length
      ? (pageLayouts[page] == 'text'
            ? 1
            : pageLayouts[page] == 'collage'
            ? 2
            : 0)
      : product == 'single'
      ? 0
      : page;
  List<int> slots(int page) {
    if (page < pagePhotos.length) return pagePhotos[page];
    if (isBook) {
      if (bookLayout(page) == 'text') return [];
      return List.generate(
        bookLayout(page) == 'collage' ? 4 : 1,
        (i) => mediaIds.isEmpty ? 0 : (page + i) % mediaIds.length,
      );
    }
    final role = layoutPage(page);
    return role == 1
        ? []
        : role == 2
        ? [1, 2, 3, 4]
        : [page == 0 ? 0 : page + 2];
  }

  bool get ready =>
      name.trim().isNotEmpty &&
      [
        for (var p = 0; p < count; p++) ...slots(p),
      ].every((i) => i < mediaIds.length && mediaIds[i].isNotEmpty);
  bool lowQuality(List<MediaItem> media) {
    final (w, h) = printSizes[size]!;
    return mediaIds.any((id) {
      final m = media.where((m) => m.id == id).firstOrNull;
      if (m == null || !m.isReady || m.deleted || m.isVideo) return true;
      final mw = m.width ?? 0, mh = m.height ?? 0;
      return mw / (w * .82 / 25.4) < 150 || mh / (h * .66 / 25.4) < 150;
    });
  }

  Map<String, dynamic> toJson() => {
    'product': product,
    'size': size,
    'style': style,
    'frame': frame,
    'occasion': occasion,
    'name': name,
    'title': title,
    'date': date,
    'message': message,
    'birthDetails': birthDetails,
    'showBirthDetails': showBirthDetails,
    'mediaIds': mediaIds,
    'pageTitles': pageTitles,
    'pageLayouts': pageLayouts,
    'pagePhotos': {
      for (var p = 0; p < pagePhotos.length; p++) '$p': pagePhotos[p],
    },
    'pageSubtitles': pageSubtitles,
    'pages': pages,
    'locale': locale,
  };
  factory PrintDesign.fromJson(Map<String, dynamic> j) => PrintDesign(
    name: j['name'] as String? ?? '',
    title: j['title'] as String? ?? '',
    date: j['date'] as String? ?? '',
    product: j['product'] as String? ?? 'trio',
    size: j['size'] as String? ?? '13x18',
    style: j['style'] as String? ?? 'minimal',
    frame: j['frame'] as String? ?? 'white',
    occasion: j['occasion'] as String? ?? 'hundred',
    message: j['message'] as String? ?? '',
    birthDetails: j['birthDetails'] as String? ?? '',
    showBirthDetails: j['showBirthDetails'] as bool? ?? true,
    mediaIds: List<String>.from(j['mediaIds'] as List? ?? []),
    pageTitles: List<String>.from(j['pageTitles'] as List? ?? []),
    pageLayouts: List<String>.from(j['pageLayouts'] as List? ?? []),
    pageSubtitles: List<String>.from(j['pageSubtitles'] as List? ?? []),
    pagePhotos: j['pagePhotos'] is Map
        ? List.generate(
            (j['pagePhotos'] as Map).length,
            (i) =>
                List<int>.from((j['pagePhotos'] as Map)['$i'] as List? ?? []),
          )
        : (j['pagePhotos'] as List? ?? [])
              .map((p) => List<int>.from(p as List))
              .toList(),
    pages: j['pages'] as int? ?? 24,
    locale: j['locale'] as String? ?? 'vi',
  );
  PrintDesign copy(Map<String, dynamic> values) =>
      PrintDesign.fromJson({...toJson(), ...values});
}

class PrintCatalog {
  const PrintCatalog(this.json);
  final Map<String, dynamic> json;
  int get version => (json['version'] as num).toInt();
  bool get physical => json['physicalEnabled'] == true;
  bool get digital => json['digitalEnabled'] == true;
  bool get pricesEstimated => json['pricesEstimated'] != false;
  bool canOrder(PrintDesign d) =>
      physical &&
      (json['orderProducts'] as List? ?? ['single', 'trio', 'five', 'book'])
          .contains(d.product);
  int get giftWrapFee => (json['giftWrapFee'] as num? ?? 30000).toInt();
  int get leadDays => (json['leadDays'] as num? ?? 7).toInt();
  List<String> get countries =>
      List<String>.from(json['supportedCountries'] as List? ?? []);
  String policy(String language) =>
      (json['policy'] as Map?)?[language] as String? ?? '';
  int? price(PrintDesign d) {
    final key = '${d.product}:${d.size}${d.isBook ? ':${d.pages}' : ''}';
    final p = (json['prices'] as Map?)?[key] as num?;
    return p == null
        ? null
        : p.toInt() +
              (d.frame == 'gift' ? (json['giftSurcharge'] as num).toInt() : 0);
  }

  ({int subtotal, int shipping, int total}) totals(
    PrintDesign d,
    int quantity, {
    bool giftWrap = false,
  }) {
    final subtotal = (price(d) ?? 0) * quantity + (giftWrap ? giftWrapFee : 0);
    final shipping = subtotal >= (json['freeShippingFrom'] as num)
        ? 0
        : (json['shippingFee'] as num).toInt();
    final total = subtotal + shipping;
    return (subtotal: subtotal, shipping: shipping, total: total);
  }
}
