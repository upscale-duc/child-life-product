import 'package:child_life/features/family/countries.dart';
import 'package:child_life/features/onboarding/setup_draft.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-078: where the family lives, asked on 11 Thông tin bé.
void main() {
  test('every offered country has an ambulance number', () {
    expect(familyCountries.toSet(), emergencyNumbers.keys.toSet());
    expect(familyCountries.first, 'VN');
    expect(emergencyNumbers['VN'], '115');
  });

  test(
    'a zone that belongs to one country preselects it; shared zones do not',
    () {
      expect(countryForZone('Asia/Ho_Chi_Minh'), 'VN');
      expect(countryForZone('Australia/Sydney'), 'AU');
      expect(countryForZone('Europe/Berlin'), 'DE');
      expect(countryForZone('America/New_York'), isNull);
      expect(countryForZone('America/Toronto'), isNull);
      for (final zone in [
        'Asia/Ho_Chi_Minh',
        'Asia/Tokyo',
        'Europe/London',
        'Asia/Dubai',
      ]) {
        expect(familyCountries, contains(countryForZone(zone)));
      }
    },
  );

  test('the country goes to createBabyProfile only once picked', () {
    final draft = SetupDraft(nickname: 'Teddy');
    expect(draft.toInput().toJson().containsKey('country'), isFalse);
    expect(draft.copyWith(country: 'US').toInput().toJson()['country'], 'US');
  });
}
