import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/providers.dart';
import '../../app/session.dart';
import '../../core/appearance/appearance_providers.dart';

/// MET-01 / P-137: bounded UID-owned operational metadata; never photo ids or child content.
class ProductAnalyticsReporter {
  ProductAnalyticsReporter({
    required this.ownerUid,
    required this.currentOwner,
    required this.read,
    required this.write,
    required this.remove,
    required this.send,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final String ownerUid;
  final String? Function() currentOwner;
  final String? Function() read;
  final Future<void> Function(String) write;
  final Future<void> Function() remove;
  final Future<void> Function(Map<String, Object?>) send;
  final DateTime Function() clock;
  bool _closed = false, _sending = false;
  Future<void> _serial = Future.value();
  final Set<String> _seen = {};
  bool get _owns => !_closed && currentOwner() == ownerUid;

  Future<void> observe(
    String event, {
    String? babyId,
    String? sourceId,
    String? result,
    String locale = 'unknown',
    String platform = 'unknown',
    bool oncePerDay = false,
  }) {
    final at = clock().toUtc();
    final day = at
        .add(const Duration(hours: 7))
        .toIso8601String()
        .substring(0, 10);
    final key = '$event/$babyId/$day/$locale';
    if (oncePerDay && !_seen.add(key)) return Future.value();
    _serial = _serial
        .then((_) async {
          if (!_owns) return;
          final rows = _load();
          rows.add({
            'schemaVersion': 1,
            'receiptId': const Uuid().v4(),
            'ownerUid': ownerUid,
            'occurredAt': at.toIso8601String(),
            'event': event,
            'platform': platform,
            'locale': locale,
            'babyId': ?babyId,
            'sourceId': ?sourceId,
            'result': ?result,
          });
          await write(
            jsonEncode(
              rows.length > 50 ? rows.sublist(rows.length - 50) : rows,
            ),
          );
          if (!_owns) {
            // A preferences write may finish after logout cleared the namespace.
            await remove();
            return;
          }
          if (_owns) await _flush();
        })
        .catchError((Object _) {
          /* Measurement never fails a domain action or logs payloads. */
        });
    return _serial;
  }

  List<Map<String, Object?>> _load() {
    try {
      final rows = jsonDecode(read() ?? '[]');
      if (rows is! List) return [];
      final cutoff = clock().toUtc().subtract(const Duration(days: 3));
      return [
        for (final row in rows)
          if (row is Map &&
              row['ownerUid'] == ownerUid &&
              (DateTime.tryParse('${row['occurredAt']}')?.isAfter(cutoff) ??
                  false))
            row.cast<String, Object?>(),
      ];
    } on Object {
      return [];
    }
  }

  Future<void> flush() {
    _serial = _serial.then((_) => _flush()).catchError((Object _) {});
    return _serial;
  }

  Future<void> _flush() async {
    if (!_owns || _sending) return;
    _sending = true;
    try {
      final rows = _load();
      while (rows.isNotEmpty && _owns) {
        try {
          await send(rows.first).timeout(const Duration(seconds: 8));
        } on FirebaseFunctionsException catch (e) {
          if (![
            'permission-denied',
            'invalid-argument',
            'not-found',
          ].contains(e.code)) {
            rethrow;
          }
        }
        if (!_owns) return;
        rows.removeAt(0);
        await write(jsonEncode(rows));
      }
    } finally {
      _sending = false;
    }
  }

  void close() {
    _closed = true;
    unawaited(remove().catchError((Object _) {}));
  }
}

final productAnalyticsReporterProvider = Provider<ProductAnalyticsReporter?>((
  ref,
) {
  final uid = ref.watch(
    sessionProvider.select(
      (s) => s is SessionSignedIn && !s.isAnonymous ? s.user.uid : null,
    ),
  );
  if (uid == null) return null;
  final prefs = ref.read(sharedPreferencesProvider);
  final key = 'productAnalytics.outbox.$uid';
  final reporter = ProductAnalyticsReporter(
    ownerUid: uid,
    currentOwner: () {
      final s = ref.read(sessionProvider);
      return s is SessionSignedIn ? s.user.uid : null;
    },
    read: () => prefs.getString(key),
    write: (s) async {
      await prefs.setString(key, s);
    },
    remove: () async {
      await prefs.remove(key);
    },
    send: (row) async {
      await ref
          .read(functionsProvider)
          .httpsCallable('recordAnalyticsObservation')
          .call<Object?>(row);
    },
  );
  ref.onDispose(reporter.close);
  return reporter;
});

String get productAnalyticsPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.iOS => 'ios',
  TargetPlatform.android => 'android',
  _ => 'unknown',
};

/// Counts real foregrounds even before onboarding creates a baby or grants push permission.
class ProductAnalyticsScope extends ConsumerStatefulWidget {
  const ProductAnalyticsScope({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<ProductAnalyticsScope> createState() =>
      _ProductAnalyticsScopeState();
}

class _ProductAnalyticsScopeState extends ConsumerState<ProductAnalyticsScope> {
  late final AppLifecycleListener _lifecycle;
  String? _last;
  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _last = null;
        if (mounted) {
          unawaited(ref.read(productAnalyticsReporterProvider)?.flush());
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reporter = ref.watch(productAnalyticsReporterProvider);
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'vi';
    final day = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 7))
        .toIso8601String()
        .substring(0, 10);
    final key = '${reporter?.ownerUid}/$day/$locale';
    if (reporter != null && key != _last) {
      _last = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            reporter.observe(
              'app_foreground_observed',
              locale: locale,
              platform: productAnalyticsPlatform,
              // Server deduplicates daily receipts; retry after a same-day flag activation.
              oncePerDay: false,
            ),
          );
        }
      });
    }
    return widget.child;
  }
}
