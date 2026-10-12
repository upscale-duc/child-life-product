import 'dart:convert';
import 'dart:io';

import 'package:child_life/features/first_aid/first_aid_models.dart';
import 'package:child_life/features/first_aid/first_aid_modes.dart';
import 'package:child_life/features/first_aid/first_aid_repository.dart';
import 'package:flutter/painting.dart';

import 'memory_fixtures.dart';

/// Sơ cứu fixtures (D-058): the real seed pack (content/first-aid/pack.seed.json) with every
/// picture slug standing in for its id, as the app would get it from `publicConfig`.
FirstAidPack seedFirstAidPack() {
  final file = File('../../content/first-aid/pack.seed.json');
  final pack = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return FirstAidPack.fromDoc({'version': 'fa_20261012_01', 'pack': pack})!;
}

/// Pictures: a flat colour (no network, no disk).
ImageProvider fakeFirstAidImage(String id) =>
    MemoryImage(pngOf(id.startsWith('icon-') ? 'mint' : 'peach'));

/// Records what the guided modes ask of the device.
class FakeFirstAidDevice implements FirstAidDevice {
  final awake = <bool>[];
  var beats = 0;
  final dialled = <String>[];

  @override
  Future<void> keepAwake(bool on) async => awake.add(on);

  @override
  Future<void> beat() async => beats++;

  final spoken = <String>[];

  @override
  Future<void> speak(String text, Locale locale) async => spoken.add(text);

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<bool> dial(String number) async {
    dialled.add(number);
    return true;
  }

  @override
  Future<void> dispose() async {}
}

/// Records "Lưu" / "Bỏ lưu".
class FakeFirstAidStore implements FirstAidStore {
  final saved = <List<String>>[];

  @override
  Future<void> setSaved(String uid, List<String> ids) async => saved.add(ids);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
