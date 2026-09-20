import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's icon style: a glyph in a round gold badge — soft gold behind,
/// deep gold on top, in either theme. Settings rows, the "More" tiles, the
/// prayer lists and the pickers all use it, so every icon in the app reads
/// as one family.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  /// Overrides for a badge sitting on a surface that is itself soft gold
  /// (a highlighted row), where the default would vanish into it.
  final Color? background;
  final Color? foreground;

  const IconBadge(
    this.icon, {
    super.key,
    this.size = 34,
    this.iconSize = 17,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppColors.accent100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: foreground ?? AppColors.accent700,
      ),
    );
  }
}
