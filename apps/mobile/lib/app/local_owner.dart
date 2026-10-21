import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session.dart';

/// Captured by each store/queue, never read again as another account's identity.
final localOwnerProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  return session is SessionSignedIn ? session.user.uid : null;
});
