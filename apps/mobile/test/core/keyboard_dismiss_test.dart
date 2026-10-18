import 'package:child_life/core/widgets/cl_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a tap outside a field closes the keyboard; a button keeps it', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => ClKeyboardDismiss(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: Key('field')),
              TextButton(
                onPressed: () => pressed++,
                child: const Text('button'),
              ),
              const SizedBox(height: 300, child: Text('empty')),
            ],
          ),
        ),
      ),
    );
    bool focused() => tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode
        .hasFocus;

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(focused(), isTrue);

    await tester.tap(find.text('button'));
    await tester.pump();
    expect(pressed, 1);
    expect(focused(), isTrue);

    await tester.tap(find.text('empty'));
    await tester.pump();
    expect(focused(), isFalse);
  });
}
