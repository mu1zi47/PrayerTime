import 'app_tap.dart';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: glassDecoration(radius: 999),
              child: AppPressContent(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
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
