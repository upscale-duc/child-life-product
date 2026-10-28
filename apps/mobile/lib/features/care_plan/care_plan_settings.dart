import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../me/me_widgets.dart';
import 'care_plan_models.dart';
import 'care_plan_repository.dart';

/// 13, the person's own part (D-135 Q5, ANALYSIS §6.2): "Nhắc trước" 5 / 10 / 15 / Tắt and
/// "Nhắc cả trong giờ yên lặng" for the N1 task reminders. One place: Thông báo › Việc chăm con
/// opens this screen too. The family's part, for plan managers only: "Tự tạo lịch mỗi sáng"
/// (D-136 #3, off by default). Rights per person (13 Quyền với lịch) come with a later step.
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
    return MePage(
      title: l10n.cpRemindTitle,
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
          MeSection(l10n.cpRemindBefore),
          ClCardGroup(
            children: [
              for (final lead in carePlanReminderLeads)
                ClOptionRow(
                  key: ValueKey('cp_lead_$lead'),
                  title: lead == 0 ? l10n.meOff : l10n.cpLeadMinutes(lead),
                  selected: prefs.leadMinutes == lead,
                  onTap: () =>
                      unawaited(_save(uid, prefs.copyWith(leadMinutes: lead))),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClSpace.s1,
              ClSpace.s2,
              ClSpace.s1,
              0,
            ),
            child: Text(
              l10n.cpRemindHint,
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
          ),
          // Without reminders there is nothing to ring in quiet hours (D-110).
          if (prefs.on) ...[
            const SizedBox(height: ClSpace.s4),
            ClCardGroup(
              children: [
                MeRow(
                  key: const Key('cp_quiet'),
                  title: l10n.cpQuietHours,
                  subtitle: l10n.cpQuietHoursHint,
                  trailing: ClToggle(
                    value: prefs.quietHours,
                    semanticLabel: l10n.cpQuietHours,
                    onChanged: (v) =>
                        unawaited(_save(uid, prefs.copyWith(quietHours: v))),
                  ),
                ),
              ],
            ),
          ],
          if (manager && autoDraft != null) ...[
            MeSection(l10n.cpFamilySection),
            ClCardGroup(
              children: [
                MeRow(
                  key: const Key('cp_auto_draft'),
                  title: l10n.cpAutoDraft,
                  subtitle: l10n.cpAutoDraftHint,
                  trailing: ClToggle(
                    value: autoDraft,
                    semanticLabel: l10n.cpAutoDraft,
                    onChanged: (v) => unawaited(_setAuto(member.babyId, v)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
