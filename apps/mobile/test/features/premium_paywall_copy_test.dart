import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Premium benefit counts interpolate and pluralise in English', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final n in [0, 1, 4, 200]) {
      for (final label in [l10n.pv2CardLumiLimit(n)]) {
        expect(label, contains('$n'));
        expect(label, isNot(contains('#')));
      }
    }
    expect(l10n.pv2CardVideoLimit(1), 'Unlimited video exports');
    expect(l10n.pv2CardVideoLimit(4), 'Unlimited video exports');
    expect(l10n.pv2CardRhythmLimit(200), 'Included in Premium');
    expect(l10n.pv2CardLumiLimit(1), contains('1 credit/month'));
    expect(l10n.pv2CardLumiLimit(200), contains('200 credits/month'));
    expect(l10n.premiumLumiBullet3(1), contains('1 credit/month'));
    expect(l10n.premiumLumiBullet3(350), contains('350 credits/month'));
    expect(l10n.premiumSeatsBullet3(1), contains('1 carer'));
    expect(l10n.premiumSeatsBullet3(8), contains('8 carers'));
    expect(l10n.pv2CardCaregiversLimit(1, 1), contains('1 logging seat'));
    expect(l10n.pv2CardCaregiversLimit(6, 3), contains('6 logging seats'));
  });

  test(
    'reviewed Vietnamese benefit allowances follow the configured plan',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      expect(l10n.premiumLumiBullet3(350), contains('350 credit/tháng'));
      expect(l10n.premiumSeatsBullet3(8), 'Thoải mái cùng 8 người chăm con');
    },
  );
}
