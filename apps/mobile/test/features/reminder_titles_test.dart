import 'package:child_life/features/reminders/reminder_titles.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('an English solids title reads in Vietnamese, name kept', () {
    expect(
      reminderTitle(vi, en.sdReminderTitle('Teddy')),
      vi.sdReminderTitle('Teddy'),
    );
    expect(
      reminderTitle(en, vi.sdReminderTitle('Bé Na')),
      en.sdReminderTitle('Bé Na'),
    );
  });

  test('the old "nearly 6 months" wording reads as the current title', () {
    expect(
      reminderTitle(vi, 'Teddy is nearly 6 months: how to start solids'),
      'Chuẩn bị cho Teddy ăn dặm',
    );
    expect(
      reminderTitle(en, 'Teddy gần 6 tháng: xem cách bắt đầu ăn dặm'),
      en.sdReminderTitle('Teddy'),
    );
  });

  test('re-measure titles follow the reader', () {
    expect(reminderTitle(vi, en.nuRemeasureWeight), vi.nuRemeasureWeight);
    expect(reminderTitle(en, vi.nuRemeasureLength), en.nuRemeasureLength);
  });

  test('a title the family typed stays as written', () {
    for (final t in [
      'Làm giấy khai sinh cho Teddy',
      'Chuẩn bị cho  ăn dặm',
      '',
    ]) {
      expect(reminderTitle(en, t), t);
    }
  });
}
