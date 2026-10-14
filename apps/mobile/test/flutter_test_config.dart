import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts (Be Vietnam Pro; Lora and Dancing Script for stories and cards, S13)
/// so widget and golden tests render real glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (family, files) in const [
    (
      'Be Vietnam Pro',
      ['BeVietnamPro-Regular', 'BeVietnamPro-Medium', 'BeVietnamPro-SemiBold'],
    ),
    (
      'Lora',
      ['Lora-Regular', 'Lora-Italic', 'Lora-SemiBold', 'Lora-SemiBoldItalic'],
    ),
    ('Dancing Script', ['DancingScript-Regular', 'DancingScript-SemiBold']),
    (
      'Be Vietnam Pro Keepsake',
      [
        'BeVietnamPro-Regular',
        'BeVietnamPro-Medium',
        'BeVietnamPro-SemiBold',
        'BeVietnamPro-Bold',
      ],
    ),
    (
      'Playfair Display Keepsake',
      [
        'PlayfairDisplay-Regular',
        'PlayfairDisplay-Italic',
        'PlayfairDisplay-Bold',
      ],
    ),
    ('Baloo 2 Keepsake', ['Baloo2-Medium', 'Baloo2-Bold', 'Baloo2-ExtraBold']),
    ('Patrick Hand Keepsake', ['PatrickHand-Regular']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  await testMain();
}
