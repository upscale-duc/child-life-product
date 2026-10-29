import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_choices.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../me/me_widgets.dart';
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

/// 13 Cài đặt (Figma 1354:22802), the person's own part (D-135 Q5): "Nhắc trước" 5 / 10 / 15 /
/// Tắt and "Nhắc cả trong giờ yên lặng" for the N1 task reminders. One place: Thông báo › Việc
/// chăm con opens this screen too. "Lịch", for plan managers only: "Tự tạo lịch mỗi sáng" (D-136
/// #3, off by default). "Gộp việc gần nhau", "Lịch sử thay đổi" and "Quyền với lịch" wait for
/// the owner and step 5.
class CarePlanSettingsScreen extends ConsumerStatefulWidget {
  const CarePlanSettingsScreen({super.key});

  @override
  ConsumerState<CarePlanSettingsScreen> createState() =>
      _CarePlanSettingsScreenState();
}

class _CarePlanSettingsScreenState
    extends ConsumerState<CarePlanSettingsScreen> {
  /// What this screen just chose, shown until the stored copy agrees (or the save fails).
  CarePlanPrefs? _chosen;
  bool? _autoChosen;

  Future<void> _setAuto(String babyId, bool on) async {
    final toaster = ClToaster.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _autoChosen = on);
    try {
      await ref.read(carePlanRepositoryProvider).setAutoDraft(babyId, on: on);
    } on Object {
      toaster.show(message: l10n.cpSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _autoChosen = null);
    }
  }

  Future<void> _save(String uid, CarePlanPrefs next) async {
    final toaster = ClToaster.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _chosen = next);
    try {
      await ref.read(carePlanRepositoryProvider).savePrefs(uid, next);
    } on Object {
      toaster.show(message: l10n.cpSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _chosen = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return ColoredBox(color: cl.colors.cloud);
    final uid = session.user.uid;
    final async = ref.watch(carePlanPrefsProvider(uid));
    final prefs = _chosen ?? async.value;
    final member = ref.watch(selectedMembershipProvider);
    final manager = member != null && carePlanCanManage(member);
    final family = manager
        ? ref.watch(carePlanFamilySettingsProvider(member.babyId)).value
        : null;
    final autoDraft = _autoChosen ?? family?.autoDraft;
    final c = cl.colors;

    Widget card(List<Widget> children) => Container(
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.card),
        boxShadow: cl.shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0) Container(height: 1, color: c.separator),
            w,
          ],
        ],
      ),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(0, ClSpace.s4, 0, ClSpace.s2),
      child: Semantics(
        header: true,
        child: Text(title, style: cl.text.label.copyWith(color: c.inkMuted)),
      ),
    );

    return CarePlanPage(
      title: l10n.cpSettingsTitle,
      children: [
        if (prefs == null && async.hasError)
          MeNotice(
            tone: MeTone.error,
            icon: ClIcons.cloudOff,
            title: l10n.cpLoadFailed,
            onTap: () => ref.invalidate(carePlanPrefsProvider(uid)),
          )
        else if (prefs == null)
          const ClSkeleton(height: 4 * 56, radius: ClRadius.card)
        else ...[
          section(l10n.cpRemindSection),
          card([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconLabel(
                    icon: ClIcons.bell,
                    tint: c.mintSoft,
                    label: l10n.cpRemindBefore,
                  ),
                  const SizedBox(height: ClSpace.s2),
                  Wrap(
                    spacing: ClSpace.s2,
                    runSpacing: ClSpace.s2,
                    children: [
                      for (final (i, lead) in carePlanReminderLeads.indexed)
                        ClRelationChip(
                          key: ValueKey('cp_lead_$lead'),
                          // Figma: the unit once, on the first ("5 phút", 10, 15, Tắt).
                          label: lead == 0
                              ? l10n.meOff
                              : i == 0
                              ? l10n.cpLeadMinutes(lead)
                              : '$lead',
                          selected: prefs.leadMinutes == lead,
                          onTap: () => unawaited(
                            _save(uid, prefs.copyWith(leadMinutes: lead)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Without reminders there is nothing to ring in quiet hours (D-110).
            if (prefs.on)
              _ToggleRow(
                key: const Key('cp_quiet'),
                icon: ClIcons.sleep,
                tint: cl.care.sleep.soft,
                label: l10n.cpQuietHours,
                value: prefs.quietHours,
                onChanged: (v) =>
                    unawaited(_save(uid, prefs.copyWith(quietHours: v))),
              ),
          ]),
          section(l10n.cpPlanSection),
          card([
            if (manager && autoDraft != null)
              _ToggleRow(
                key: const Key('cp_auto_draft'),
                icon: ClIcons.sunrise,
                tint: c.sunshineSoft,
                label: l10n.cpAutoDraft,
                value: autoDraft,
                onChanged: (v) => unawaited(_setAuto(member.babyId, v)),
              ),
            // 20 Lịch sử thay đổi.
            ClPressable(
              key: const Key('cp_history'),
              onPressed: () => context.push(Routes.carePlanHistory),
              semanticLabel: l10n.cpHistTitle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: _IconLabel(
                        icon: ClIcons.journal,
                        tint: c.mintSoft,
                        label: l10n.cpHistTitle,
                      ),
                    ),
                    ClIcon(ClIcons.chevronRight, size: 18, color: c.inkMuted),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

/// An icon on a tinted circle and its label (Figma 13 rows).
class _IconLabel extends StatelessWidget {
  const _IconLabel({
    required this.icon,
    required this.tint,
    required this.label,
  });

  final ClIcons icon;
  final Color tint;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: ClIcon(icon, size: 18, color: cl.colors.ink),
        ),
        const SizedBox(width: ClSpace.s3),
        Expanded(
          child: Text(
            label,
            style: cl.text.bodyStrong.copyWith(color: cl.colors.ink),
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ClIcons icon;
  final Color tint;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: ClSpace.s3),
    child: Row(
      children: [
        Expanded(
          child: _IconLabel(icon: icon, tint: tint, label: label),
        ),
        const SizedBox(width: ClSpace.s2),
        ClToggle(value: value, semanticLabel: label, onChanged: onChanged),
      ],
    ),
  );
}
