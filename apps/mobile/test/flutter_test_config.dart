import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled Be Vietnam Pro so widget and golden tests render real glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Be Vietnam Pro');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    final bytes = File(
      'assets/fonts/BeVietnamPro-$weight.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  await testMain();
}
