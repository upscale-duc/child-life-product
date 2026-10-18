import 'package:flutter/widgets.dart';

/// A tap on anything that is not a control closes the keyboard; iOS and Android otherwise
/// leave it up until a screen says so. It wraps the whole app (`MaterialApp.builder`), so every
/// screen, sheet and dialog gets it. Whatever is under the finger wins first: a button, another
/// field (the keyboard stays) or a scroll.
class ClKeyboardDismiss extends StatelessWidget {
  const ClKeyboardDismiss({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    onTap: dismissKeyboard,
    child: child,
  );
}

/// Unfocuses the text field being typed in, if any (other focus, such as a hardware keyboard's,
/// stays).
void dismissKeyboard() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) {
    focus!.unfocus();
  }
}
