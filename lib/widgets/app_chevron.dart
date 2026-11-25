import '../theme/app_design_system.dart';
import 'package:flutter/material.dart';

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
      size: AppIconSize.medium,
      color: AppColors.accent.withValues(alpha: enabled ? 1 : .25),
    );
  }
}
