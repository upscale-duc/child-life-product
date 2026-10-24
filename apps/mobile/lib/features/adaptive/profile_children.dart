import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart' show careClockProvider;
import '../home/home_shell.dart';
import 'today_adaptive.dart' show AdaptiveRoutes;

/// AX34 "Các bé" on Hồ sơ: the children this person manages (Cùng nuôi), youngest first, each
/// opening its own "mục tiêu & Hôm nay" (AX14 for that child, G-110); "Thêm" adds one.
class ProfileChildren extends ConsumerWidget {
  const ProfileChildren({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    if (session is! SessionSignedIn) return const SizedBox.shrink();
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final managed = [
      for (final m in session.active)
        if (m.role == MemberRole.coParent) m,
    ];
    DateTime? dob(Membership m) =>
        ref.watch(babyPrivateProfileProvider(m.babyId)).value?.dateOfBirth;
    managed.sort((a, b) {
      final da = dob(a), db = dob(b);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    if (managed.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: ClSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSectionHeader(
            title: l10n.pfChildren,
            linkLabel: l10n.pfAdd,
            onLink: () => startAddingBaby(context, ref),
          ),
          const SizedBox(height: ClSpace.s2),
          ClCardGroup(
            key: const Key('profileChildren'),
            children: [
              for (final m in managed)
                if (ref.watch(babyProvider(m.babyId)).value case final baby?)
                  ClPressable(
                    key: ValueKey('profileChild_${m.babyId}'),
                    onPressed: () {
                      ref
                          .read(selectedBabyIdProvider.notifier)
                          .select(m.babyId);
                      context.push(AdaptiveRoutes.customize);
                    },
                    semanticLabel: baby.nickname,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          SavedBabyAvatar(baby: baby, size: 36),
                          const SizedBox(width: ClSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  baby.nickname,
                                  style: cl.text.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: cl.colors.ink,
                                  ),
                                ),
                                Text(
                                  l10n.pfChildRow(switch (dob(m)) {
                                    final d? => ageShort(l10n, d, now),
                                    null => '',
                                  }),
                                  style: cl.text.caption.copyWith(
                                    color: cl.colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
