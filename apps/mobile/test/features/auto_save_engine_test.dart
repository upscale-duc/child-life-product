import 'dart:typed_data';

import 'package:child_life/features/auto_save/auto_save_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tự lưu (D-066): which baby a photo may show (P-149) and how near-copies are grouped and
/// ranked (P-146). Prints are tiny hand-made vectors; only their directions matter.
void main() {
  Float32List v(List<double> xs) => Float32List.fromList(xs);
  final t0 = DateTime(2026, 10, 12, 9);

  AssetInfo photo(
    String id, {
    Duration at = Duration.zero,
    List<FaceInfo> faces = const [],
    Float32List? print,
    String? burst,
    bool favorite = false,
    bool video = false,
    double? aesthetics,
  }) => AssetInfo(
    id: id,
    captureAt: t0.add(at),
    faces: faces,
    print: print,
    burst: burst,
    favorite: favorite,
    video: video,
    aesthetics: aesthetics,
  );

  group('printDistance', () {
    test('is 0 for the same direction and grows with the angle', () {
      expect(printDistance(v([1, 0]), v([2, 0])), closeTo(0, 1e-9));
      expect(printDistance(v([1, 0]), v([0, 1])), closeTo(1, 1e-9));
      expect(printDistance(v([1, 0]), v([-1, 0])), closeTo(2, 1e-9));
    });
    test('treats prints of different lengths as unrelated', () {
      expect(printDistance(v([1, 0]), v([1, 0, 0])), 2);
    });
  });

  group('matchBaby', () {
    final teddy = BabyFaces(
      samples: [
        v([1, 0, 0]),
        v([0.98, 0.2, 0]),
      ],
    );
    final na = BabyFaces(
      samples: [
        v([0, 1, 0]),
        v([0.2, 0.98, 0]),
      ],
    );

    test('picks the baby whose samples are closest', () {
      final a = photo(
        'a',
        faces: [
          FaceInfo(size: 0.3, print: v([0.99, 0.1, 0])),
        ],
      );
      final m = matchBaby(a, {'teddy': teddy, 'na': na});
      expect(m?.babyId, 'teddy');
      expect(m?.face, 0);
    });

    test('one baby per photo: the best face wins when two babies appear', () {
      final a = photo(
        'a',
        faces: [
          FaceInfo(size: 0.3, print: v([0.9, 0.3, 0])),
          FaceInfo(size: 0.3, print: v([0.1, 1, 0])),
        ],
      );
      expect(matchBaby(a, {'teddy': teddy, 'na': na})?.babyId, 'na');
    });

    test(
      'ignores small faces, faces far from every sample and babies without samples',
      () {
        final small = photo(
          's',
          faces: [
            FaceInfo(size: 0.02, print: v([1, 0, 0])),
          ],
        );
        final far = photo(
          'f',
          faces: [
            FaceInfo(size: 0.3, print: v([0, 0, 1])),
          ],
        );
        expect(matchBaby(small, {'teddy': teddy}), isNull);
        expect(matchBaby(far, {'teddy': teddy}), isNull);
        expect(matchBaby(far, {'bin': const BabyFaces(samples: [])}), isNull);
      },
    );

    test(
      'a face closer to a rejected face than to the samples is someone else',
      () {
        final cousin = v([0.97, 0.25, 0]);
        final withNeg = BabyFaces(samples: teddy.samples, negatives: [cousin]);
        final a = photo(
          'a',
          faces: [
            FaceInfo(size: 0.3, print: v([0.96, 0.27, 0])),
          ],
        );
        expect(matchBaby(a, {'teddy': teddy})?.babyId, 'teddy');
        expect(matchBaby(a, {'teddy': withNeg}), isNull);
      },
    );
  });

  group('groupAndRank', () {
    Candidate c(AssetInfo a) => Candidate(
      asset: a,
      match: const FaceMatch(babyId: 'teddy', distance: 0.1, face: 0),
    );
    FaceInfo face(double quality, [double size = 0.3]) =>
        FaceInfo(size: size, quality: quality, print: v([1, 0]));

    test('near-copies in one moment form one group led by the best face', () {
      final groups = groupAndRank([
        c(photo('blurry', print: v([1, 0.01]), faces: [face(0.2)])),
        c(
          photo(
            'sharp',
            at: const Duration(seconds: 5),
            print: v([1, 0.02]),
            faces: [face(0.9)],
          ),
        ),
        c(
          photo(
            'other',
            at: const Duration(seconds: 10),
            print: v([0, 1]),
            faces: [face(0.5)],
          ),
        ),
      ]);
      expect(groups, hasLength(2));
      final pair = groups.firstWhere((g) => g.items.length == 2);
      expect(pair.best.asset.id, 'sharp');
      expect(pair.preselected, {'sharp'});
    });

    test('a long pause starts a new moment even for look-alike photos', () {
      final groups = groupAndRank([
        c(photo('a', print: v([1, 0]), faces: [face(0.5)])),
        c(
          photo(
            'b',
            at: const Duration(minutes: 10),
            print: v([1, 0]),
            faces: [face(0.5)],
          ),
        ),
      ]);
      expect(groups, hasLength(2));
      expect(groups.first.best.asset.id, 'b', reason: 'newest first');
    });

    test('a burst is one group; favourites lead; videos stay alone', () {
      final groups = groupAndRank([
        c(photo('b1', burst: 'x', print: v([1, 0]), faces: [face(0.9)])),
        c(
          photo(
            'b2',
            at: const Duration(seconds: 1),
            burst: 'x',
            print: v([0, 1]),
            faces: [face(0.5)],
            favorite: true,
          ),
        ),
        c(
          photo(
            'vid',
            at: const Duration(seconds: 2),
            video: true,
            print: v([1, 0]),
            faces: [face(0.9)],
          ),
        ),
      ]);
      expect(groups, hasLength(2));
      final burst = groups.firstWhere((g) => g.items.length == 2);
      expect(burst.best.asset.id, 'b2');
      expect(groups.any((g) => g.items.single.asset.id == 'vid'), isTrue);
    });

    test('a large group pre-selects the runner-up when it is close', () {
      final groups = groupAndRank([
        for (var i = 0; i < 6; i++)
          c(
            photo(
              'p$i',
              at: Duration(seconds: i),
              print: v([1, 0]),
              faces: [
                face(
                  i == 5
                      ? 0.95
                      : i == 4
                      ? 0.93
                      : 0.1,
                ),
              ],
            ),
          ),
      ]);
      expect(groups.single.preselected, {'p5', 'p4'});
    });
  });

  test('estimatedBytes: photos by pixels, videos by length and size', () {
    final p = AssetInfo(id: 'p', captureAt: t0, width: 4032, height: 3024);
    final vid = AssetInfo(
      id: 'v',
      captureAt: t0,
      video: true,
      width: 1920,
      height: 1080,
      durationMs: 10000,
    );
    expect(p.estimatedBytes, closeTo(3600000, 100000));
    expect(vid.estimatedBytes, 13000000);
  });
}
