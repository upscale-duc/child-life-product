import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_shell.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import '../rhythm/rhythm_actions.dart' show leaveRhythm;
import '../rhythm/rhythm_labels.dart' show longDay;
import '../rhythm/rhythm_widgets.dart';
import 'ai_models.dart';
import 'ai_repository.dart';

/// A1 · AI consent (NL10 574:1222 "Dùng AI để tóm tắt" / "Quyền riêng tư & dữ liệu"), per person
/// (`users/{uid}/settings/ai`, [aiConsentVersion]): what is sent, what never is, who handles it
/// and what withdrawal does — only what P-151 / D-003 settle (the wording waits for legal, Q-070).
/// "Cho phép ghi chú của tôi…" is `shareMyNotes`. Opened from Cá nhân hoá and from SU01 / "Giải
/// thích thêm" when consent is missing; pops back once given.
class AiConsentScreen extends ConsumerStatefulWidget {
  const AiConsentScreen({super.key});

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  bool? _share;
  var _busy = false;

  Future<void> _run(
    Future<void> Function(AiRepository repo) write, {
    required String done,
    bool pop = false,
    VoidCallback? undo,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await write(ref.read(aiRepositoryProvider));
      if (!mounted) return;
      toaster.show(message: done);
      if (pop) leaveRhythm(context);
    } on Object {
      // AI-12: a switch that did not save goes back to what is saved.
      if (mounted) undo?.call();
      toaster.show(message: l10n.aiConsentFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    final l10n = AppLocalizations.of(context);
    final ok = await rhConfirm(
      context,
      title: l10n.aiWithdrawTitle,
      body: l10n.aiWithdrawBody,
      confirm: l10n.aiWithdrawConfirm,
      cancel: l10n.rhEpNotYet,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run((r) async {
      await r.withdrawConsent();
      // The server drops the AI text; this phone's copies go too.
      await r.forgetHandovers();
      ref.invalidate(handoversProvider);
    }, done: l10n.aiWithdrawn);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final me = ref.watch(selectedMembershipProvider);
    final topBar = Align(
      alignment: Alignment.centerLeft,
      child: RhRoundIcon(
        icon: ClIcons.back,
        label: l10n.a11yBack,
        onPressed: () => leaveRhythm(context),
      ),
    );
    if (me == null) {
      return OnboardingScaffold(topBar: topBar, content: const []);
    }
    final async = ref.watch(aiSettingsProvider(me.uid));
    final settings = async.value ?? AiSettings.none;
    final granted = settings.granted;
    final share = _share ?? settings.consent?.shareMyNotes ?? false;

    Widget group(String title, ClIcons icon, List<String> items) => RhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClIcon(icon, size: 18, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: cl.text.bodyStrong),
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          RhBullets(items),
        ],
      ),
    );

    return OnboardingScaffold(
      topBar: topBar,
      content: [
        Semantics(
          header: true,
          child: Text(l10n.aiConsentTitle, style: cl.text.title2),
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.aiConsentIntro,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        if (settings.outdated) ...[
          const SizedBox(height: ClSpace.s3),
          RhInfoBox(icon: ClIcons.alert, text: l10n.aiConsentOutdated),
        ],
        const SizedBox(height: ClSpace.s4),
        group(l10n.aiConsentSentTitle, ClIcons.upload, [
          l10n.aiConsentSent1,
          l10n.aiConsentSent2,
        ]),
        const SizedBox(height: ClSpace.s3),
        group(l10n.aiConsentNeverTitle, ClIcons.lock, [
          l10n.aiConsentNever1,
          l10n.aiConsentNever2,
          l10n.aiConsentNever3,
        ]),
        const SizedBox(height: ClSpace.s3),
        group(l10n.aiConsentWhereTitle, ClIcons.globe, [
          l10n.aiConsentWhere1,
          l10n.aiConsentWhere2,
          l10n.aiConsentWhere3,
        ]),
        const SizedBox(height: ClSpace.s3),
        ClSettingRow(
          icon: ClIcons.journal,
          title: l10n.aiConsentShareNotes,
          subtitle: l10n.aiConsentShareNotesSub,
          value: share,
          onChanged: _busy
              ? null
              : (v) {
                  setState(() => _share = v);
                  // Already given: the choice is saved at once.
                  if (granted) {
                    _run(
                      (r) => r.setConsent(shareMyNotes: v),
                      done: l10n.aiConsentSaved,
                      undo: () => setState(() => _share = null),
                    );
                  }
                },
        ),
        const SizedBox(height: ClSpace.s3),
        RhNote(l10n.aiConsentPersonal, icon: ClIcons.eye),
        const SizedBox(height: ClSpace.s2),
        Text(
          [
            if (granted && settings.consent?.grantedAt != null)
              l10n.aiConsentGranted(
                longDay(
                  locale,
                  settings.consent!.grantedAt!.toLocal().toIso8601String(),
                ),
              ),
            l10n.aiConsentVersion(aiConsentVersion),
          ].join(' · '),
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ],
      bottom: async.isLoading
          ? null
          : granted
          ? [
              ClButton(
                label: l10n.aiConsentWithdraw,
                expand: true,
                style: ClButtonStyle.destructive,
                loading: _busy,
                onPressed: _withdraw,
              ),
            ]
          : [
              ClButton(
                label: l10n.aiConsentAgree,
                expand: true,
                loading: _busy,
                onPressed: () => _run(
                  (r) => r.setConsent(shareMyNotes: share),
                  done: l10n.aiConsentSaved,
                  pop: true,
                ),
              ),
              const SizedBox(height: ClSpace.s2),
              ClButton(
                label: l10n.rhLater,
                expand: true,
                style: ClButtonStyle.secondary,
                onPressed: () => leaveRhythm(context),
              ),
            ],
    );
  }
}
