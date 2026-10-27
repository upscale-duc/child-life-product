import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../family/my_invites.dart' show ClRedDot;
import 'notification_repository.dart';

/// The bell in the Hôm nay header (559:57622): a 44 pt circle like the Night care toggle, with a
/// red dot while the inbox has unread rows (EN04); opens EN06.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({this.hero = false, super.key});
  final bool hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final unread = ref.watch(unreadNotificationsProvider);
    return ClPressable(
      semanticLabel: unread > 0 ? l10n.ntBellUnread(unread) : l10n.ntBell,
      onPressed: () => context.push(Routes.notifications),
      child: SizedBox(
        width: ClSpace.tapMin,
        height: ClSpace.tapMin,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: ClSpace.tapMin,
              height: ClSpace.tapMin,
              decoration: BoxDecoration(
                color: hero ? cl.colors.surface : cl.colors.surface2,
                shape: BoxShape.circle,
                boxShadow: hero ? cl.shadows.chip : null,
              ),
              alignment: Alignment.center,
              child: ClIcon(ClIcons.bell, size: 22, color: cl.colors.ink),
            ),
            if (unread > 0)
              const Positioned(
                key: Key('notificationBellDot'),
                top: 9,
                right: 9,
                child: ClRedDot(),
              ),
          ],
        ),
      ),
    );
  }
}
