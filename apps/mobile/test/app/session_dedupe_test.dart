import 'package:child_life/app/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'member snapshots with the same data compare equal (metadata-only repeats)',
    () {
      Map<String, dynamic> doc() => {
        'uid': 'u',
        'babyId': 'b',
        'role': 'coParent',
        'joinedAt': Timestamp.fromMillisecondsSinceEpoch(1000),
        'extraRights': {'spending': true},
        'tags': ['a', 'b'],
      };
      expect(sameFirestoreData([doc()], [doc()]), isTrue);
      expect(sameFirestoreData(null, null), isTrue);
      expect(sameFirestoreData(null, [doc()]), isFalse);
      expect(
        sameFirestoreData([doc()], [doc()..['role'] = 'relative']),
        isFalse,
      );
      expect(
        sameFirestoreData(
          [doc()],
          [
            doc()..['extraRights'] = {'spending': false},
          ],
        ),
        isFalse,
      );
      expect(sameFirestoreData([doc()], [doc(), doc()]), isFalse);
    },
  );
}
