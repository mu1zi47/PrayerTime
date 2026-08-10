import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionKicker extends StatelessWidget {
  final String label;

  const SectionKicker(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.body(fontSize: 10, color: AppColors.accent700).copyWith(
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final String kicker;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.kicker, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionKicker(kicker),
        ...children,
      ],
    );
  }
}

class OptRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? background;

  const OptRow({super.key, required this.child, this.onTap, this.background});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: background ?? AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(child: child),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.text),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final Widget child;
  final Widget trailing;

  const SettingsRow({super.key, required this.child, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            trailing,
          ],
        ),
      ),
    );
  }
}
