import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An opaque launch token survives the account widget remount during sign-in.
/// No route or child data is cached; the server reauthorizes it after sign-in.
class EngagementLaunchQueue {
  String? _id;
  DateTime? _expires;
  void put(String id, {DateTime? now}) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) return;
    _id = id;
    _expires = (now ?? DateTime.now()).add(const Duration(minutes: 10));
  }

  String? take({DateTime? now}) {
    final id = _expires?.isAfter(now ?? DateTime.now()) == true ? _id : null;
    _id = null;
    _expires = null;
    return id;
  }
}

final engagementLaunchQueueProvider = Provider(
  (ref) => EngagementLaunchQueue(),
);
