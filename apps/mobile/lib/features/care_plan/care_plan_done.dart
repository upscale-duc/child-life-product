import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show inBabyZone;
import '../family/family_repository.dart' show familyMembersProvider;
import '../home/home_shell.dart' show selectedMembershipProvider;
import '../reminders/reminder_screens.dart' show assigneeName;
import 'care_plan_models.dart';
import 'care_plan_repository.dart';
import 'care_plan_widgets.dart';

/// 10 Vừa xong (Figma 1353:22683): the task someone else just did, from their N2 push. A heart
/// and / or one thanks line go to them as N3 ("Mẹ thả tim cho Ba"); hearts stay once sent. The
/// one who did it sees how many hearts came. Figma's "sớm 5 phút" is left out: the plan does not
/// grade timing (D-135 Q8).
class CarePlanDoneScreen extends ConsumerStatefulWidget {
  const CarePlanDoneScreen({
    required this.date,
    required this.itemId,
    super.key,
  });

  final String date;
  final String itemId;

  @override
  ConsumerState<CarePlanDoneScreen> createState() => _CarePlanDoneScreenState();
}

class _CarePlanDoneScreenState extends ConsumerState<CarePlanDoneScreen> {
  bool _heart = false;
  CarePlanThanks? _thanks;
  bool _sending = false;

  Future<void> _send(String babyId, CarePlanItem item, String who) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final nav = Navigator.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(carePlanRepositoryProvider)
          .react(babyId, widget.date, item.id, heart: _heart, thanks: _thanks);
      toaster.show(message: l10n.cpSentTo(who));
      if (!mounted) return;
      setState(() => _sending = false);
      unawaited(nav.maybePop());
    } on Object {
      toaster.show(message: l10n.cpSaveFailed, error: true);
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final c = cl.colors;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: c.cloud);
    final babyId = me.babyId;
    final baby = ref.watch(babyProvider(babyId)).value;
    final members = ref.watch(familyMembersProvider(babyId)).value ?? const [];
    final items = ref.watch(carePlanLiveItemsProvider((babyId, widget.date)));
    final item = items.value?.where((i) => i.id == widget.itemId).firstOrNull;
    final inset = MediaQuery.paddingOf(context).bottom;

    final close = Align(
      alignment: Alignment.centerRight,
      child: CarePlanIconButton(
        key: const Key('cp_done_close'),
        icon: ClIcons.close,
        semanticLabel: l10n.a11yClose,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );

    final Widget body;
    Widget? bottom;
    if (!items.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (item == null || !item.done || item.doneBy == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(ClSpace.s6),
          child: Text(
            l10n.cpDoneMissing,
            textAlign: TextAlign.center,
            style: cl.text.body.copyWith(color: c.inkMuted),
          ),
        ),
      );
    } else {
      final doer = members.where((m) => m.uid == item.doneBy).firstOrNull;
      final mine = item.doneBy == me.uid;
      final who = doer == null
          ? ''
          : carePlanCapitalized(assigneeName(l10n, doer, me.uid));
      final sent = item.reactions[me.uid];
      final hadHeart = sent?.heart ?? false;
      final hearts = item.hearts + (_heart && !hadHeart ? 1 : 0);
      final zone = baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh';
      final at = item.doneAt == null ? null : inBabyZone(zone, item.doneAt!);
      final something = (_heart && !hadHeart) || _thanks != null;

      Widget reaction({
        required Key key,
        required ClIcons icon,
        required String label,
        required String semantic,
        required bool selected,
        required VoidCallback? onTap,
      }) => ClPressable(
        key: key,
        onPressed: onTap,
        semanticLabel: semantic,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: selected ? c.peachSoft : c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.peach : c.separator,
                    width: selected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: ClIcon(icon, size: 30, color: c.ink),
              ),
              const SizedBox(height: ClSpace.s1),
              Text(
                label,
                textAlign: TextAlign.center,
                style: cl.text.label.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      );

      void pick(CarePlanThanks t) =>
          setState(() => _thanks = _thanks == t ? null : t);

      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          ClSpace.s4,
          0,
          ClSpace.s4,
          ClSpace.s4,
        ),
        children: [
          const SizedBox(height: ClSpace.s4),
          Center(
            child: _Stage(task: item.task, doer: doer),
          ),
          const SizedBox(height: ClSpace.s6),
          Semantics(
            header: true,
            child: Text(
              l10n.cpDidLine(who, item.task.name, baby?.nickname ?? ''),
              textAlign: TextAlign.center,
              style: cl.text.title.copyWith(color: c.ink),
            ),
          ),
          if (at != null) ...[
            const SizedBox(height: ClSpace.s1),
            Text(
              DateFormat.Hm().format(at),
              textAlign: TextAlign.center,
              style: cl.text.body.copyWith(color: c.inkMuted),
            ),
          ],
          const SizedBox(height: ClSpace.s6),
          if (mine)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClIcon(ClIcons.heart, size: 20, color: c.ink),
                const SizedBox(width: ClSpace.s2),
                Text(
                  l10n.cpHeartsFrom(item.hearts),
                  style: cl.text.bodyStrong.copyWith(color: c.ink),
                ),
              ],
            )
          else ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: ClSpace.s4,
              runSpacing: ClSpace.s3,
              children: [
                reaction(
                  key: const Key('cp_react_heart'),
                  icon: ClIcons.heart,
                  label: '$hearts',
                  semantic: l10n.cpHeartA11y(who),
                  selected: _heart || hadHeart,
                  onTap: hadHeart
                      ? null
                      : () => setState(() => _heart = !_heart),
                ),
                reaction(
                  key: const Key('cp_react_thanks'),
                  icon: ClIcons.star,
                  label: l10n.cpReactThanks,
                  semantic: l10n.cpReactThanks,
                  selected: _thanks == CarePlanThanks.thanks,
                  onTap: () => pick(CarePlanThanks.thanks),
                ),
                reaction(
                  key: const Key('cp_react_great'),
                  icon: ClIcons.spark,
                  label: l10n.cpReactGreat,
                  semantic: l10n.cpReactGreat,
                  selected: _thanks == CarePlanThanks.great,
                  onTap: () => pick(CarePlanThanks.great),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final (t, label) in [
                  (CarePlanThanks.thanksName, l10n.cpThanksName(who)),
                  (CarePlanThanks.proud, l10n.cpThanksProud(who)),
                  (CarePlanThanks.love, l10n.cpThanksLove(who)),
                ])
                  ClFilterChip(
                    key: ValueKey('cp_thanks_${t.name}'),
                    label: label,
                    selected: _thanks == t,
                    onTap: () => pick(t),
                  ),
              ],
            ),
          ],
        ],
      );
      bottom = mine
          ? null
          : ClButton(
              key: const Key('cp_react_send'),
              label: l10n.cpSendTo(who),
              expand: true,
              loading: _sending,
              onPressed: something
                  ? () => unawaited(_send(babyId, item, who))
                  : null,
            );
    }

    return Scaffold(
      backgroundColor: c.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
              child: close,
            ),
            Expanded(child: body),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  inset + ClSpace.s3,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// The task's picture in a soft circle, the one who did it at its corner, and a few hearts.
class _Stage extends StatelessWidget {
  const _Stage({required this.task, required this.doer});

  final CarePlanTask task;
  final Membership? doer;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    Widget heart(double size) => ExcludeSemantics(
      child: ClIcon(ClIcons.heart, size: size, color: c.peach),
    );
    return SizedBox.square(
      dimension: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.mintSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: CarePlanArtBare(task, size: 140),
          ),
          if (doer != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: CarePlanAvatar(doer!, size: 72),
            ),
          Positioned(left: -10, top: 20, child: heart(28)),
          Positioned(right: 2, top: 6, child: heart(22)),
          Positioned(left: -20, top: 150, child: heart(20)),
          Positioned(left: 20, top: -4, child: heart(16)),
        ],
      ),
    );
  }
}
