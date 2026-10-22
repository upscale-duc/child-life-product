import 'dart:async';

import 'package:child_life/features/notifications/notification_destinations.dart';
import 'package:child_life/features/notifications/notification_models.dart';
import 'package:child_life/features/notifications/notification_repository.dart';

/// Notification centre (D-076 #2) without Firebase: an in-memory inbox and EN07 switches that
/// record the calls. Synthetic copy only (generic, R-120).
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({
    List<InboxItem> inbox = const [],
    NotificationSettings? settings,
  }) : _inbox = [...inbox],
       _settings = settings ?? NotificationSettings.defaults;

  final List<InboxItem> _inbox;
  NotificationSettings _settings;
  final calls = <(String, Object?)>[];
  final _changes = StreamController<void>.broadcast();

  List<InboxItem> get visible => [
    for (final i in _inbox)
      if (i.archivedAt == null) i,
  ];

  /// When set, [watchInbox] fails with it (EN06 error state) until cleared.
  Object? failWith;

  /// How many times [watchInbox] was subscribed, and with which limits.
  final limits = <int>[];

  InboxPage _page(int limit) => InboxPage(
    items: visible.take(limit).toList(),
    more: visible.length > limit,
  );

  @override
  Stream<InboxPage> watchInbox(String uid, {int limit = inboxPageSize}) async* {
    limits.add(limit);
    final error = failWith;
    if (error != null) throw error;
    yield _page(limit);
    await for (final _ in _changes.stream) {
      yield _page(limit);
    }
  }

  @override
  Stream<int> watchUnreadCount(String uid) async* {
    int count() => visible.where((i) => i.unread).length;
    yield count();
    await for (final _ in _changes.stream) {
      yield count();
    }
  }

  @override
  Future<void> markRead(String uid, Iterable<String> ids) async {
    final set = ids.toSet();
    calls.add(('markRead', set));
    for (var i = 0; i < _inbox.length; i++) {
      if (set.contains(_inbox[i].id)) _inbox[i] = _copy(_inbox[i], read: true);
    }
    _changes.add(null);
  }

  @override
  Future<void> archive(String uid, String id) async {
    calls.add(('archive', id));
    for (var i = 0; i < _inbox.length; i++) {
      if (_inbox[i].id == id) _inbox[i] = _copy(_inbox[i], archived: true);
    }
    _changes.add(null);
  }

  @override
  Stream<NotificationSettings> watchSettings(String uid) async* {
    yield _settings;
    await for (final _ in _changes.stream) {
      yield _settings;
    }
  }

  @override
  Future<void> saveSettings(String uid, NotificationSettings settings) async {
    calls.add(('saveSettings', settings.toMap()));
    _settings = settings;
    _changes.add(null);
  }

  static InboxItem _copy(
    InboxItem i, {
    bool read = false,
    bool archived = false,
  }) => InboxItem(
    id: i.id,
    kind: i.kind,
    category: i.category,
    title: i.title,
    body: i.body,
    route: i.route,
    babyId: i.babyId,
    data: i.data,
    createdAt: i.createdAt,
    readAt: read ? DateTime(2026, 10, 8, 10) : i.readAt,
    archivedAt: archived ? DateTime(2026, 10, 8, 10) : i.archivedAt,
    expireAt: i.expireAt,
    destination: i.destination,
    group: i.group,
    templateId: i.templateId,
    templateVersion: i.templateVersion,
  );
}

InboxItem inboxItem(
  String id, {
  required String kind,
  required NotificationCategory category,
  required String route,
  required DateTime at,
  required (String, String) vi,
  required (String, String) en,
  String? babyId = 'b_00000000000000000001',
  Map<String, String> data = const {},
  bool read = false,
  String? destination,
  String? group,
  DateTime? expireAt,
}) => InboxItem(
  id: id,
  kind: kind,
  category: category,
  title: {'vi': vi.$1, 'en': en.$1},
  body: {'vi': vi.$2, 'en': en.$2},
  route: route,
  babyId: babyId,
  data: {'kind': kind, 'inboxId': id, ...data},
  createdAt: at,
  readAt: read ? at : null,
  destination: destination,
  group: group,
  expireAt: expireAt,
);

/// `recordNotificationOpen` without Firebase: what the app reported.
class FakeNotificationOpenReporter implements NotificationOpenReporter {
  final records =
      <
        ({
          String inboxId,
          NotificationSurface surface,
          NotificationOpenOutcome outcome,
          String? destination,
        })
      >[];

  @override
  Future<void> record({
    required String inboxId,
    required NotificationSurface surface,
    required NotificationOpenOutcome outcome,
    String? destination,
  }) async => records.add((
    inboxId: inboxId,
    surface: surface,
    outcome: outcome,
    destination: destination,
  ));
}

/// `actOnEngagement` "open" without Firebase: the ids asked, and the answer.
class FakeEngagementOpener {
  FakeEngagementOpener({this.opens = true});
  bool opens;
  final ids = <String>[];

  Future<bool> call(Object ref, String id) async {
    ids.add(id);
    return opens;
  }
}

/// EN06 as drawn, with the server's generic copy (no baby name, R-120); "now" is Thu 8 Oct
/// 2026, 21:00.
List<InboxItem> mockInbox() => [
  inboxItem(
    'n_vx-1',
    kind: 'vaccine',
    category: NotificationCategory.reminders,
    route: 'vaccine',
    at: DateTime(2026, 10, 8, 19),
    vi: (
      'Ngày mai có lịch tiêm của bé',
      '6in1 · Rota · Phế cầu (mũi 1) · Mốc 2 tháng tuổi. Nhớ mang sổ tiêm và một chiếc khăn mỏng.',
    ),
    en: (
      'A vaccination is due tomorrow',
      '6-in-1 · Rotavirus · Pneumococcal (dose 1) · 2-month milestone. Remember the vaccination book and a thin towel.',
    ),
    data: {
      'babyId': 'b_00000000000000000001',
      'date': '2026-10-09',
      'months': '2',
    },
  ),
  inboxItem(
    'n_rr-1',
    kind: 'reminderRule',
    category: NotificationCategory.reminders,
    route: 'ruleReminder',
    at: DateTime(2026, 10, 8, 11, 45),
    vi: ('Đến giờ cữ bú bạn đã đặt', 'Lần bú gần nhất 08:45 · 3 giờ trước'),
    en: ('Time for the feed you set', 'Last feed 08:45 · 3 h ago'),
    data: {'babyId': 'b_00000000000000000001', 'ruleId': 'r1', 'type': 'feed'},
    read: true,
  ),
  inboxItem(
    'n_bn-1',
    kind: 'memories',
    category: NotificationCategory.family,
    route: 'memories',
    at: DateTime(2026, 10, 6, 20, 10),
    vi: ('Có 3 khoảnh khắc mới', 'Minh vừa chia sẻ với gia đình. Mở để xem.'),
    en: ('3 new moments', 'Minh just shared with the family. Open to see.'),
  ),
  inboxItem(
    'n_sp-1',
    kind: 'spending',
    category: NotificationCategory.reminders,
    route: 'spending',
    at: DateTime(2026, 10, 4, 9),
    vi: (
      'Chi tiêu đã dùng 80% ngân sách tháng',
      'Mở Chi tiêu để xem chi tiết.',
    ),
    en: (
      'Spending has reached 80% of the monthly budget',
      'Open Spending for details.',
    ),
    read: true,
  ),
  inboxItem(
    'n_msg-1',
    kind: 'message',
    category: NotificationCategory.family,
    route: 'memories',
    at: DateTime(2026, 9, 28, 18),
    vi: ('Có lời nhắn mới', 'Bà nội Hoa vừa nhắn cho ba mẹ. Mở để đọc.'),
    en: ('New message', 'Bà nội Hoa sent the parents a message. Open to read.'),
    read: true,
  ),
];
