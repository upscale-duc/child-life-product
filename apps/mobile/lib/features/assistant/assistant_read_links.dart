/// Phase 2 destinations are read-only module screens. Never follow an arbitrary server URL.
String? assistantReadRoute(String? link) {
  final uri = link == null ? null : Uri.tryParse(link);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.fragment.isNotEmpty) {
    return null;
  }
  final path = uri.path;
  if (uri.pathSegments.any(
    (s) => !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(s),
  )) {
    return null;
  }
  const exact = {
    '/today',
    '/care',
    '/care/history',
    '/care/stats/feed',
    '/care/stats/sleep',
    '/care/growth',
    '/care/vaccines',
    '/care/reminders',
    '/care/solids',
    '/care/solids/history',
    '/utilities/spending',
    '/utilities/spending/budget',
    '/utilities/milestones',
    '/utilities/first-aid',
    '/library',
    '/stages',
  };
  final detail = RegExp(
    r'^/(care/record|care/reminders|care/reminders/rules|care/vaccines/dose|care/solids/food|care/solids/recipe|utilities/milestones|utilities/first-aid/s|library/a|stages)/[A-Za-z0-9_-]{1,128}$',
  );
  final timer = RegExp(r'^/care/timer/(sleep|breast|pump)$');
  if (!exact.contains(path) &&
      !detail.hasMatch(path) &&
      !timer.hasMatch(path)) {
    return null;
  }
  if (uri.queryParametersAll.values.any((values) => values.length != 1)) {
    return null;
  }
  for (final e in uri.queryParameters.entries) {
    final allowed = switch ((path, e.key)) {
      ('/care/history', 'filter') => const {
        'all',
        'feed',
        'sleep',
        'pump',
        'diaper',
        'growth',
        'solids',
      }.contains(e.value),
      ('/care/solids/history', 'tab') => const {
        'foods',
        'calendar',
      }.contains(e.value),
      _ => false,
    };
    if (!allowed) return null;
  }
  return uri.toString();
}
