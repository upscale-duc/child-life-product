import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'route_guard.dart';

extension PopOrToday on BuildContext {
  /// Back from a screen that a widget or Live Activity link can open on its own: the deep
  /// link replaces the stack, so with nothing underneath, Hôm nay is "back".
  void popOrToday() => canPop() ? pop() : go(Routes.today);
}

/// D-076 nav: opening a location from anywhere without building a second tab shell.
///
/// The tab pages (Hôm nay, Kỷ niệm, Chăm sóc, Tiện ích and everything under them) live inside the
/// `StatefulShellRoute`; Nhịp lớn lên, Thư viện, Trợ lý, Tôi, Premium and the other full-screen
/// pages sit above it on the root navigator. A plain `push` of a tab page while such a page is on
/// top makes go_router build another shell on the root navigator with the same page keys, and the
/// Navigator asserts (`!keyReservation.contains(key)`): the flow freezes (D-076 #14). [pushSafe]
/// first leaves the full-screen pages above the shell (the tab pages under them stay), then
/// pushes, keeping `extra`; anything else is a plain push. Use it for every push whose target is
/// a tab page and whose caller may sit above the shell, or runs after a pop or a notification tap
/// from an unknown place.
extension SafePush on GoRouter {
  /// True when [location] is a page of a tab branch (inside the shell).
  bool isTabLocation(String location) {
    final match = configuration.findMatch(Uri.parse(location));
    return !match.isError && match.matches.any((m) => m is ShellRouteMatch);
  }

  /// True when a full-screen page (or several) sits above the tab shell.
  bool get aboveShell {
    final matches = routerDelegate.currentConfiguration.matches;
    return matches.isNotEmpty &&
        matches.last is! ShellRouteMatch &&
        matches.any((m) => m is ShellRouteMatch);
  }

  /// Pushes [location] (with [extra]); a tab page opened from above the shell first closes the
  /// full-screen pages over it. [replace]: `pushReplacement` when nothing has to close (closing
  /// them already takes the current page away).
  Future<T?> pushSafe<T extends Object?>(
    String location, {
    Object? extra,
    bool replace = false,
  }) {
    if (aboveShell && isTabLocation(location)) {
      // Each pop updates the configuration synchronously (as `closeFlow` relies on); the bound
      // only guards against a pop that is refused.
      for (var i = 0; i < 64 && aboveShell && canPop(); i++) {
        pop();
      }
      return push<T>(location, extra: extra);
    }
    return replace
        ? pushReplacement<T>(location, extra: extra)
        : push<T>(location, extra: extra);
  }
}

extension SafePushContext on BuildContext {
  /// [SafePush.pushSafe] on this context's router (D-076 nav).
  Future<T?> pushSafe<T extends Object?>(
    String location, {
    Object? extra,
    bool replace = false,
  }) => GoRouter.of(this).pushSafe<T>(location, extra: extra, replace: replace);
}
