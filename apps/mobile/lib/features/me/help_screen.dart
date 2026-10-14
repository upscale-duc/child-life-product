import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../l10n/app_localizations.dart';
import '../feedback/feedback_repository.dart';
import '../feedback/feedback_screens.dart';
import '../home/home_shell.dart';
import '../memories/upload_queue.dart';
import 'me_models.dart';
import 'me_repository.dart';
import 'me_widgets.dart';

String helpCategoryLabel(AppLocalizations l10n, HelpCategory c) => switch (c) {
  HelpCategory.memories => l10n.hpCatMemories,
  HelpCategory.family => l10n.hpCatFamily,
  HelpCategory.invites => l10n.hpCatInvites,
  HelpCategory.sync => l10n.hpCatSync,
  HelpCategory.account => l10n.hpCatAccount,
  HelpCategory.storage => l10n.hpCatStorage,
  HelpCategory.stories => l10n.hpCatStories,
};

/// The consented device snapshot for Trợ giúp and Góp ý (FB2): app and OS versions, model, role,
/// pending uploads. Nothing about the child.
Future<Map<String, Object?>> deviceSnapshot(WidgetRef ref) async {
  final info = await PackageInfo.fromPlatform();
  final device = DeviceInfoPlugin();
  var os = Platform.operatingSystemVersion;
  var model = defaultTargetPlatform == TargetPlatform.iOS
      ? 'iPhone'
      : 'Android';
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final i = await device.iosInfo;
      os = 'iOS ${i.systemVersion}';
      model = i.utsname.machine;
    } else {
      final a = await device.androidInfo;
      os = 'Android ${a.version.release}';
      model = a.model;
    }
  } on Object {
    // Keep the defaults.
  }
  final pending = [
    for (final b in ref.read(uploadQueueProvider).batches)
      for (final i in b.items)
        if (i.state != QueueState.uploaded &&
            i.state != QueueState.cancelled &&
            i.state != QueueState.unreadable)
          i,
  ].length;
  String cut(String s, int n) => s.length > n ? s.substring(0, n) : s;
  return {
    'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    'appVersion': cut('${info.version}+${info.buildNumber}', 32),
    'osVersion': cut(os, 64),
    'deviceModel': cut(model, 64),
    'role': ref.read(selectedMembershipProvider)?.role.name,
    'pendingUploads': pending,
    'lastSyncAt': null,
  };
}

/// "Trợ giúp & liên hệ" (13a/13g/13h; form not drawn, G-057/G-073): topic, message, and
/// diagnostics only with consent (no child content).
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _message = TextEditingController();
  HelpCategory? _category;
  var _diagnostics = true;
  var _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      final ticket = await ref
          .read(meRepositoryProvider)
          .sendHelp(
            _category!,
            _message.text,
            _diagnostics ? await deviceSnapshot(ref) : null,
          );
      ref.invalidate(myTicketsProvider);
      toaster.show(message: l10n.hpSent(ticket));
      router.pop();
    } on Object {
      toaster.show(message: l10n.toastActionFailed, error: true);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final email = session is SessionSignedIn ? session.user.email ?? '' : '';
    final ready =
        !_busy &&
        email.isNotEmpty &&
        _category != null &&
        _message.text.trim().isNotEmpty;
    return MePage(
      title: l10n.meHelp,
      children: [
        Text(l10n.hpTopic, style: cl.text.bodyStrong),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s2,
          runSpacing: ClSpace.s2,
          children: [
            for (final c in HelpCategory.values)
              ClFilterChip(
                label: helpCategoryLabel(l10n, c),
                selected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        ClTextField(
          label: l10n.hpMessage,
          placeholder: l10n.hpMessage,
          standalone: true,
          controller: _message,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s3),
        ClCardGroup(
          children: [
            MeRow(
              title: l10n.hpDiagnostics,
              subtitle: l10n.hpDiagnosticsHint,
              trailing: ClToggle(
                value: _diagnostics,
                semanticLabel: l10n.hpDiagnostics,
                onChanged: (v) => setState(() => _diagnostics = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        if (email.isEmpty)
          MeNotice(tone: MeTone.warn, title: l10n.needEmailAccount)
        else
          Text(
            l10n.hpFootnote(email),
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          ),
        const SizedBox(height: ClSpace.s4),
        ClButton(
          label: l10n.messageSend,
          icon: ClIcons.arrowRight,
          expand: true,
          loading: _busy,
          onPressed: ready ? _send : null,
        ),
        const _SentTickets(),
      ],
    );
  }
}

/// FB3 "Bạn xem lại góp ý trong Tôi › Trợ giúp & liên hệ": what this person sent, newest first.
/// Hidden while loading, offline or empty.
class _SentTickets extends ConsumerWidget {
  const _SentTickets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tickets = ref.watch(myTicketsProvider).value ?? const [];
    if (tickets.isEmpty) return const SizedBox.shrink();
    String topic(MyTicket t) {
      final type = t.type;
      if (type != null) {
        return l10n.hpFeedbackLabel(feedbackTypeLabel(l10n, type));
      }
      final category = HelpCategory.values.asNameMap()[t.category];
      return category == null ? t.category : helpCategoryLabel(l10n, category);
    }

    String status(String s) => switch (s) {
      'claimed' => l10n.hpStatusClaimed,
      'waiting' => l10n.hpStatusWaiting,
      'closed' => l10n.hpStatusClosed,
      _ => l10n.hpStatusNew,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: ClSpace.s6),
        Semantics(
          header: true,
          child: Text(l10n.hpSentTitle, style: cl.text.bodyStrong),
        ),
        const SizedBox(height: ClSpace.s2),
        ClCardGroup(
          children: [
            for (final t in tickets)
              MeRow(
                title: '${t.ticket} · ${topic(t)}',
                subtitle: t.message,
                value: status(t.status),
              ),
          ],
        ),
      ],
    );
  }
}
