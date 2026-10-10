import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Time-zone choices for 11b. Figma lists fixed offsets ("GMT+7 · Hà Nội, TP. Hồ Chí Minh,
/// Bangkok"); the app stores the IANA zone behind each row (P-014) so DST is handled.
@immutable
class ZoneChoice {
  const ZoneChoice(
    this.zone, {
    required this.vi,
    required this.en,
    this.keywords = '',
  });

  final String zone;
  final String vi;
  final String en;

  /// Extra search terms (countries, other spellings).
  final String keywords;

  String cities(String languageCode) => languageCode == 'vi' ? vi : en;
}

/// The six rows drawn in Figma, in order, then common zones reachable through search.
const zoneChoices = <ZoneChoice>[
  ZoneChoice(
    'Asia/Ho_Chi_Minh',
    vi: 'Hà Nội, TP. Hồ Chí Minh, Bangkok',
    en: 'Hanoi, Ho Chi Minh City, Bangkok',
    keywords:
        'Việt Nam Vietnam Thái Lan Thailand Saigon Sài Gòn Đà Nẵng Da Nang',
  ),
  ZoneChoice(
    'Asia/Singapore',
    vi: 'Singapore, Kuala Lumpur, Đài Bắc',
    en: 'Singapore, Kuala Lumpur, Taipei',
    keywords: 'Malaysia Đài Loan Taiwan Philippines Manila',
  ),
  ZoneChoice(
    'Asia/Tokyo',
    vi: 'Tokyo, Seoul',
    en: 'Tokyo, Seoul',
    keywords: 'Nhật Bản Japan Hàn Quốc Korea',
  ),
  ZoneChoice(
    'Australia/Sydney',
    vi: 'Sydney, Melbourne',
    en: 'Sydney, Melbourne',
    keywords: 'Úc Australia Canberra',
  ),
  ZoneChoice(
    'Europe/Paris',
    vi: 'Paris, Berlin',
    en: 'Paris, Berlin',
    keywords:
        'Pháp France Đức Germany Amsterdam Rome Madrid Praha Prague Warsaw',
  ),
  ZoneChoice(
    'America/New_York',
    vi: 'New York, Toronto',
    en: 'New York, Toronto',
    keywords: 'Mỹ USA Hoa Kỳ United States Canada Washington Boston Miami',
  ),
  ZoneChoice(
    'Asia/Shanghai',
    vi: 'Bắc Kinh, Thượng Hải, Hồng Kông',
    en: 'Beijing, Shanghai, Hong Kong',
    keywords: 'Trung Quốc China',
  ),
  ZoneChoice(
    'Asia/Jakarta',
    vi: 'Jakarta',
    en: 'Jakarta',
    keywords: 'Indonesia',
  ),
  ZoneChoice(
    'Asia/Kolkata',
    vi: 'New Delhi, Mumbai',
    en: 'New Delhi, Mumbai',
    keywords: 'Ấn Độ India',
  ),
  ZoneChoice(
    'Asia/Dubai',
    vi: 'Dubai, Abu Dhabi',
    en: 'Dubai, Abu Dhabi',
    keywords: 'UAE',
  ),
  ZoneChoice(
    'Europe/London',
    vi: 'London, Dublin',
    en: 'London, Dublin',
    keywords: 'Anh England UK Ireland',
  ),
  ZoneChoice(
    'Europe/Moscow',
    vi: 'Moskva',
    en: 'Moscow',
    keywords: 'Nga Russia',
  ),
  ZoneChoice(
    'America/Chicago',
    vi: 'Chicago, Houston, Dallas',
    en: 'Chicago, Houston, Dallas',
    keywords: 'Mỹ USA Texas',
  ),
  ZoneChoice('America/Denver', vi: 'Denver', en: 'Denver', keywords: 'Mỹ USA'),
  ZoneChoice(
    'America/Los_Angeles',
    vi: 'Los Angeles, San Francisco, Seattle',
    en: 'Los Angeles, San Francisco, Seattle',
    keywords: 'Mỹ USA California Vancouver Canada',
  ),
  ZoneChoice(
    'Australia/Perth',
    vi: 'Perth',
    en: 'Perth',
    keywords: 'Úc Australia',
  ),
  ZoneChoice(
    'Pacific/Auckland',
    vi: 'Auckland, Wellington',
    en: 'Auckland, Wellington',
    keywords: 'New Zealand',
  ),
];

const figmaZoneCount = 6;

bool _ready = false;

/// Loads the tz database (last 10 years of rules) once.
void ensureTimeZones() {
  if (_ready) return;
  tzdata.initializeTimeZones();
  _ready = true;
}

/// "GMT+7", "GMT+5:30", "GMT−5" (Figma uses the real minus sign) at [at].
String gmtOffsetLabel(String zone, DateTime at) {
  ensureTimeZones();
  final Duration offset;
  try {
    offset = tz.TZDateTime.from(at, tz.getLocation(zone)).timeZoneOffset;
  } on Object {
    return zone;
  }
  final minutes = offset.inMinutes;
  if (minutes == 0) return 'GMT';
  final sign = minutes > 0 ? '+' : '−';
  final h = minutes.abs() ~/ 60;
  final m = minutes.abs() % 60;
  return 'GMT$sign$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
}

/// Short place name for a zone: the curated cities, else the IANA city part.
String placeOf(String zone, String languageCode) {
  for (final c in zoneChoices) {
    if (c.zone == zone) return c.cities(languageCode).split(',').first.trim();
  }
  return zone.split('/').last.replaceAll('_', ' ');
}

const _foldGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _foldMap = {
  for (final entry in _foldGroups.entries)
    for (final ch in entry.value.split('')) ch: entry.key,
};

String _fold(String s) =>
    s.toLowerCase().split('').map((ch) => _foldMap[ch] ?? ch).join();

/// Diacritic-insensitive search over cities, keywords and the IANA id ("ha noi" finds Hà Nội).
List<ZoneChoice> searchZones(String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return zoneChoices.take(figmaZoneCount).toList();
  return [
    for (final c in zoneChoices)
      if (_fold(
        '${c.vi} ${c.en} ${c.keywords} ${c.zone.replaceAll('_', ' ')}',
      ).contains(q))
        c,
  ];
}

/// The device's IANA zone; falls back to Vietnam when the platform cannot tell.
Future<String> deviceTimeZone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    ensureTimeZones();
    tz.getLocation(info.identifier);
    return info.identifier;
  } on Object {
    return 'Asia/Ho_Chi_Minh';
  }
}
