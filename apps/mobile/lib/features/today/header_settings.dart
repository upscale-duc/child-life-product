import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/appearance/appearance_providers.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;

enum HeaderBackground { pattern, avatar, memory }

@immutable
class HeaderSettings {
  const HeaderSettings({
    this.background = HeaderBackground.pattern,
    this.mediaId,
    this.showDuty = true,
  });
  final HeaderBackground background;
  final String? mediaId;
  final bool showDuty;

  HeaderSettings copyWith({
    HeaderBackground? background,
    String? mediaId,
    bool? showDuty,
  }) => HeaderSettings(
    background: background ?? this.background,
    mediaId: mediaId ?? this.mediaId,
    showDuty: showDuty ?? this.showDuty,
  );
}

// Owner 27/10/2026: per device, scoped to account and baby. Never save a signed photo URL.
final headerSettingsProvider =
    NotifierProvider<HeaderSettingsController, HeaderSettings>(
      HeaderSettingsController.new,
    );

class HeaderSettingsController extends Notifier<HeaderSettings> {
  String get _key {
    final me = ref.read(selectedMembershipProvider);
    return 'today.header.${me?.uid}.${me?.babyId}';
  }

  @override
  HeaderSettings build() {
    final me = ref.watch(selectedMembershipProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final key = 'today.header.${me?.uid}.${me?.babyId}';
    Map<String, dynamic> saved = {};
    try {
      final decoded = jsonDecode(prefs.getString(key) ?? '{}');
      if (decoded is Map<String, dynamic>) saved = decoded;
    } on FormatException {
      // Corrupt local preferences fall back to artwork; never fail the Today screen.
    }
    return HeaderSettings(
      background:
          HeaderBackground.values.asNameMap()[saved['background']] ??
          HeaderBackground.pattern,
      mediaId: saved['media'] is String ? saved['media'] as String : null,
      showDuty: saved['duty'] is bool ? saved['duty'] as bool : true,
    );
  }

  Future<void> save(HeaderSettings next) async {
    final key = _key;
    final prefs = ref.read(sharedPreferencesProvider);
    // Publish after persistence; a failed write cannot masquerade as saved settings.
    final saved = await prefs.setString(
      key,
      jsonEncode({
        'background': next.background.name,
        'media': next.mediaId,
        'duty': next.showDuty,
      }),
    );
    if (!saved) throw StateError('header-preferences-not-saved');
    if (_key == key) state = next;
  }
}
