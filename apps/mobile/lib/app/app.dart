import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/appearance/appearance_providers.dart';
import '../core/design/cl_theme.dart';
import '../core/design/tokens.g.dart';
import '../features/auth/auth_repository.dart';
import '../l10n/app_localizations.dart';
import 'locale.dart';
import 'router.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class ChildLifeApp extends ConsumerStatefulWidget {
  const ChildLifeApp({super.key});

  @override
  ConsumerState<ChildLifeApp> createState() => _ChildLifeAppState();
}

class _ChildLifeAppState extends ConsumerState<ChildLifeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// "Tự động" follows the system appearance (P-061).
  @override
  void didChangePlatformBrightness() {
    ref
        .read(platformBrightnessProvider.notifier)
        .set(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildClTheme(palette),
      themeAnimationDuration: ClMotion.gentle,
      themeAnimationCurve: Curves.easeInOut,
      locale: ref.watch(localeOverrideProvider),
      supportedLocales: supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      localeListResolutionCallback: (locales, _) => resolveLocale(locales),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Auth emails (verification, reset) follow the app language (D-012).
        ref
            .read(authRepositoryProvider)
            .setLanguage(Localizations.localeOf(context).languageCode);
        return child!;
      },
    );
  }
}

/// Shown instead of the app when the build's environment configuration is inconsistent.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildClTheme(ClPalette.light),
      supportedLocales: supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      localeListResolutionCallback: (locales, _) => resolveLocale(locales),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${AppLocalizations.of(context).configErrorTitle}\n\n$message',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
