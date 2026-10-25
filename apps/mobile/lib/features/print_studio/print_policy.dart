import 'package:flutter/material.dart';
import '../../core/design/cl_theme.dart';
import '../../l10n/app_localizations.dart';
import 'print_models.dart';
import 'print_ui.dart';
import 'print_widgets.dart';

void showPrintPolicy(BuildContext context, PrintCatalog catalog) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PrintPolicy(catalog: catalog)),
    );

class PrintPolicy extends StatelessWidget {
  const PrintPolicy({required this.catalog, super.key});
  final PrintCatalog catalog;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), cl = context.cl;
    Widget section(String title, String content, IconData icon) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: psText(context, 17, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          PrintCard(
            lifted: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: cl.colors.mintText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(content, style: psText(context, 13, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: Column(
          children: [
            PrintHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                children: [
                  Text(
                    l.psPolicy,
                    style: psText(context, 24, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.psPolicyIntro,
                    style: psText(context, 13, color: cl.colors.inkMuted),
                  ),
                  const SizedBox(height: 20),
                  section(
                    l.psPayment,
                    l.psNoDepositHelp,
                    Icons.payments_outlined,
                  ),
                  section(
                    l.psShippingAndPayment,
                    '${l.psManualOrderNote}\n${l.psPolicyDeliveryHelp}',
                    Icons.local_shipping_outlined,
                  ),
                  section(
                    l.psPolicyCancelTitle,
                    l.psPolicyCancelHelp,
                    Icons.close,
                  ),
                  section(
                    l.psPolicyReturnTitle,
                    l.psPolicyReturnHelp,
                    Icons.verified_outlined,
                  ),
                  section(
                    l.psPolicyPrivacyTitle,
                    l.psPolicyPrivacyHelp,
                    Icons.lock_outline,
                  ),
                  if (catalog
                      .policy(Localizations.localeOf(context).languageCode)
                      .isNotEmpty)
                    Text(
                      catalog.policy(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: psText(context, 12, color: cl.colors.inkMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
