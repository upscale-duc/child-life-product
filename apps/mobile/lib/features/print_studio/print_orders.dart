import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/route_guard.dart';
import '../home/home_shell.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import 'print_repository.dart';
import 'print_models.dart';
import '../memories/memory_models.dart';
import 'print_widgets.dart';

class PrintOrdersScreen extends ConsumerStatefulWidget {
  const PrintOrdersScreen({this.id, this.babyId, super.key});
  final String? id, babyId;
  @override
  ConsumerState<PrintOrdersScreen> createState() => _PrintOrdersScreenState();
}

class _PrintOrdersScreenState extends ConsumerState<PrintOrdersScreen> {
  bool _busy = false;
  AppLocalizations get l => AppLocalizations.of(context);
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) showClToast(context, message: l.psError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(String baby, String id) async {
    var stars = 5;
    final text = TextEditingController();
    final result = await showModalBottomSheet<({int stars, String message})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cl.colors.cloud,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(c).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.psReview, style: context.cl.text.headline),
                const SizedBox(height: 12),
                Text(l.psReviewHelp, style: context.cl.text.caption),
                const SizedBox(height: 12),
                Wrap(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: '${l.psRating} $i',
                        onPressed: () => set(() => stars = i),
                        icon: Icon(
                          i <= stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: context.cl.colors.mintDeep,
                          size: 32,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: text,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.psReviewMessage),
                  onChanged: (_) => set(() {}),
                ),
                const SizedBox(height: 16),
                ClButton(
                  label: l.psSendReview,
                  onPressed: text.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(c, (
                          stars: stars,
                          message: text.text.trim(),
                        )),
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    text.dispose();
    if (result == null || !mounted) return;
    await _run(() async {
      await printCall(ref, 'printStudioReview', {
        'babyId': baby,
        'id': id,
        'rating': result.stars,
        'message': result.message,
      });
      if (mounted) showClToast(context, message: l.psReviewSent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(selectedMembershipProvider),
        baby = widget.babyId ?? me?.babyId;
    if (baby == null || me?.role != MemberRole.coParent) {
      return Scaffold(body: Center(child: Text(l.psForParents)));
    }
    final data = ref.watch(printOrdersProvider(baby)), cl = context.cl;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      appBar: AppBar(
        backgroundColor: cl.colors.cloud,
        leading: IconButton(
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: cl.colors.surface),
          icon: const ClIcon(ClIcons.back, size: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(Routes.meHelp),
            child: Text(l.meHelp),
          ),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ClEmptyState(
          icon: ClIcons.cloudOff,
          title: l.psError,
          message: l.psOrders,
          actionLabel: l.psRetry,
          onAction: () => ref.invalidate(printOrdersProvider(baby)),
        ),
        data: (orders) {
          final order = orders.where((o) => o['id'] == widget.id).firstOrNull;
          // PR-5: a missing order is not "Chưa có đơn in".
          if (widget.id != null && order == null) {
            return ClEmptyState(
              icon: ClIcons.journal,
              title: l.psOrderNotFound,
              message: l.psOrderNotFoundHelp,
              actionLabel: l.psOrders,
              onAction: () => context.pushReplacement(
                '${Routes.printStudioOrders}?baby=$baby',
              ),
            );
          }
          if (order == null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.psOrders,
                  style: cl.text.title2.copyWith(
                    fontFamily: 'Be Vietnam Pro Keepsake',
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (orders.isEmpty)
                  ClEmptyState(
                    icon: ClIcons.journal,
                    title: l.psNoOrders,
                    message: l.psNoOrdersHelp,
                    actionLabel: l.psPreview,
                    onAction: () => context.push(Routes.printStudio),
                  ),
                for (final o in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PrintCard(
                      onTap: () => context.push(
                        '${Routes.printStudioOrders}/${o['id']}?baby=$baby',
                      ),
                      lifted: false,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 42,
                            height: 56,
                            child: PrintArtwork(
                              design: PrintDesign.fromJson(
                                Map<String, dynamic>.from(o['design'] as Map),
                              ),
                              media: _snapshotMedia(o, baby),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  printProductName(
                                    l,
                                    (o['design'] as Map)['product'] as String,
                                  ),
                                  style: cl.text.label.copyWith(
                                    fontFamily: 'Be Vietnam Pro Keepsake',
                                    height: 1.3,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${o['id']} · ${printMoney(context, (o['total'] as num).toInt())}',
                                  style: cl.text.caption.copyWith(
                                    fontFamily: 'Be Vietnam Pro Keepsake',
                                    height: 1.3,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: o['status'] == 'printing'
                                  ? cl.colors.sunshineSoft
                                  : cl.colors.surface2,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              printStatusName(l, o['status'] as String),
                              style: cl.text.caption.copyWith(
                                fontFamily: 'Be Vietnam Pro Keepsake',
                                height: 1.3,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
          final o = order,
              status = o['status'] as String,
              address = Map<String, dynamic>.from(o['address'] as Map),
              design = Map<String, dynamic>.from(o['design'] as Map);
          Widget row(
            String label,
            Object? value, {
            bool copy = false,
          }) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(label, style: cl.text.caption)),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText('$value', style: cl.text.bodyStrong),
                ),
                if (copy)
                  IconButton(
                    tooltip: l.psCopy,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: '$value'));
                      if (context.mounted) {
                        showClToast(context, message: l.psCopied);
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
              ],
            ),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                o['id'] as String,
                style: cl.text.title2.copyWith(
                  fontFamily: 'Be Vietnam Pro Keepsake',
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              PrintCard(child: _timeline(o)),
              const SizedBox(height: 16),
              PrintCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const ClIcon(ClIcons.lock, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          l.psPrintLocked,
                          style: cl.text.label.copyWith(
                            fontFamily: 'Be Vietnam Pro Keepsake',
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: PrintDesign.fromJson(design).count,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => SizedBox(
                          width: 58,
                          child: PrintArtwork(
                            design: PrintDesign.fromJson(design),
                            media: _snapshotMedia(o, baby),
                            page: i,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(l.psImmutable, style: cl.text.caption),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrintCard(
                lifted: false,
                child: Column(
                  children: [
                    row(l.psQuantity, o['quantity']),
                    row(
                      o['pricesEstimated'] == true
                          ? l.psEstimatedTotal
                          : l.psTotal,
                      printMoney(context, (o['total'] as num).toInt()),
                    ),
                  ],
                ),
              ),
              if (status == 'pendingConfirmation' ||
                  status == 'awaitingDeposit') ...[
                const SizedBox(height: 16),
                PrintNotice(l.psOrderReceivedHelp),
              ],
              if (o['pricesEstimated'] == true) ...[
                const SizedBox(height: 12),
                PrintNotice(l.psEstimatedPriceNote),
              ],
              if (o['cancellationReason'] is String) ...[
                const SizedBox(height: 12),
                PrintNotice(
                  printCancelReasonLabel(l, o['cancellationReason'] as String),
                ),
              ],
              const SizedBox(height: 16),
              PrintCard(
                child: Column(
                  children: [
                    row(l.psRecipient, address['recipient']),
                    row(l.psPhone, address['phone']),
                    row(l.psAddress, address['address']),
                    if (o['tracking'] != null)
                      row(l.psTracking, o['tracking'], copy: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (status == 'pendingConfirmation' ||
                  status == 'awaitingDeposit')
                ClButton(
                  label: l.psCancelOrder,
                  style: ClButtonStyle.destructive,
                  loading: _busy,
                  onPressed: _busy
                      ? null
                      : () async {
                          var reason = 'customer_changed_mind';
                          final toaster = ClToaster.of(context);
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (c) => StatefulBuilder(
                              builder: (c, set) => AlertDialog(
                                title: Text(l.psCancelOrder),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(l.psCancelConfirm),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      initialValue: reason,
                                      decoration: InputDecoration(
                                        labelText: l.psCancelReason,
                                      ),
                                      items:
                                          [
                                                'customer_changed_mind',
                                                'price',
                                                'shipping_fee',
                                                'delivery_time',
                                                'design',
                                                'other',
                                              ]
                                              .map(
                                                (r) => DropdownMenuItem(
                                                  value: r,
                                                  child: Text(
                                                    printCancelReasonLabel(
                                                      l,
                                                      r,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) =>
                                          set(() => reason = v ?? reason),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: Text(l.psKeep),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: Text(l.psCancelOrder),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (yes == true && mounted) {
                            await _run(() async {
                              await printCall(ref, 'printStudioCancel', {
                                'babyId': baby,
                                'id': o['id'],
                                'reason': reason,
                              });
                              toaster.show(message: l.psOrderCancelledToast);
                            });
                          }
                        },
                ),
              if (status == 'delivered' && o['reviewed'] != true)
                ClButton(
                  label: l.psReview,
                  loading: _busy,
                  onPressed: () => _review(baby, o['id'] as String),
                ),
              if (o['reviewed'] == true)
                ClButton(
                  label: l.psDeleteReview,
                  style: ClButtonStyle.destructive,
                  loading: _busy,
                  onPressed: () => _run(() async {
                    await printCall(ref, 'printStudioRemoveReview', {
                      'babyId': baby,
                      'id': o['id'],
                    });
                  }),
                ),
              const SizedBox(height: 16),
              ClButton(
                label: l.meHelp,
                style: ClButtonStyle.plain,
                onPressed: () => context.push(Routes.meHelp),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _timeline(Map<String, dynamic> order) {
    final cl = context.cl;
    const steps = [
      'pendingConfirmation',
      'confirmed',
      'printing',
      'shipped',
      'delivered',
    ];
    final status = order['status'] == 'awaitingDeposit'
        ? 'pendingConfirmation'
        : order['status'];
    final current = steps.indexOf(status as String);
    if (status == 'cancelled') {
      return Text(l.psCancelled, style: cl.text.bodyStrong);
    }
    // PR-5: a status this build does not know: said plainly, no greyed-out steps.
    if (current < 0) {
      return Text(l.psStatusUnknown, style: cl.text.bodyStrong);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < current
                        ? cl.colors.mintDeep
                        : i == current
                        ? cl.colors.sunshine
                        : cl.colors.surface2,
                  ),
                  child: i < current
                      ? ClIcon(
                          ClIcons.check,
                          size: 14,
                          color: cl.colors.onMintDeep,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printStatusName(l, steps[i]),
                        style: cl.text.label.copyWith(
                          fontFamily: 'Be Vietnam Pro Keepsake',
                          height: 1.3,
                          fontSize: 15,
                          color: i > current
                              ? cl.colors.inkMuted
                              : cl.colors.ink,
                          fontWeight: i == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      for (final e in order['events'] as List? ?? [])
                        if ((e as Map)['status'] == steps[i] &&
                            dateOf(e['at']) != null)
                          Text(
                            DateFormat.yMMMd(
                              locale,
                            ).add_Hm().format(dateOf(e['at'])!.toLocal()),
                            style: cl.text.caption,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<MediaItem> _snapshotMedia(Map<String, dynamic> order, String baby) => [
    for (final source in order['snapshotSources'] as List? ?? [])
      if ((source as Map)['path'] is String)
        MediaItem(
          id: source['id'] as String,
          babyId: baby,
          memoryId: '',
          type: MediaKind.photo,
          status: MediaStatus.ready,
          audience: Audience.parents,
          effectiveAudience: Audience.parents,
          captureAt: DateTime(2000),
          createdBy: '',
          paths: MediaPaths(display: source['path'] as String),
        ),
  ];
}
