import 'app_tap.dart';
import 'ambient_surface.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionKicker extends StatelessWidget {
  final String label;

  const SectionKicker(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: AppTextStyles.body(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.text.withValues(alpha: .55),
        ).copyWith(letterSpacing: .1),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  final String kicker;
  final List<Widget> children;
  final Widget? footer;

  const SettingsGroup({
    super.key,
    required this.kicker,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionKicker(kicker),
        GlassPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              GroupRows(children: children),
              ?footer,
            ],
          ),
        ),
      ],
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
    AppColors.watch(context);
    return AppTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
    AppColors.watch(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: child),
          trailing,
        ],
      ),
    );
  }
}

/// Separators belong to the group, so its final row never draws a line.
class GroupRows extends StatelessWidget {
  final List<Widget> children;
  const GroupRows({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const PanelDivider(),
        children[i],
      ],
    ],
  );
}

class SettingsValue extends StatelessWidget {
  final String label;
  final String value;
  const SettingsValue({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: AppTextStyles.body(fontSize: 15)),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppTextStyles.body(
            fontSize: 14,
            color: AppColors.text.withValues(alpha: .55),
          ),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

/// One clipped surface for a sheet's actions, with inset separators.
class ActionGroup extends StatelessWidget {
  final List<Widget> children;
  const ActionGroup({super.key, required this.children});
  @override
  Widget build(BuildContext context) =>
      GlassPanel(child: GroupRows(children: children));
}
