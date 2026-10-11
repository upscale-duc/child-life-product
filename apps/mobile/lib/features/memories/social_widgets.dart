import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../home/home_shell.dart';
import 'album_models.dart';
import 'memory_repository.dart';
import 'memory_widgets.dart';

/// Loves, favourites and "Nhắn ba mẹ" (S10, 11c, 11f, 11g, D-034).

(String, String, bool)? _lovesKey(WidgetRef ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return null;
  return (me.babyId, me.uid, me.role == MemberRole.coParent);
}

/// Whether I love [targetId].
bool lovedByMe(WidgetRef ref, LoveTarget target, String targetId) {
  final key = _lovesKey(ref);
  if (key == null) return false;
  final loves = ref.watch(lovesProvider(key)).value ?? const <Love>[];
  return loves.any(
    (l) => l.uid == key.$2 && l.target == target && l.targetId == targetId,
  );
}

Future<void> toggleLove(
  BuildContext context,
  WidgetRef ref,
  LoveTarget target,
  String targetId,
  bool on,
) async {
  final me = ref.read(selectedMembershipProvider);
  if (me == null) return;
  if (on) ClHaptics.success();
  try {
    await ref.read(memoryRepositoryProvider).setLove(me, target, targetId, on);
  } on Object {
    if (context.mounted) {
      showClToast(
        context,
        message: AppLocalizations.of(context).toastActionFailed,
      );
    }
  }
}

/// "♥ Thương" / "♥ 4" pill. [count] is the target's family-wide count.
class LoveButton extends ConsumerWidget {
  const LoveButton({
    required this.target,
    required this.targetId,
    required this.count,
    this.dark = false,
    this.showLabel = true,
    super.key,
  });

  final LoveTarget target;
  final String targetId;
  final int count;

  /// On the black viewer.
  final bool dark;
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final mine = lovedByMe(ref, target, targetId);
    final label = [
      if (showLabel) l10n.love,
      if (count > 0) '$count',
    ].join(' · ');
    final fg = dark ? Colors.white : (mine ? cl.colors.onWarm : cl.colors.ink);
    return ClPressable(
      onPressed: () => toggleLove(context, ref, target, targetId, !mine),
      selected: mine,
      semanticLabel: l10n.love,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white24
              : (mine ? cl.colors.peachSoft : cl.colors.surface2),
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(ClIcons.heart, size: 18, color: mine ? cl.colors.peach : fg),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: cl.text.label.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "🔖 Yêu thích" — private to me (R-107).
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({required this.mediaId, this.dark = false, super.key});
  final String mediaId;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return const SizedBox.shrink();
    final on =
        ref
            .watch(favoritesProvider((me.babyId, me.uid)))
            .value
            ?.contains(mediaId) ??
        false;
    final fg = dark ? Colors.white : cl.colors.ink;
    return ClPressable(
      onPressed: () async {
        final toaster = ClToaster.of(context);
        try {
          await ref
              .read(memoryRepositoryProvider)
              .setFavorite(me.babyId, me.uid, mediaId, !on);
          toaster.show(message: on ? l10n.favRemoved : l10n.favAdded);
        } on Object {
          toaster.show(message: l10n.toastActionFailed);
        }
      },
      selected: on,
      semanticLabel: l10n.albFavorites,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: dark ? Colors.white24 : cl.colors.surface2,
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(
              ClIcons.bookmark,
              size: 18,
              color: on ? cl.colors.sunshine : fg,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.albFavorites,
              style: cl.text.label.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bà nội, Ông ngoại thương" for parents, "2 lượt thương" otherwise (10a, 11c).
class LovesLine extends ConsumerWidget {
  const LovesLine({
    required this.target,
    required this.targetId,
    required this.count,
    super.key,
  });
  final LoveTarget target;
  final String targetId;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final key = _lovesKey(ref);
    if (key == null) return const SizedBox.shrink();
    final loves = ref.watch(lovesProvider(key)).value ?? const <Love>[];
    final names = key.$3
        ? [
            for (final a in loversOf(loves, target, targetId))
              whoLabel(l10n, a, false),
          ]
        : const <String>[];
    final n = key.$3 ? names.length : count;
    if (n == 0) return const SizedBox.shrink();
    return Row(
      children: [
        ClIcon(ClIcons.heart, size: 16, color: cl.colors.peach),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            names.isNotEmpty && names.length <= 3
                ? l10n.lovesNamed(names.join(', '))
                : l10n.lovesCount(n),
            style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// "Nhắn ba mẹ…" (11i) / "Nhắn Mẹ" (12e): one-way, the parents read it (D-034).
Future<void> showMessageComposer(
  BuildContext context, {
  required MessageContext kind,
  required String contextId,
  String? title,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _Composer(kind: kind, contextId: contextId, title: title),
);

class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.kind, required this.contextId, this.title});
  final MessageContext kind;
  final String contextId;
  final String? title;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final _text = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final me = ref.read(selectedMembershipProvider);
    final text = _text.text.trim();
    if (me == null || text.isEmpty) return;
    setState(() => _busy = true);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    // Saved on the device first, like everything else (sent when online).
    ref
        .read(memoryRepositoryProvider)
        .sendMessage(me, widget.kind, widget.contextId, text)
        .catchError((Object _) => toaster.show(message: l10n.messageFailed));
    ClHaptics.success();
    navigator.pop();
    toaster.show(message: l10n.messageSent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: widget.title ?? l10n.messageParents),
        ClTextField(
          label: '',
          placeholder: l10n.messagePlaceholder,
          controller: _text,
          standalone: true,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.messageHint,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.messageSend,
          icon: ClIcons.arrowRight,
          expand: true,
          onPressed: _busy || _text.text.trim().isEmpty ? null : _send,
          loading: _busy,
        ),
      ],
    );
  }
}

/// One message ("Bà nội Hoa · hôm qua 19:05" + text).
class MessageTile extends ConsumerWidget {
  const MessageTile({required this.message, this.about, super.key});
  final ParentMessage message;
  final String? about;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final unread = me != null && !message.readByUid(me.uid);
    final when = DateFormat(
      'd MMM · HH:mm',
      locale,
    ).format(message.createdAt.toLocal());
    return Container(
      padding: const EdgeInsets.all(ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.card - 6),
        border: unread
            ? Border.all(color: cl.colors.mintDeep, width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorAvatar(name: message.author.name),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.messageFrom(whoLabel(l10n, message.author, false), when),
                  style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
                ),
                if (about != null)
                  Text(
                    about!,
                    style: cl.text.caption.copyWith(color: cl.colors.mintText),
                  ),
                const SizedBox(height: 4),
                Text(message.text, style: cl.text.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
