import 'package:child_life/features/assistant/assistant_screens.dart';
import 'package:flutter_test/flutter_test.dart';

// Lumi L5: the rule editor link a "nhắc … mỗi 3 tiếng" reply carries is opened only in its shape.
void main() {
  test('only the rule editor with known, well-formed values', () {
    expect(
      ruleEditorRoute('/care/reminders/rules/new?type=feed&interval=180'),
      '/care/reminders/rules/new?type=feed&interval=180',
    );
    expect(
      ruleEditorRoute(
        '/care/reminders/rules/new?type=diaper&times=08%3A00%2C14%3A00&days=6%2C7',
      ),
      isNotNull,
    );
    for (final bad in [
      null,
      'https://evil.example/care/reminders/rules/new?type=feed',
      '/care/reminders/rules/rr_1/edit',
      '/care/reminders/rules/new?type=vitamin',
      '/care/reminders/rules/new?type=feed&next=/me',
      '/care/reminders/rules/new?times=8h',
    ]) {
      expect(ruleEditorRoute(bad), isNull, reason: bad);
    }
  });
}
