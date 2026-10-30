import 'package:flutter/widgets.dart' show Locale;

import '../../l10n/app_localizations.dart';

/// Titles the app writes for the family (Ăn dặm "Nhắc tôi khi bé gần 6 tháng", Dinh dưỡng "Đo
/// lại") are stored as text in the writer's language. Shown to a reader in another language, or
/// after the wording changed, they are read back in the reader's current wording; a title the
/// family typed or edited is shown as written.

typedef _Template = String Function(AppLocalizations l10n, String name);

final List<_Template> _templates = [
  (l, name) => l.sdReminderTitle(name),
  (l, _) => l.nuRemeasureWeight,
  (l, _) => l.nuRemeasureLength,
];

/// Earlier wordings still stored on reminders, each read as the template at the same index in
/// [_templates]. Matching only, never shown.
const _legacy = <int, List<String>>{
  0: [
    '{name} gần 6 tháng: xem cách bắt đầu ăn dặm',
    '{name} is nearly 6 months: how to start solids',
  ],
};

const _slot = '\u0000';

List<AppLocalizations>? _all;

/// The name in [stored] when it reads as [pattern] (with [_slot] where the name goes).
String? _match(String pattern, String stored) {
  final at = pattern.indexOf(_slot);
  if (at < 0) return pattern == stored ? '' : null;
  final head = pattern.substring(0, at);
  final tail = pattern.substring(at + _slot.length);
  if (stored.length <= head.length + tail.length ||
      !stored.startsWith(head) ||
      !stored.endsWith(tail)) {
    return null;
  }
  return stored.substring(head.length, stored.length - tail.length);
}

/// [stored] in [l10n]'s language when it is one of the app's own titles, else [stored].
String reminderTitle(AppLocalizations l10n, String stored) {
  final locales = _all ??= [
    for (final l in AppLocalizations.supportedLocales)
      lookupAppLocalizations(Locale(l.languageCode)),
  ];
  for (var i = 0; i < _templates.length; i++) {
    final patterns = [
      for (final l in locales) _templates[i](l, _slot),
      for (final p in _legacy[i] ?? const <String>[])
        p.replaceAll('{name}', _slot),
    ];
    for (final p in patterns) {
      final name = _match(p, stored);
      if (name != null) return _templates[i](l10n, name);
    }
  }
  return stored;
}
