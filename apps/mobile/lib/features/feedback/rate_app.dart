import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../l10n/app_localizations.dart';
import '../app_update/app_update_repository.dart';
import '../me/me_widgets.dart';

/// The store page to rate on (FB1): the App Store / Google Play link from `publicConfig/
/// appUpdate` (UP, D-061), with "write a review" on iOS. Null until the app is published.
Uri? rateUrlOf(Uri? storeUrl, {required bool ios}) {
  if (storeUrl == null) return null;
  if (!ios) return storeUrl;
  return storeUrl.replace(
    queryParameters: {...storeUrl.queryParameters, 'action': 'write-review'},
  );
}

/// FB1 "Đánh giá trên App Store" ("… Google Play" on Android): always there, opened only when
/// tapped; unlike FB5 it is the person's own choice, so no rule applies.
class RateAppRow extends ConsumerWidget {
  const RateAppRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return MeRow(
      icon: ClIcons.star,
      title: ios ? l10n.meRateAppStore : l10n.meRatePlay,
      onTap: () async {
        final config = ref.read(appUpdateConfigProvider).value;
        final url = rateUrlOf(
          config
              ?.forPlatform(ios: ref.read(updateFromAppStoreProvider))
              .storeUrl,
          ios: ios,
        );
        if (url == null) {
          showClToast(context, message: l10n.meRateUnavailable);
          return;
        }
        await ref.read(openStoreProvider)(url);
      },
    );
  }
}
