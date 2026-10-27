import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../app/session.dart';
import 'print_models.dart';

final printReviewsProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('printReviewsPublic')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList()),
);

final printCatalogProvider = FutureProvider<PrintCatalog>((ref) async {
  final result = await ref
      .watch(functionsProvider)
      .httpsCallable('printStudioCatalog')
      .call<dynamic>();
  return PrintCatalog(Map<String, dynamic>.from(result.data as Map));
}, retry: (_, _) => null);

final printDraftProvider = StreamProvider.family<PrintDesign?, String>((
  ref,
  babyId,
) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionSignedIn) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .doc('babies/$babyId/printDrafts/${session.user.uid}')
      .snapshots()
      .map((d) {
        final j = d.data()?['design'];
        return j is Map
            ? PrintDesign.fromJson(Map<String, dynamic>.from(j))
            : null;
      });
});

/// PR-1: the print file job the draft remembers (cleared when the design changes).
final printDraftExportJobProvider = StreamProvider.autoDispose
    .family<String?, String>((ref, babyId) {
      final session = ref.watch(sessionProvider);
      if (session is! SessionSignedIn) return Stream.value(null);
      return ref
          .watch(firestoreProvider)
          .doc('babies/$babyId/printDrafts/${session.user.uid}')
          .snapshots()
          .map((d) => d.data()?['exportJobId'] as String?);
    });

/// PR-1: one print file job, live while it builds.
final printExportJobProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, (String, String)>(
      (ref, key) => ref
          .watch(firestoreProvider)
          .doc('babies/${key.$1}/printExportJobs/${key.$2}')
          .snapshots()
          .map((d) => d.data()),
    );

final printOrdersProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, babyId) {
      final session = ref.watch(sessionProvider);
      if (session is! SessionSignedIn) return Stream.value([]);
      // One field query avoids introducing a composite index; sort bounded results locally.
      return ref
          .watch(firestoreProvider)
          .collection('babies/$babyId/printOrders')
          .where('uid', isEqualTo: session.user.uid)
          .snapshots()
          .map((s) {
            final docs = s.docs.map((d) => d.data()).toList();
            docs.sort(
              (a, b) =>
                  ((b['createdAt'] as dynamic)?.millisecondsSinceEpoch
                              as int? ??
                          0)
                      .compareTo(
                        (a['createdAt'] as dynamic)?.millisecondsSinceEpoch
                                as int? ??
                            0,
                      ),
            );
            return docs;
          });
    });

typedef PrintAction =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    );
final printActionProvider = Provider<PrintAction>((ref) {
  final functions = ref.watch(functionsProvider);
  return (name, data) async {
    final result = await functions
        .httpsCallable(
          name,
          options: HttpsCallableOptions(
            timeout: name == 'printStudioOrder'
                ? const Duration(seconds: 30)
                : const Duration(minutes: 5),
          ),
        )
        .call<dynamic>(data);
    return Map<String, dynamic>.from(result.data as Map);
  };
});
Future<Map<String, dynamic>> printCall(
  WidgetRef ref,
  String name,
  Map<String, dynamic> data,
) => ref.read(printActionProvider)(name, data);
