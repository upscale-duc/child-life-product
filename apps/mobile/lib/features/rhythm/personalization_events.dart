import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

/// P-172 I3: fixed dimensions only; identifiers stay local for impression deduplication.
final personalizationEventSinkProvider =
    Provider<Future<void> Function(String, String?)>(
      (ref) => (event, dim) async {
        await ref
            .read(functionsProvider)
            .httpsCallable('recordAppEvent')
            .call<Object?>({'event': event, 'dim': ?dim});
      },
    );
void personalEvent(WidgetRef ref, String event, [String? dim]) {
  if (!ref.context.mounted) return;
  unawaited(
    ref
        .read(personalizationEventSinkProvider)(event, dim)
        .catchError((Object _) {}),
  );
}

class PersonalImpression extends ConsumerStatefulWidget {
  const PersonalImpression({
    required this.identity,
    required this.child,
    this.reason = 'INTEREST',
    super.key,
  });
  final String identity;
  final String reason;
  final Widget child;
  @override
  ConsumerState<PersonalImpression> createState() => _PersonalImpressionState();
}

class _PersonalImpressionState extends ConsumerState<PersonalImpression> {
  ScrollPosition? _position;
  final _seen = <String>{};
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position;
      _position?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(covariant PersonalImpression oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _seen.contains(widget.identity)) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final view = Offset.zero & MediaQuery.sizeOf(context);
    if (rect.intersect(view).height >= box.size.height.clamp(1, 48) &&
        rect.intersect(view).width >= box.size.width.clamp(1, 48)) {
      _seen.add(widget.identity);
      personalEvent(ref, 'nextActionShown', widget.reason);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
