import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_segmented.dart';
import 'showcase_sections.dart';

/// Dev-only component showcase (S1): every shared component in Light / Night care, vi / en.
class ShowcaseScreen extends ConsumerStatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen> {
  ClPalette palette = ClPalette.light;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Theme(
      data: buildClTheme(palette),
      child: Builder(
        builder: (context) {
          final cl = context.cl;
          return Scaffold(
            backgroundColor: cl.colors.cloud,
            appBar: AppBar(
              backgroundColor: cl.colors.cloud,
              foregroundColor: cl.colors.ink,
              title: Text('Design system', style: cl.text.headline),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                120,
              ),
              children: [
                ClSegmented<ClPalette>(
                  options: ClPalette.values,
                  selected: palette,
                  onChanged: (p) => setState(() => palette = p),
                  labelOf: (p) => p == ClPalette.light ? 'Light' : 'Night care',
                ),
                const SizedBox(height: ClSpace.s3),
                ClSegmented<String>(
                  options: const ['vi', 'en'],
                  selected: locale.languageCode,
                  onChanged: (code) => ref
                      .read(localeOverrideProvider.notifier)
                      .set(Locale(code)),
                  labelOf: (code) => code == 'vi' ? 'Tiếng Việt' : 'English',
                ),
                for (final section in showcaseSections) ...[
                  const SizedBox(height: ClSpace.s6),
                  Text(section.title, style: cl.text.title2),
                  const SizedBox(height: ClSpace.s3),
                  section.builder(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
