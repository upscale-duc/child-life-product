import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Line icons exported from Figma (Components 7:6, 24px, 1.8 stroke, `currentColor`).
/// Figma notes production iOS uses SF Symbols; both platforms use these drawings so Android
/// mimics iOS (D-004, P-063).
enum ClIcons {
  alert,
  arrowRight('arrow-right'),
  back,
  backspace,

  /// Reminder notifications (S7, engineering icon in the Figma line style).
  bell,
  bookmark,

  /// Saved (Sơ cứu 7b, engineering icon: the bookmark filled).
  bookmarkFill('bookmark-fill'),
  brandMark('brand-mark'),
  cake,
  camera,

  /// NavBar v1.0.1 Chăm sóc tab (engineering icon in the Figma line style).
  care,
  check,
  chevronDown('chevron-down'),
  chevronRight('chevron-right'),
  clock,
  close,
  cloudOff('cloud-off'),
  diaper,

  /// Memories "Tải về" (S9, engineering icon in the Figma line style).
  download,
  drop,
  edit,
  eye,
  family,
  feed,
  globe,
  grid,
  heart,
  journal,

  /// Tôi → Ngôn ngữ (G-081, engineering icon in the Figma line style).
  language,
  link,
  lock,
  mail,
  memories,
  plus,
  retry,
  ruler,
  search,
  sleep,
  sliders,
  spark,
  star,
  sunrise,
  sunset,
  today,

  /// Sơ cứu "Gọi 115" (Figma Icon/phone, v1.1; drawn in the line style).
  phone,

  /// Sơ cứu "Đọc to hướng dẫn" (Figma Icon/speaker, v1.1 revision 2) and stopping it.
  speaker,
  stop,

  /// Memories delete (S9, engineering icon in the Figma line style).
  trash,
  upload;

  const ClIcons([this._file]);
  final String? _file;

  String get asset => 'assets/icons/${_file ?? name}.svg';
}

class ClIcon extends StatelessWidget {
  const ClIcon(
    this.icon, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final ClIcons icon;
  final double size;
  final Color? color;

  /// Null = decorative (excluded from accessibility).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF173D44);
    final picture = SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: picture)
        : Semantics(label: semanticLabel, child: picture);
  }
}
