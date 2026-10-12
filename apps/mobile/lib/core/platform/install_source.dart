import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../appearance/appearance_providers.dart';

/// How this install arrived (A13 "Nguồn gia đình mới", P-137, Q-042 default). Android only: the
/// Play install referrer, read once after install, tells the landing site's store links
/// (`utm_source=website`, or a referrer naming childlife.app) from the rest of the store. iOS
/// cannot tell without a third-party SDK and sends nothing; the invite channel is set by the
/// server when an invite is redeemed.
enum InstallChannel { website, store, unknown }

/// The channel a Play install referrer stands for. An empty referrer is not known; any other
/// referrer that is not the landing site is the store.
InstallChannel channelOfReferrer(String? referrer) {
  final raw = referrer?.trim() ?? '';
  if (raw.isEmpty) return InstallChannel.unknown;
  String decoded;
  try {
    decoded = Uri.decodeComponent(raw);
  } on Object {
    decoded = raw;
  }
  String? source;
  try {
    source = Uri.splitQueryString(decoded)['utm_source'];
  } on Object {
    source = null;
  }
  if (source?.trim().toLowerCase() == 'website' ||
      decoded.toLowerCase().contains('childlife.app')) {
    return InstallChannel.website;
  }
  return InstallChannel.store;
}

/// Reads the referrer once per install (kept in preferences), then reports it once per account
/// through `recordInstallSource` (the server keeps the first answer).
class InstallSourceReporter {
  InstallSourceReporter({
    required this._prefs,
    required this.android,
    required this._readReferrer,
    required this._send,
  });

  final SharedPreferences _prefs;
  final bool android;
  final Future<String?> Function() _readReferrer;
  final Future<void> Function(InstallChannel channel) _send;

  static const _kChannel = 'install.channel';
  static String _sentKey(String uid) => 'install.sent.$uid';

  Future<InstallChannel>? _reading;

  /// The channel of this install: read from Play the first time (on Android only), then
  /// remembered; concurrent callers share the one read.
  Future<InstallChannel> channel() async {
    final pending = _reading ??= _channel();
    try {
      return await pending;
    } on Object {
      if (identical(_reading, pending)) _reading = null;
      rethrow;
    }
  }

  Future<InstallChannel> _channel() async {
    final saved = InstallChannel.values
        .asNameMap()[_prefs.getString(_kChannel)];
    if (saved != null) return saved;
    if (!android) return InstallChannel.unknown;
    InstallChannel found;
    try {
      found = channelOfReferrer(await _readReferrer());
    } on Object {
      // Not installed from Play, no Play services, or the service is down.
      found = InstallChannel.unknown;
    }
    await _prefs.setString(_kChannel, found.name);
    return found;
  }

  /// Sends the channel for [uid] unless it was sent already; a failure retries next time.
  Future<void> report(String uid) async {
    if (!android || _prefs.getBool(_sentKey(uid)) == true) return;
    final found = await channel();
    await _send(found);
    await _prefs.setBool(_sentKey(uid), true);
  }
}

final installSourceReporterProvider = Provider<InstallSourceReporter>(
  (ref) => InstallSourceReporter(
    prefs: ref.watch(sharedPreferencesProvider),
    android: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    readReferrer: () async =>
        (await PlayInstallReferrer.installReferrer).installReferrer,
    send: (channel) => ref
        .read(functionsProvider)
        .httpsCallable('recordInstallSource')
        .call<Object?>({'channel': channel.name}),
  ),
);
