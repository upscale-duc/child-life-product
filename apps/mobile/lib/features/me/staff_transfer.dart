import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/appearance/appearance_providers.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'me_models.dart';
import 'me_repository.dart';

/// Staff-initiated ownership transfer, owner side (Figma A17, P-136, G-091): Child Life Hỗ trợ
/// asks the current owner to hand the family to a Cùng nuôi of every baby. The owner agrees
/// or declines within 48 hours; agreeing makes the usual 13n offer (P-001 / P-003), which the
/// candidate accepts in the app as for any transfer.

/// Requests answered (or found gone) on this device, hidden until `users/{uid}` catches up.
final answeredStaffTransfersProvider =
    NotifierProvider<AnsweredStaffTransfers, Set<String>>(
      AnsweredStaffTransfers.new,
    );

class AnsweredStaffTransfers extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String transferId) => state = {...state, transferId};
}

/// [request] while it can still be answered: not expired (checked each minute) and not
/// answered here.
StaffTransferRequest? openStaffTransfer(
  WidgetRef ref,
  StaffTransferRequest? request,
) {
  if (request == null) return null;
  if (ref.watch(answeredStaffTransfersProvider).contains(request.transferId)) {
    return null;
  }
  final now = ref.watch(minuteClockProvider).value ?? DateTime.now();
  return request.isOpenAt(now) ? request : null;
}

/// "Hỗ trợ Child Life đề nghị chuyển quyền chủ hồ sơ" — Đồng ý (confirmed in a sheet) /
/// Không đồng ý. Shown on Tôi and in Tài khoản & đăng nhập › Chủ hồ sơ (13n).
class StaffTransferCard extends ConsumerStatefulWidget {
  const StaffTransferCard({required this.request, super.key});
  final StaffTransferRequest request;

  @override
  ConsumerState<StaffTransferCard> createState() => _StaffTransferCardState();
}

class _StaffTransferCardState extends ConsumerState<StaffTransferCard> {
  bool? _answering;

  Future<void> _agree() async {
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => _ConfirmAgreeSheet(to: widget.request.toMasked),
    );
    if (ok == true && mounted) await _answer(accept: true);
  }

  Future<void> _answer({required bool accept}) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final answered = ref.read(answeredStaffTransfersProvider.notifier);
    final request = widget.request;
    setState(() => _answering = accept);
    try {
      await ref
          .read(meRepositoryProvider)
          .answerStaffTransfer(request.transferId, accept: accept);
      answered.add(request.transferId);
      toaster.show(
        message: accept
            ? l10n.acStaffTransferAgreed(request.toMasked)
            : l10n.acStaffTransferDeclined,
      );
    } on AccountActionException catch (e) {
      switch (e.reason) {
        // Expired, answered elsewhere or cancelled by Hỗ trợ: nothing left to answer.
        case 'not-pending' || 'not-found':
          answered.add(request.transferId);
          toaster.show(message: l10n.acStaffTransferGone);
        case 'receiver-owns-family':
          toaster.show(message: l10n.acReceiverOwns);
        default:
          toaster.show(message: l10n.toastActionFailed, error: true);
      }
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
    } finally {
      if (mounted) setState(() => _answering = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final request = widget.request;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.MMMd(
      locale,
    ).add_Hm().format(request.expiresAt.toLocal());
    final body = request.ticket == null
        ? l10n.acStaffTransferBody(request.toMasked, time)
        : l10n.acStaffTransferBodyTicket(
            request.toMasked,
            request.ticket!,
            time,
          );
    final busy = _answering != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(ClRadius.card - 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Read as one: title, then what agreeing means and the deadline.
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClIcon(ClIcons.family, size: 20, color: cl.colors.ink),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.acStaffTransferTitle,
                          style: cl.text.bodyStrong.copyWith(
                            color: cl.colors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: cl.text.label.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              Expanded(
                child: ClButton(
                  label: l10n.acStaffTransferAgree,
                  expand: true,
                  loading: _answering == true,
                  onPressed: busy ? null : _agree,
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: ClButton(
                  label: l10n.acStaffTransferDecline,
                  style: ClButtonStyle.outline,
                  expand: true,
                  loading: _answering == false,
                  onPressed: busy ? null : () => _answer(accept: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Đồng ý chuyển quyền chủ hồ sơ?": pops true to agree.
class _ConfirmAgreeSheet extends StatelessWidget {
  const _ConfirmAgreeSheet({required this.to});
  final String to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.acStaffTransferConfirmTitle),
        Text(
          l10n.acStaffTransferConfirmBody(to),
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        ClButton(
          label: l10n.acStaffTransferAgree,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: ClSpace.s2),
        ClButton(
          label: l10n.actionCancel,
          style: ClButtonStyle.plain,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
