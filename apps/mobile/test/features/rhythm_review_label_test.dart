import 'package:child_life/features/rhythm/rhythm_labels.dart';
import 'package:child_life/features/rhythm/rhythm_models.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// D-148: Nhịp content signed "Child Life Team" reads once, not "Child Life Team · Child Life Team".
void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));
  const team = ContentReview(
    reviewer: 'Child Life Team',
    credential: 'Child Life Team',
    reviewedOn: '2026-10-30',
  );
  const person = ContentReview(
    reviewer: 'BS. Lan',
    credential: 'Nhi khoa',
    reviewedOn: '2026-10-30',
  );

  test(
    'the team signs once; a person keeps the credential; none is pending',
    () {
      expect(reviewLabel(vi, team), 'Đã duyệt bởi Child Life Team');
      expect(reviewLabel(en, team), 'Reviewed by Child Life Team');
      expect(reviewLabel(vi, person), 'Đã duyệt bởi BS. Lan · Nhi khoa');
      expect(reviewLabel(vi, null), vi.rhReviewPending);
    },
  );
}
