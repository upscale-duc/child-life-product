import 'package:flutter/material.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tabular_text.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_art.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_misc.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../core/widgets/cl_status.dart';

/// Dev-only showcase content. Sample copy is Figma's Vietnamese with an English draft (D-012);
/// production screens take copy from ARB files, not from here.
String sample(BuildContext context, String vi, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : vi;

class ShowcaseSection {
  const ShowcaseSection(this.id, this.title, this.builder);
  final String id;
  final String title;
  final WidgetBuilder builder;
}

final showcaseSections = <ShowcaseSection>[
  ShowcaseSection(
    'foundations',
    'Foundations',
    (context) => const _Foundations(),
  ),
  ShowcaseSection('buttons', 'Buttons', (context) => const _Buttons()),
  ShowcaseSection(
    'status',
    'Chips, status & avatar',
    (context) => const _Status(),
  ),
  ShowcaseSection(
    'controls',
    'Segmented, toggles & inputs',
    (context) => const _Controls(),
  ),
  ShowcaseSection('rows', 'Lists & rows', (context) => const _Rows()),
  ShowcaseSection('choices', 'Tiles & chips', (context) => const _Choices()),
  ShowcaseSection('navigation', 'Navigation', (context) => const _Navigation()),
  ShowcaseSection(
    'guidance',
    'Empty state & guidance',
    (context) => const _Guidance(),
  ),
];

class _Gap extends SizedBox {
  const _Gap() : super(height: ClSpace.s3, width: ClSpace.s3);
}

class _Foundations extends StatelessWidget {
  const _Foundations();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final swatches = <(String, Color)>[
      ('cloud', c.cloud),
      ('surface', c.surface),
      ('surface-2', c.surface2),
      ('ink', c.ink),
      ('ink-muted', c.inkMuted),
      ('mint', c.mint),
      ('mint-deep', c.mintDeep),
      ('mint-soft', c.mintSoft),
      ('sunshine', c.sunshine),
      ('peach', c.peach),
      ('error', c.error),
      ('pending', c.pending),
    ];
    final care = <(String, ClCareColor)>[
      ('bottle', cl.care.bottle),
      ('breast', cl.care.breast),
      ('sleep', cl.care.sleep),
      ('diaper', cl.care.diaper),
      ('growth', cl.care.growth),
      ('pump', cl.care.pump),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (name, color) in swatches)
              Column(
                children: [
                  Container(
                    width: 52,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.separator),
                    ),
                  ),
                  Text(
                    name,
                    style: cl.text.caption.copyWith(color: c.inkMuted),
                  ),
                ],
              ),
          ],
        ),
        const _Gap(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (name, tone) in care)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tone.soft,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: tone.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(name, style: cl.text.label.copyWith(color: tone.ink)),
                  ],
                ),
              ),
          ],
        ),
        const _Gap(),
        Text(
          sample(
            context,
            'Cùng chăm con, giữ trọn tuổi thơ',
            'Care together, keep their childhood',
          ),
          style: cl.text.display,
        ),
        Text(sample(context, 'Hôm nay', 'Today'), style: cl.text.largeTitle),
        Text(
          sample(context, 'Ghi nhanh, một tay', 'Quick log, one hand'),
          style: cl.text.title,
        ),
        Text(
          sample(context, 'Ngày sinh', 'Date of birth'),
          style: cl.text.title2,
        ),
        Text(sample(context, 'Bú bình', 'Bottle'), style: cl.text.headline),
        Text(
          sample(context, 'Tối đa 3 chạm là xong.', 'Done in 3 taps or fewer.'),
          style: cl.text.body,
        ),
        Text(
          sample(context, 'Tiếp tục với Apple', 'Continue with Apple'),
          style: cl.text.bodyStrong,
        ),
        Text(
          sample(context, '45 phút trước · Mẹ ghi', '45 min ago · Mum logged'),
          style: cl.text.label,
        ),
        Text(sample(context, 'Hôm nay', 'Today'), style: cl.text.caption),
        ClTabularText('1:24:08', style: cl.text.numeralXl),
        ClTabularText('120 ml', style: cl.text.numeral),
        const _Gap(),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final icon in ClIcons.values) ClIcon(icon, color: c.ink),
          ],
        ),
        const _Gap(),
        Row(
          children: [
            const ClLogo(height: 40),
            const SizedBox(width: 16),
            const ClLogo(kind: ClLogoKind.lockup, height: 32),
          ],
        ),
        const _Gap(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final art in [
              ClIllustration.miniBottle,
              ClIllustration.miniDrop,
              ClIllustration.miniMoon,
              ClIllustration.miniDiaper,
              ClIllustration.miniRuler,
              ClIllustration.miniWetDirty,
              ClIllustration.miniPump,
            ])
              ClArt(art, width: 48, height: 48),
          ],
        ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ClButton(label: sample(context, 'Lưu', 'Save'), onPressed: noop),
        ClButton(
          label: sample(context, 'Bắt đầu', 'Start'),
          style: ClButtonStyle.secondary,
          onPressed: noop,
        ),
        ClButton(
          label: sample(context, 'Thử lại', 'Retry'),
          style: ClButtonStyle.tinted,
          icon: ClIcons.retry,
          onPressed: noop,
        ),
        ClButton(
          label: sample(context, 'Bỏ qua', 'Skip'),
          style: ClButtonStyle.plain,
          onPressed: noop,
        ),
        ClButton(
          label: sample(context, 'Mời', 'Invite'),
          style: ClButtonStyle.outline,
          onPressed: noop,
        ),
        ClButton(
          label: sample(context, 'Xoá', 'Delete'),
          style: ClButtonStyle.destructive,
          onPressed: noop,
        ),
        ClButton(
          label: sample(context, 'Tiếp tục với Apple', 'Continue with Apple'),
          style: ClButtonStyle.apple,
          onPressed: noop,
        ),
        ClButton(label: sample(context, 'Lưu', 'Save'), onPressed: null),
        ClButton(
          label: sample(context, 'Lưu cữ bú', 'Save feed'),
          expand: true,
          onPressed: noop,
        ),
        ClRoundButton(
          semanticLabel: sample(context, 'Tiếp tục', 'Continue'),
          onPressed: noop,
        ),
        ClBackButton(
          semanticLabel: sample(context, 'Quay lại', 'Back'),
          onPressed: noop,
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      ClChip(
        label: sample(context, 'Chỉ ba mẹ', 'Parents only'),
        icon: ClIcons.lock,
      ),
      ClChip(
        label: sample(context, 'Gia đình', 'Family'),
        icon: ClIcons.family,
        style: ClChipStyle.warm,
      ),
      ClChip(
        label: sample(context, 'Lần đầu cười', 'First smile'),
        icon: ClIcons.spark,
        style: ClChipStyle.sun,
      ),
      ClSyncStatus(
        state: ClSyncState.synced,
        label: sample(context, 'Đã đồng bộ', 'Synced'),
      ),
      ClSyncStatus(
        state: ClSyncState.pending,
        label: sample(context, 'Chờ đồng bộ · 2', 'Waiting to sync · 2'),
      ),
      ClSyncStatus(
        state: ClSyncState.error,
        label: sample(context, 'Chưa lưu được', "Couldn't save"),
      ),
      const ClFloatChip(value: '120 ml'),
      ClFloatChip(
        value: sample(context, 'Đã đồng bộ', 'Synced'),
        lead: ClFloatChipLead.check,
      ),
      ClFloatChip(
        value: sample(context, 'Bú · 12:40', 'Feed · 12:40'),
        lead: ClFloatChipLead.avatar,
        initial: 'M',
      ),
      const ClAvatar(initial: 'M'),
      const ClAvatar(initial: 'T', style: ClAvatarStyle.warm),
      const ClAvatar(style: ClAvatarStyle.add),
      ClErrorBanner(
        lead: sample(context, 'Chưa lưu được.', "Couldn't save."),
        message: sample(
          context,
          'Thử lại, nội dung vẫn ở đây.',
          'Try again — your content is still here.',
        ),
      ),
    ],
  );
}

class _Controls extends StatefulWidget {
  const _Controls();

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  String milk = 'breast';
  String diaper = 'wet';
  bool nightCare = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSegmented<String>(
          options: const ['breast', 'formula'],
          selected: milk,
          onChanged: (v) => setState(() => milk = v),
          labelOf: (v) => v == 'breast'
              ? sample(context, 'Sữa mẹ', 'Breast milk')
              : sample(context, 'Sữa công thức', 'Formula'),
        ),
        const _Gap(),
        ClSegmented<String>(
          options: const ['wet', 'dirty', 'both'],
          selected: diaper,
          onChanged: (v) => setState(() => diaper = v),
          labelOf: (v) => switch (v) {
            'wet' => sample(context, 'Ướt', 'Wet'),
            'dirty' => sample(context, 'Bẩn', 'Dirty'),
            _ => sample(context, 'Cả hai', 'Both'),
          },
        ),
        const _Gap(),
        ClSettingRow(
          icon: ClIcons.sleep,
          title: 'Night care',
          subtitle: sample(
            context,
            'Theo lịch 21:00 – 06:00',
            'Scheduled 21:00 – 06:00',
          ),
          value: nightCare,
          onChanged: (v) => setState(() => nightCare = v),
        ),
        const _Gap(),
        ClCardGroup(
          children: [
            ClTextField(
              label: 'Email',
              placeholder: 'ten@email.com',
              keyboardType: TextInputType.emailAddress,
            ),
            ClTextField(
              label: sample(context, 'Mật khẩu', 'Password'),
              placeholder: sample(context, '8+ ký tự', '8+ characters'),
              password: true,
            ),
          ],
        ),
        const _Gap(),
        ClTextField(
          label: 'Email',
          placeholder: 'ten@email.com',
          standalone: true,
        ),
        const _Gap(),
        const ClCodeInput(),
        const _Gap(),
        const ClAmountField(value: '120', unit: 'ml', focused: true),
        const _Gap(),
        const ClAmountField(value: '4,3', unit: 'kg'),
        const _Gap(),
        ClTimeRow(
          label: sample(context, 'Thời gian', 'Time'),
          value: sample(context, 'Bây giờ · 15:05', 'Now · 15:05'),
          onTap: () {},
        ),
      ],
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClSectionHeader(
        title: sample(context, 'Hôm nay', 'Today'),
        linkLabel: sample(context, 'Lịch sử', 'History'),
        onLink: () {},
      ),
      const _Gap(),
      ClCardGroup(
        children: [
          ClListRow(
            title: 'Mai',
            subtitle: sample(context, 'Mẹ · Cùng nuôi', 'Mum · Co-parent'),
            leading: const ClAvatar(initial: 'M'),
            onTap: () {},
          ),
          ClListRow(
            title: sample(context, 'Mời người thân', 'Invite family'),
            isInvite: true,
            onTap: () {},
          ),
        ],
      ),
      const _Gap(),
      ClCardGroup(
        children: [
          ClDetailRow(
            icon: ClIcons.cake,
            label: sample(context, 'Ngày sinh', 'Date of birth'),
            value: sample(context, '17 tháng 9, 2026', '17 Sep 2026'),
            onTap: () {},
          ),
          ClDetailRow(
            icon: ClIcons.globe,
            label: sample(context, 'Múi giờ', 'Time zone'),
            value: 'GMT+7',
            onTap: () {},
          ),
        ],
      ),
      const _Gap(),
      ClCardGroup(
        children: [
          ClOptionRow(
            title: 'GMT+7',
            subtitle: sample(
              context,
              'Hà Nội, TP. Hồ Chí Minh',
              'Hanoi, Ho Chi Minh City',
            ),
            selected: true,
            onTap: () {},
          ),
          ClOptionRow(
            title: 'GMT+8',
            subtitle: 'Singapore, Kuala Lumpur',
            selected: false,
            onTap: () {},
          ),
        ],
      ),
      const _Gap(),
      ClCardGroup(
        children: [
          ClInfoRow(
            label: sample(context, 'Thời gian', 'Time'),
            value: sample(context, 'Hôm nay · 14:20', 'Today · 14:20'),
          ),
          ClInfoRow(
            label: sample(context, 'Người ghi', 'Logged by'),
            value: sample(context, 'Mẹ Mai (bạn)', 'Mum Mai (you)'),
          ),
        ],
      ),
      const _Gap(),
      ClCardGroup(
        children: [
          ClMemberRow(
            initial: 'M',
            name: 'Mai',
            detail: sample(context, 'Mẹ · Cùng nuôi', 'Mum · Co-parent'),
            status: ClMemberStatus.you,
            youLabel: sample(context, 'Bạn', 'You'),
          ),
          ClMemberRow(
            initial: 'L',
            name: 'Cô Lan',
            detail: sample(
              context,
              'Bảo mẫu · Người chăm sóc',
              'Nanny · Caregiver',
            ),
            status: ClMemberStatus.member,
            onTap: () {},
          ),
          ClMemberRow(
            initial: '?',
            name: 'ba.ngoai@gmail.com',
            detail: sample(
              context,
              'Bà ngoại · hết hạn 15 thg 10',
              'Grandma · expires 15 Oct',
            ),
            status: ClMemberStatus.pending,
            resendLabel: sample(context, 'Gửi lại', 'Resend'),
            onResend: () {},
          ),
        ],
      ),
      const _Gap(),
      const ClAccountRow(
        email: 'mai.nguyen@email.com',
        provider: 'Apple',
      ),
    ],
  );
}

class _Choices extends StatefulWidget {
  const _Choices();

  @override
  State<_Choices> createState() => _ChoicesState();
}

class _ChoicesState extends State<_Choices> {
  int filter = 0;
  int relation = 1;
  int day = 6;
  int diaper = 0;
  final trackers = {0, 1};
  int role = 1;
  ClThemePreview theme = ClThemePreview.light;

  @override
  Widget build(BuildContext context) {
    final filters = [
      sample(context, 'Tất cả', 'All'),
      sample(context, 'Bú', 'Feeds'),
      sample(context, 'Ngủ', 'Sleep'),
      sample(context, 'Tã', 'Diapers'),
    ];
    final relations = [
      sample(context, 'Mẹ', 'Mum'),
      sample(context, 'Ba', 'Dad'),
      sample(context, 'Bà', 'Grandma'),
      sample(context, 'Bảo mẫu', 'Nanny'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < filters.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                ClFilterChip(
                  label: filters[i],
                  selected: filter == i,
                  onTap: () => setState(() => filter = i),
                ),
              ],
            ],
          ),
        ),
        const _Gap(),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < relations.length; i++)
              ClRelationChip(
                label: relations[i],
                selected: relation == i,
                onTap: () => setState(() => relation = i),
              ),
          ],
        ),
        const _Gap(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 7; i++)
              ClDayPill(
                weekday: ['T6', 'T7', 'CN', 'T2', 'T3', 'T4', 'T5'][i],
                day: '${i + 2}',
                selected: day == i,
                onTap: () => setState(() => day = i),
              ),
          ],
        ),
        const _Gap(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (i, label, art) in [
              (0, sample(context, 'Ướt', 'Wet'), ClIllustration.miniDrop),
              (1, sample(context, 'Bẩn', 'Dirty'), ClIllustration.miniDiaper),
              (
                2,
                sample(context, 'Cả hai', 'Both'),
                ClIllustration.miniWetDirty,
              ),
            ])
              ClChoiceTile(
                label: label,
                art: ClArt(art),
                selected: diaper == i,
                onTap: () => setState(() => diaper = i),
              ),
          ],
        ),
        const _Gap(),
        Wrap(
          spacing: 11,
          runSpacing: 11,
          children: [
            for (final (i, label, art) in [
              (
                0,
                sample(context, 'Bú bình', 'Bottle'),
                ClIllustration.miniBottle,
              ),
              (
                1,
                sample(context, 'Giấc ngủ', 'Sleep'),
                ClIllustration.miniMoon,
              ),
            ])
              ClSelectTile(
                label: label,
                art: ClArt(art),
                selected: trackers.contains(i),
                onTap: () => setState(
                  () => trackers.contains(i)
                      ? trackers.remove(i)
                      : trackers.add(i),
                ),
              ),
          ],
        ),
        const _Gap(),
        Wrap(
          spacing: 11,
          runSpacing: 11,
          children: [
            ClPermissionTile(
              label: sample(
                context,
                'Ghi bú, ngủ, tã',
                'Log feeds, sleep, diapers',
              ),
              allowed: true,
            ),
            ClPermissionTile(
              label: sample(context, 'Kỷ niệm', 'Memories'),
              allowed: false,
            ),
          ],
        ),
        const _Gap(),
        for (final (i, title, subtitle) in [
          (
            0,
            sample(context, 'Cùng nuôi', 'Co-parent'),
            sample(
              context,
              'Toàn quyền, như ba mẹ',
              'Full rights, like parents',
            ),
          ),
          (
            1,
            sample(context, 'Người chăm sóc', 'Caregiver'),
            sample(context, 'Ghi & xem chăm sóc', 'Log & view care'),
          ),
        ]) ...[
          ClRoleOption(
            icon: ClIcons.today,
            title: title,
            subtitle: subtitle,
            selected: role == i,
            onTap: () => setState(() => role = i),
            permissions: [
              (
                sample(context, 'Ghi bú, ngủ, tã', 'Log feeds, sleep, diapers'),
                true,
              ),
              (sample(context, 'Xem kỷ niệm', 'See memories'), i == 0),
            ],
          ),
          const _Gap(),
        ],
        ClEntryOption(
          icon: ClIcons.clock,
          title: sample(context, 'Bắt đầu hẹn giờ', 'Start timer'),
          subtitle: sample(
            context,
            'Teddy vừa ngủ. Đồng hồ chạy, cả nhà cùng thấy',
            'Teddy just fell asleep. The clock runs and the family sees it',
          ),
          care: context.cl.care.sleep,
          primary: true,
          onTap: () {},
        ),
        const _Gap(),
        ClEntryOption(
          icon: ClIcons.edit,
          title: sample(context, 'Nhập giấc đã ngủ', 'Enter a past sleep'),
          subtitle: sample(
            context,
            'Quên bấm giờ? Chọn giờ bắt đầu và kết thúc',
            'Forgot the timer? Pick start and end',
          ),
          care: context.cl.care.sleep,
          onTap: () {},
        ),
        const _Gap(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (p, label) in [
              (ClThemePreview.light, sample(context, 'Sáng', 'Light')),
              (ClThemePreview.dark, sample(context, 'Tối', 'Dark')),
              (ClThemePreview.auto, sample(context, 'Tự động', 'Automatic')),
            ])
              ClThemeOption(
                preview: p,
                label: label,
                selected: theme == p,
                onTap: () => setState(() => theme = p),
              ),
          ],
        ),
      ],
    );
  }
}

class _Navigation extends StatefulWidget {
  const _Navigation();

  @override
  State<_Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<_Navigation> {
  final active = {
    ClRole.parent: ClTab.today,
    ClRole.caregiver: ClTab.today,
    ClRole.relative: ClTab.memories,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in ClRole.values) ...[
          Row(
            children: [
              Expanded(
                child: ClNavBar(
                  role: role,
                  active: active[role]!,
                  initial: 'M',
                  onSelect: (t) => setState(() => active[role] = t),
                ),
              ),
              if (roleCanQuickLog(role)) ...[
                const SizedBox(width: ClSpace.s3),
                ClQuickLogButton(onPressed: () {}),
              ],
            ],
          ),
          const _Gap(),
        ],
        ClNavHeader(
          subtitle: sample(
            context,
            'Thứ Năm, 8 tháng 10',
            'Thursday, 8 October',
          ),
          title: sample(context, 'Hôm nay', 'Today'),
          trailing: ClBabySwitcher(
            label: sample(context, 'Teddy · 3 tuần', 'Teddy · 3 weeks'),
            avatar: const ClArt(ClIllustration.babyFace),
            hasMultiple: true,
            onTap: () {},
          ),
        ),
        ClTopBar(onBack: () {}, onSkip: () {}),
        const _Gap(),
        ClTopBar(onBack: () {}, progress: 0.5),
        const _Gap(),
        ClTopBar(
          onBack: () {},
          countdown: ClChip(
            label: sample(context, 'Còn 68 giờ', '68 hours left'),
            icon: ClIcons.clock,
          ),
        ),
        const _Gap(),
        ClTopBar(brand: const ClLogo(kind: ClLogoKind.lockup, height: 28)),
        const _Gap(),
        const Center(child: ClPageDots(count: 4, index: 1)),
        const _Gap(),
        ClButton(
          label: sample(context, 'Mở sheet', 'Open sheet'),
          style: ClButtonStyle.secondary,
          onPressed: () => showClSheet<void>(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClSheetHeader(
                  title: sample(context, 'Ghi cữ bú', 'Log a feed'),
                ),
                const ClAmountField(value: '120', unit: 'ml', focused: true),
                const SizedBox(height: ClSpace.s3),
                ClButton(
                  label: sample(context, 'Lưu cữ bú', 'Save feed'),
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClEmptyState(
        icon: ClIcons.today,
        title: sample(
          context,
          'Chưa có ghi chép hôm nay',
          'Nothing logged today',
        ),
        message: sample(
          context,
          'Ghi khi gia đình cần nhé.',
          'Log whenever the family needs.',
        ),
        actionLabel: sample(context, 'Ghi cữ bú', 'Log a feed'),
        actionIcon: ClIcons.feed,
        onAction: () {},
      ),
      ClButton(
        label: sample(context, 'Hiện thông báo', 'Show toast'),
        style: ClButtonStyle.secondary,
        onPressed: () => showClToast(
          context,
          message: sample(
            context,
            'Đã ghi · Bú bình 120 ml',
            'Logged · Bottle 120 ml',
          ),
          actionLabel: sample(context, 'Hoàn tác', 'Undo'),
        ),
      ),
      const _Gap(),
      const ClSkeleton(width: 220, height: 20),
      const _Gap(),
      const ClSkeleton(height: 72, radius: 24),
      const _Gap(),
      ClCoachmark(
        text: sample(
          context,
          'Chạm để ghi việc đầu tiên',
          'Tap to log your first entry',
        ),
      ),
      const _Gap(),
      ClTourTip(
        step: sample(context, 'Bước 1/3', 'Step 1/3'),
        title: sample(context, 'Ghi cữ bú đầu tiên', 'Log the first feed'),
        body: sample(
          context,
          'Chạm thẻ Bú bình để ghi. Các thẻ khác cũng ghi y như vậy.',
          'Tap the Bottle card to log. Other cards work the same way.',
        ),
        skipLabel: sample(context, 'Bỏ qua', 'Skip'),
        nextLabel: sample(context, 'Tiếp', 'Next'),
        onSkip: () {},
        onNext: () {},
      ),
    ],
  );
}
