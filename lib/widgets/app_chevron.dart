import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One treatment for row actions and previous/next navigation.
class AppChevron extends StatelessWidget {
  final IconData icon;
  final bool enabled;

  const AppChevron({
    super.key,
    this.icon = Icons.chevron_right_rounded,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Icon(
      icon,
      size: 20,
      color: AppColors.accent.withValues(alpha: enabled ? 1 : .25),
    );
  }
}
