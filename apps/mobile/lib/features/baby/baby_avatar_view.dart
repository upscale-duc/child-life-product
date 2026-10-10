import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/widgets/cl_art.dart';
import 'baby_models.dart';
import 'baby_repository.dart';

/// Illustrated avatars on 11c: the baby face with circle / hat colours swapped
/// (mint · peach · sun · night). Illustration colours are fixed in both palettes.
const _presetColors = <int, (Color circle, Color hat)>{
  1: (Color(0xFF2CBFB3), Color(0xFFFFD166)),
  2: (Color(0xFFFFA58D), Color(0xFF2CBFB3)),
  3: (Color(0xFFFFD166), Color(0xFFFFA58D)),
  4: (Color(0xFF173D44), Color(0xFFFFD166)),
};

class _PresetColorMapper extends ColorMapper {
  const _PresetColorMapper(this.circle, this.hat);
  final Color circle;
  final Color hat;

  static const _sourceCircle = Color(0xFF2CBFB3);
  static const _sourceHat = Color(0xFFFFD166);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == _sourceCircle) return circle;
    if (color == _sourceHat) return hat;
    return color;
  }
}

/// Round baby avatar: a preset illustration, raw photo bytes, or a saved baby's avatar.
class BabyAvatarImage extends StatelessWidget {
  const BabyAvatarImage.preset(this.preset, {required this.size, super.key})
    : photo = null;
  const BabyAvatarImage.photo(
    Uint8List this.photo, {
    required this.size,
    super.key,
  }) : preset = 1;

  final int preset;
  final Uint8List? photo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = photo;
    if (bytes != null) {
      return ClipOval(
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    final (circle, hat) = _presetColors[preset] ?? _presetColors[1]!;
    return ExcludeSemantics(
      child: SvgPicture.asset(
        ClIllustration.babyFace.asset,
        width: size,
        height: size,
        colorMapper: _PresetColorMapper(circle, hat),
      ),
    );
  }
}

/// A saved baby's avatar; photos load through the member-checked callable.
class SavedBabyAvatar extends ConsumerWidget {
  const SavedBabyAvatar({required this.baby, required this.size, super.key});

  final Baby baby;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (baby.avatar) {
      PresetAvatar(:final preset) => BabyAvatarImage.preset(preset, size: size),
      PhotoAvatar(:final version) => switch (ref.watch(
        babyAvatarPhotoProvider((baby.id, version)),
      )) {
        AsyncData(:final value?) => BabyAvatarImage.photo(value, size: size),
        _ => BabyAvatarImage.preset(1, size: size),
      },
    };
  }
}
