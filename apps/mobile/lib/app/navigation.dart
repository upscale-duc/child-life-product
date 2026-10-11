import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'route_guard.dart';

extension PopOrToday on BuildContext {
  /// Back from a screen that a widget or Live Activity link can open on its own: the deep
  /// link replaces the stack, so with nothing underneath, Hôm nay is "back".
  void popOrToday() => canPop() ? pop() : go(Routes.today);
}
