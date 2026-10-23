import 'package:flutter/foundation.dart';
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
/// Navigator asserts (`!keyReservation.contains(key)`): the flow freezes (D-076 #14).
///
/// Every tab page below a tab root therefore has an "overlay twin" on the root navigator
/// ([OverlayTwin], `/o/care/history` for `/care/history`): the same builders, params, `extra` and
/// redirects, without the shell. A tab page opened from above the shell opens as its twin ON TOP
/// of the page that opened it, so Back (the button, Android back, iOS swipe) returns there with
/// its state (owner: "mở nhật ký từ Lumi chat, khi back lại thì nó về Home"). [SafeGoRouter] does
/// this for every `push` / `pushReplacement` / `replace`, so links inside a twin stack too; only
/// a tab root (no twin) still closes the full-screen pages first and opens inside the tabs.
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

  /// True when, once the top page is gone, a full-screen page still sits above the tab shell
  /// (what a `pushReplacement` / `replace` lands on).
  bool get _aboveShellUnderTop {
    final matches = routerDelegate.currentConfiguration.matches;
    return matches.length >= 2 &&
        matches.last is! ShellRouteMatch &&
        matches[matches.length - 2] is! ShellRouteMatch &&
        matches.any((m) => m is ShellRouteMatch);
  }

  /// The overlay twin of the tab page [location] (query kept), or null for a tab root, a page
  /// that is not a tab page, or a router without twins.
  String? overlayTwinOf(String location) {
    if (OverlayTwin.isTwin(location) || !isTabLocation(location)) return null;
    final twin = OverlayTwin.of(location);
    final match = configuration.findMatch(Uri.parse(twin));
    // A tab root's twin is a single match: it opens in the tabs instead (with the dock).
    return !match.isError && match.matches.length > 1 ? twin : null;
  }

  /// Where a notification's destination opens (push or Hộp thông báo): on top of what shows,
  /// like any push. A tab root that carries a query (a recap week from Smart Engagement) opens
  /// as its overlay twin, a page with its own Back, so Back returns to the screen or the inbox
  /// underneath instead of the tab root being replaced; a bare tab root opens in the tabs.
  String notificationLocation(String location) {
    final uri = Uri.parse(location);
    return uri.hasQuery &&
            isTabLocation(location) &&
            overlayTwinOf(location) == null &&
            !OverlayTwin.isTwin(location)
        ? OverlayTwin.of(location)
        : location;
  }

  /// Closes the full-screen pages above the shell (the tab pages under them stay).
  void _leaveAboveShell() {
    // Each pop updates the configuration synchronously (as `closeFlow` relies on); the bound
    // only guards against a pop that is refused.
    for (var i = 0; i < 64 && aboveShell && canPop(); i++) {
      pop();
    }
  }

  /// Pushes [location] (with [extra]); a tab page opened from above the shell opens as its
  /// overlay twin on top of the opener (Back returns to it), or, for a tab root, after closing
  /// the full-screen pages over the shell. [replace]: `pushReplacement`.
  Future<T?> pushSafe<T extends Object?>(
    String location, {
    Object? extra,
    bool replace = false,
  }) {
    if (aboveShell && isTabLocation(location)) {
      final twin = overlayTwinOf(location);
      if (twin != null) {
        return replace
            ? pushReplacement<T>(twin, extra: extra)
            : push<T>(twin, extra: extra);
      }
      _leaveAboveShell();
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

/// D-076 nav: root-level twins of the tab pages, `/o` + the tab location.
abstract final class OverlayTwin {
  static const prefix = '/o';

  /// `/care/history?filter=growth` → `/o/care/history?filter=growth`.
  static String of(String location) => '$prefix$location';

  static bool isTwin(String location) =>
      location == prefix || location.startsWith('$prefix/');

  /// The tab location a twin stands for (anything else unchanged): for code that compares
  /// the current location with a tab route.
  static String original(String location) =>
      isTwin(location) ? location.substring(prefix.length) : location;
}

/// [routes] plus a root-level twin of every tab branch's routes (D-076 nav): the same paths
/// under [OverlayTwin.prefix], builders and page builders reused as they are, and redirects that
/// land on a tab page sent to its twin (a redirect to the shell from above it would build a
/// second shell). Pushed, only the twin's last page is built, so a twin sits alone on the opener.
List<RouteBase> withOverlayTwins(List<RouteBase> routes) {
  final tabRoots = [
    for (final r in routes)
      if (r is ShellRouteBase) ...r.routes.whereType<GoRoute>(),
  ];
  final rootPaths = [for (final g in tabRoots) g.path];
  String? toTwin(String? location) {
    if (location == null) return null;
    final path = Uri.parse(location).path;
    final tab = rootPaths.any((p) => path == p || path.startsWith('$p/'));
    return tab ? OverlayTwin.of(location) : location;
  }

  GoRouterRedirect? redirectOf(GoRouterRedirect? redirect) => redirect == null
      ? null
      : (context, state) {
          final to = redirect(context, state);
          return to is Future<String?> ? to.then(toTwin) : toTwin(to);
        };

  GoRoute twin(GoRoute g, {String? path}) => GoRoute(
    path: path ?? g.path,
    name: g.name == null ? null : 'overlay.${g.name}',
    builder: g.builder,
    pageBuilder: g.pageBuilder,
    redirect: redirectOf(g.redirect),
    metadata: g.metadata,
    onExit: g.onExit,
    caseSensitive: g.caseSensitive,
    routes: [
      for (final c in g.routes)
        if (c is GoRoute) twin(c),
    ],
  );

  return [
    ...routes,
    for (final g in tabRoots) twin(g, path: OverlayTwin.of(g.path)),
  ];
}

/// The app's router (D-076 nav): [withOverlayTwins] routes, and every `push`,
/// `pushReplacement` and `replace` of a tab page from above the shell goes to its overlay twin,
/// on top of the page that opened it, including links from screens that never heard of
/// [SafePush.pushSafe]; a tab root still closes the full-screen pages first. Inside the shell
/// nothing changes.
class SafeGoRouter extends GoRouter {
  SafeGoRouter({
    required List<RouteBase> routes,
    required GoRouterRedirect redirect,
    super.refreshListenable,
    super.initialLocation,
  }) : super.routingConfig(
         routingConfig: _FixedRoutingConfig(
           RoutingConfig(routes: withOverlayTwins(routes), redirect: redirect),
         ),
       );

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    if (aboveShell && isTabLocation(location)) {
      final twin = overlayTwinOf(location);
      if (twin != null) return super.push<T>(twin, extra: extra);
      _leaveAboveShell();
    }
    return super.push<T>(location, extra: extra);
  }

  @override
  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) {
    if (_aboveShellUnderTop && isTabLocation(location)) {
      final twin = overlayTwinOf(location);
      if (twin != null) return super.pushReplacement<T>(twin, extra: extra);
      _leaveAboveShell();
      return super.push<T>(location, extra: extra);
    }
    return super.pushReplacement<T>(location, extra: extra);
  }

  @override
  Future<T?> replace<T>(String location, {Object? extra}) {
    if (_aboveShellUnderTop && isTabLocation(location)) {
      final twin = overlayTwinOf(location);
      if (twin != null) return super.replace<T>(twin, extra: extra);
      _leaveAboveShell();
      return super.push<T>(location, extra: extra);
    }
    return super.replace<T>(location, extra: extra);
  }
}

class _FixedRoutingConfig extends ValueListenable<RoutingConfig> {
  _FixedRoutingConfig(this.value);

  @override
  final RoutingConfig value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
