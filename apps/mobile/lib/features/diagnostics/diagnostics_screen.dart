import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/environment.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'diagnostics_providers.dart';

/// Temporary S0 screen: proves environment wiring on real devices. Replaced in S2.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final environment = ref.watch(environmentProvider);
    final ping = ref.watch(pingProvider);
    final flags = ref.watch(publicFlagsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.diagnosticsEnvironment),
            subtitle: Text(environment.name),
          ),
          ListTile(
            title: Text(l10n.diagnosticsServer),
            subtitle: Text(
              ping.when(
                data: (r) => l10n.diagnosticsConnected(r.projectId, r.region),
                loading: () => l10n.diagnosticsChecking,
                error: (e, _) => l10n.diagnosticsUnreachable('$e'),
              ),
            ),
            trailing: IconButton(
              tooltip: l10n.diagnosticsRetry,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(pingProvider),
            ),
          ),
          ListTile(
            title: Text(l10n.diagnosticsFlags),
            subtitle: Text(
              flags.when(
                data: (f) => f.isEmpty
                    ? l10n.diagnosticsFlagsEmpty
                    : l10n.diagnosticsFlagsCount(
                        f.values.where((v) => v).length,
                        f.length,
                      ),
                loading: () => l10n.diagnosticsLoading,
                error: (e, _) => l10n.diagnosticsUnreadable('$e'),
              ),
            ),
          ),
          if (environment == AppEnvironment.dev)
            ListTile(
              title: const Text('Design system'),
              trailing: const Icon(Icons.palette_outlined),
              onTap: () => context.push('/showcase'),
            ),
          if (environment == AppEnvironment.dev)
            ListTile(
              title: Text(l10n.diagnosticsTestCrash),
              subtitle: Text(l10n.diagnosticsDevOnly),
              trailing: const Icon(Icons.bug_report_outlined),
              onTap: () => FirebaseCrashlytics.instance.crash(),
            ),
        ],
      ),
    );
  }
}
