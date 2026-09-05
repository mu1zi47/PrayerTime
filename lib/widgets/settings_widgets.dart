import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionKicker extends StatelessWidget {
  final String label;

  const SectionKicker(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.body(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ).copyWith(letterSpacing: 1.0),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final String kicker;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.kicker,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SectionKicker(kicker), ...children],
    );
  }
}

/// A flat, divider-separated line — the same "plain rows, one hairline
/// each" table look as HomeScreen's own schedule, rather than a stack of
/// individually rounded, filled buttons.
class OptRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const OptRow({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.text.withValues(alpha: 0.35),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: child),
          trailing,
        ],
      ),
    );
  }
}
