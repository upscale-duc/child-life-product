import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/cl_theme.dart';
import '../../core/widgets/cl_button.dart';
import '../../l10n/app_localizations.dart';
import 'print_repository.dart';
import 'print_widgets.dart';

class PrintReviews extends ConsumerStatefulWidget {
  const PrintReviews({super.key});
  @override
  ConsumerState<PrintReviews> createState() => _PrintReviewsState();
}

class _PrintReviewsState extends ConsumerState<PrintReviews> {
  int? stars;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        data = ref.watch(printReviewsProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ClButton(
        label: l.psRetry,
        onPressed: () => ref.invalidate(printReviewsProvider),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Text(l.psNoReviews, style: context.cl.text.caption);
        }
        final avg =
            reviews.fold<int>(
              0,
              (sum, r) => sum + (r['rating'] as num).toInt(),
            ) /
            reviews.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${avg.toStringAsFixed(1)} / 5 · ${reviews.length}',
              style: context.cl.text.headline,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l.psAllReviews),
                  selected: stars == null,
                  onSelected: (_) => setState(() => stars = null),
                ),
                for (final n in [5, 4, 3, 2, 1])
                  ChoiceChip(
                    label: Text('$n ★'),
                    selected: stars == n,
                    onSelected: (_) => setState(() => stars = n),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final r in reviews.where(
              (r) => stars == null || r['rating'] == stars,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PrintCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r['rating']} ★ · ${l.psVerifiedBuyer}',
                        style: context.cl.text.label.copyWith(
                          fontFamily: 'Be Vietnam Pro Keepsake',
                          height: 1.3,
                          color: context.cl.colors.mintText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(r['message'] as String, style: context.cl.text.body),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
