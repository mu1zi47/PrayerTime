import '../theme/app_design_system.dart';
import 'app_tap.dart';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'ambient_surface.dart';

class ScreenBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const ScreenBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AppTap(
      feedbackOnChild: false,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: AppSize.largeBadge,
              height: AppSize.largeBadge,
              alignment: Alignment.center,
              decoration: glassDecoration(radius: AppRadius.pill),
              child: AppPressContent(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: AppIconSize.medium,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
