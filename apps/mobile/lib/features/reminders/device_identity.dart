import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/appearance/appearance_providers.dart';

/// This install, as the device that holds reminder notifications ("iPhone của Mai", 8e).
/// The id is random per install — never a hardware identifier — and the label is the model
/// name the OS reports ("iPhone", "iPad", "Pixel 8").
@immutable
class DeviceIdentity {
  const DeviceIdentity({required this.id, required this.label});
  final String id;
  final String label;
}

final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  var id = prefs.getString('device.id');
  if (id == null || !RegExp(r'^d_[a-f0-9]{32}$').hasMatch(id)) {
    id = 'd_${const Uuid().v4().replaceAll('-', '')}';
    await prefs.setString('device.id', id);
  }
  return DeviceIdentity(id: id, label: await _modelName());
});

Future<String> _modelName() async {
  final fallback = switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'iPhone',
    TargetPlatform.android => 'Android',
    _ => 'Device',
  };
  try {
    final info = DeviceInfoPlugin();
    final name = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => (await info.iosInfo).model,
      TargetPlatform.android => (await info.androidInfo).model,
      _ => fallback,
    };
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
  } on Object {
    return fallback;
  }
}
