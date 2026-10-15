import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'billing_models.dart';

/// PR02 · Mua/Trạng thái (592:6781): Pending / Success / Error / Restore, plus what Figma does
/// not draw: restore results (restored, nothing to restore, bound to another household), the
/// owner-only refusal and the server / network errors.
enum PurchaseSheetKind {
  pending,
  success,
  storeError,
  networkError,
  verifyError,
  restoreConfirm,
  restored,
  nothingToRestore,
  alreadyBound,
  notOwner,
}

enum PurchaseSheetAction { primary, secondary, dismissed }

Future<PurchaseSheetAction> showPurchaseSheet(
  BuildContext context,
  PurchaseSheetKind kind, {
  required PaywallEntry entry,
  PurchaseResume? resume,
  String? templateName,
}) async {
  final action = await showClSheet<PurchaseSheetAction>(
    context: context,
    // Success resumes exactly once: it is answered, not swiped away.
    dismissible:
        kind != PurchaseSheetKind.success && kind != PurchaseSheetKind.restored,
    builder: (sheet) => PurchaseStatusView(
      kind: kind,
      entry: entry,
      resume: resume,
      templateName: templateName,
      onAction: (a) => Navigator.of(sheet).pop(a),
    ),
  );
  return action ?? PurchaseSheetAction.dismissed;
}

/// One state of the purchase sheet: icon chip, title, body, buttons (592:6781 layout).
class PurchaseStatusView extends StatelessWidget {
  const PurchaseStatusView({
    required this.kind,
    required this.entry,
    required this.onAction,
    this.resume,
    this.templateName,
    super.key,
  });

  final PurchaseSheetKind kind;
  final PaywallEntry entry;
  final PurchaseResume? resume;
  final String? templateName;
  final ValueChanged<PurchaseSheetAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final template =
        resume != null &&
        resume!.kind != ResumeKind.rhythm &&
        entry == PaywallEntry.templates;
    final (ClIcons icon, Color chip, Color ink) = switch (kind) {
      PurchaseSheetKind.success || PurchaseSheetKind.restored => (
        ClIcons.check,
        cl.colors.mintSoft,
        cl.colors.mintText,
      ),
      PurchaseSheetKind.storeError ||
      PurchaseSheetKind.networkError ||
      PurchaseSheetKind.verifyError ||
      PurchaseSheetKind.alreadyBound => (
        ClIcons.alert,
        cl.colors.errorSoft,
        cl.colors.error,
      ),
      PurchaseSheetKind.restoreConfirm => (
        ClIcons.retry,
        cl.colors.surface2,
        cl.colors.ink,
      ),
      PurchaseSheetKind.notOwner => (
        ClIcons.family,
        cl.colors.surface2,
        cl.colors.ink,
      ),
      _ => (ClIcons.clock, cl.colors.surface2, cl.colors.inkMuted),
    };
    final successBody = template && templateName != null
        ? l10n.pmSuccessTemplate(templateName!)
        : l10n.pmSuccessRhythm;
    final continueLabel = switch (resume?.kind) {
      ResumeKind.card when template => l10n.pmContinueCard,
      ResumeKind.video when template => l10n.pmContinueVideo,
      ResumeKind.assistant => l10n.asContinueQuestion,
      _ when entry == PaywallEntry.rhythm => l10n.pmBackToRhythm,
      _ => l10n.pmDone,
    };
    final errorSecondary = template ? l10n.pmUseFreeTemplate : l10n.pmClose;
    final (
      String title,
      String body,
      String primary,
      String? secondary,
    ) = switch (kind) {
      PurchaseSheetKind.pending => (
        l10n.pmPendingTitle,
        template ? l10n.pmPendingBody : l10n.pmPendingBodyPlain,
        l10n.pmCheckAgain,
        l10n.pmClose,
      ),
      PurchaseSheetKind.success => (
        l10n.pmSuccessTitle,
        successBody,
        continueLabel,
        null,
      ),
      PurchaseSheetKind.storeError => (
        l10n.pmErrorTitle,
        template ? l10n.pmErrorBody : l10n.pmErrorBodyPlain,
        l10n.pmTryAgain,
        errorSecondary,
      ),
      PurchaseSheetKind.networkError => (
        l10n.pmErrorTitle,
        l10n.pmErrorNetworkBody,
        l10n.pmTryAgain,
        errorSecondary,
      ),
      PurchaseSheetKind.verifyError => (
        l10n.pmErrorTitle,
        l10n.pmErrorVerifyBody,
        l10n.pmTryAgain,
        errorSecondary,
      ),
      PurchaseSheetKind.restoreConfirm => (
        l10n.pmRestoreTitle,
        l10n.pmRestoreBody,
        l10n.pmRestore,
        l10n.pmCancel,
      ),
      PurchaseSheetKind.restored => (
        l10n.pmRestoredTitle,
        l10n.pmRestoredBody,
        template ? continueLabel : l10n.pmDone,
        null,
      ),
      PurchaseSheetKind.nothingToRestore => (
        l10n.pmRestoreNoneTitle,
        l10n.pmRestoreNoneBody,
        l10n.pmClose,
        null,
      ),
      PurchaseSheetKind.alreadyBound => (
        l10n.pmRestoreBoundTitle,
        l10n.pmRestoreBoundBody,
        l10n.pmClose,
        null,
      ),
      PurchaseSheetKind.notOwner => (
        l10n.pmNotOwnerTitle,
        l10n.pmNotOwnerBody,
        l10n.pmClose,
        null,
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s2),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: chip, shape: BoxShape.circle),
            child: ClIcon(icon, size: 22, color: ink),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Semantics(header: true, child: Text(title, style: cl.text.title2)),
        const SizedBox(height: ClSpace.s2),
        Text(body, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: primary,
          expand: true,
          onPressed: () => onAction(PurchaseSheetAction.primary),
        ),
        if (secondary != null) ...[
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: secondary,
            expand: true,
            style: ClButtonStyle.secondary,
            onPressed: () => onAction(PurchaseSheetAction.secondary),
          ),
        ],
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}
