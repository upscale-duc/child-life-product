import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'notification_destinations.dart';

/// The legacy `category` of a row (`notificationCategories` in contracts). EN06 chips now use
/// [InboxGroup] (P-174); kept so older rows and the server's field still parse.
enum NotificationCategory { reminders, baby, family, general }

/// `users/{uid}/notifications/{id}` (D-076 #2): one row per server push, written by Functions
/// (`notifyUsers`). The copy is what the push showed (generic, R-120), in both languages; `data`
/// holds ids only, the same as the push's.
@immutable
class InboxItem {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.title,
    required this.body,
    required this.route,
    required this.babyId,
    required this.data,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
    this.expireAt,
    this.destination,
    this.group,
    this.templateId,
    this.templateVersion,
  });

  final String id;
  final String kind;
  final NotificationCategory category;
  final Map<String, String> title;
  final Map<String, String> body;

  /// `notificationRoutes`: ruleReminder · vaccine · spending · memories · keepsakeJob · inbox.
  final String route;
  final String? babyId;
  final Map<String, String> data;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;

  /// The 90-day end of the row (the daily job removes it; until then it is hidden).
  final DateTime? expireAt;

  /// P-174: the semantic destination id, the chip, and the template that wrote the copy. Absent
  /// on rows written before it (derived from the kind and `data`).
  final String? destination;
  final String? group;
  final String? templateId;
  final int? templateVersion;

  bool get unread => readAt == null;

  /// The EN06 chip this row shows under.
  InboxGroup get inboxGroup => inboxGroupFor(kind, group);

  /// Hidden from EN06: archived, or past its end.
  bool hiddenAt(DateTime now) =>
      archivedAt != null || (expireAt != null && !expireAt!.isAfter(now));

  /// What the resolver opens for this row.
  NotificationTarget get target => NotificationTarget(
    kind: kind,
    babyId: babyId,
    data: data,
    destination: destination,
    inboxId: id,
  );

  String titleIn(String language) => title[language] ?? title['vi'] ?? '';
  String bodyIn(String language) => body[language] ?? body['vi'] ?? '';

  static Map<String, String> _strings(Object? v) => v is Map
      ? {
          for (final e in v.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
        }
      : const {};

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

  /// Null for a row this version cannot read (no time or no copy).
  static InboxItem? fromDoc(String id, Map<String, dynamic>? m) {
    if (m == null) return null;
    final created = _date(m['createdAt']);
    final title = _strings(m['title']);
    if (created == null || title.isEmpty) return null;
    final babyId = m['babyId'];
    String? text(String key) => m[key] is String ? m[key] as String : null;
    return InboxItem(
      id: id,
      kind: m['kind'] as String? ?? '',
      category:
          NotificationCategory.values.asNameMap()[m['category']] ??
          NotificationCategory.general,
      title: title,
      body: _strings(m['body']),
      route: m['route'] as String? ?? 'inbox',
      babyId: babyId is String ? babyId : null,
      data: _strings(m['data']),
      createdAt: created,
      readAt: _date(m['readAt']),
      archivedAt: _date(m['archivedAt']),
      expireAt: _date(m['expireAt']),
      destination: text('destination'),
      group: text('group'),
      templateId: text('templateId'),
      templateVersion: switch (m['templateVersion']) {
        final num v => v.toInt(),
        _ => null,
      },
    );
  }
}

/// EN07 switches in `users/{uid}/settings/notifications` (`notificationSettingsOf` in
/// contracts): a missing key takes its default; `vaccines` and `spending` follow the G-056
/// "Nhắc việc" switch (`reminders`) until set.
@immutable
class NotificationSettings {
  const NotificationSettings(this.values);

  static const keys = [
    'reminders',
    'vaccines',
    'spending',
    'rhythm',
    'stages',
    'milestones',
    'articles',
    'weeklySummary',
    'memories',
    'messages',
    'storage',
    'photoSuggestions',
    'keepsakePrompts',
    'familyActivity',
    // D-092 (G-109): someone joined, an invitation was declined.
    'familyMembers',
    // D-093: a family member sent this person a handover.
    'handovers',
    // D-094: pushes show the baby's nickname (else "bé"); on by default.
    'babyName',
  ];

  /// EN07 draws "Bài viết gợi ý" and "Hoạt động của gia đình" off.
  static const _offByDefault = {'articles', 'familyActivity'};

  final Map<String, bool> values;

  factory NotificationSettings.fromMap(Map<String, dynamic>? m) {
    final out = {
      for (final k in keys)
        k: m?[k] is bool ? m![k] as bool : !_offByDefault.contains(k),
    };
    if (m?['vaccines'] is! bool) out['vaccines'] = out['reminders']!;
    if (m?['spending'] is! bool) out['spending'] = out['reminders']!;
    return NotificationSettings(out);
  }

  static final defaults = NotificationSettings.fromMap(null);

  /// The switches EN07 draws on: "Bật" in Tôi while all of these are.
  static final onByDefault = [
    for (final k in keys)
      if (!_offByDefault.contains(k)) k,
  ];

  bool operator [](String key) => values[key] ?? false;

  NotificationSettings set(String key, bool value) =>
      NotificationSettings({...values, key: value});

  /// Every switch is written, so the stored document says what the screen showed.
  Map<String, Object?> toMap() => {for (final k in keys) k: values[k]};

  bool allOf(Iterable<String> shown) => shown.every((k) => this[k]);
  bool noneOf(Iterable<String> shown) => shown.every((k) => !this[k]);

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings && mapEquals(other.values, values);

  @override
  int get hashCode => Object.hashAll(keys.map((k) => values[k]));
}
