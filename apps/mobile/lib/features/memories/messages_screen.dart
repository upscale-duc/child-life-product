import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import 'album_models.dart';
import 'memory_repository.dart';
import 'social_widgets.dart';

/// "Lời nhắn" (D-034, engineering screen awaiting design review): what relatives and
/// caregivers sent the parents, newest first; opening the list marks them read.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _marked = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final me = ref.watch(selectedMembershipProvider);
    if (me == null) return ColoredBox(color: cl.colors.cloud);
    final messages =
        ref.watch(messagesProvider((me.babyId, me.uid, true))).value ??
        const <ParentMessage>[];
    final albums =
        ref.watch(albumsProvider((me.babyId, true))).value ?? const <Album>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final m in messages) {
        if (!m.readByUid(me.uid) && _marked.add(m.id)) {
          ref
              .read(memoryRepositoryProvider)
              .markRead(me.babyId, m.id, me.uid)
              .catchError((_) {});
        }
      }
    });
    String about(ParentMessage m) => switch (m.context) {
      MessageContext.media => l10n.messagesAboutPhoto,
      MessageContext.memory => l10n.messagesAboutMemory,
      MessageContext.album => switch (albums
          .where((a) => a.id == m.contextId)
          .firstOrNull) {
        final a? => l10n.messagesAboutAlbum(a.name),
        null => l10n.messagesAboutAlbumGeneric,
      },
      MessageContext.story => l10n.messagesAboutStory,
      MessageContext.record => l10n.messagesAboutRecord,
    };
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            ClSpace.s2,
            ClSpace.s4,
            ClTabDock.contentBottomPadding,
          ),
          children: [
            ClTopBar(onBack: () => context.pop()),
            const SizedBox(height: ClSpace.s3),
            Semantics(
              header: true,
              child: Text(l10n.messagesTitle, style: cl.text.largeTitle),
            ),
            const SizedBox(height: ClSpace.s4),
            if (messages.isEmpty)
              ClEmptyState(
                icon: ClIcons.mail,
                title: l10n.messagesTitle,
                message: l10n.messagesEmpty,
              )
            else
              for (final m in messages) ...[
                MessageTile(message: m, about: about(m)),
                const SizedBox(height: ClSpace.s2),
              ],
          ],
        ),
      ),
    );
  }
}
