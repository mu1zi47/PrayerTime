import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _TabSpec {
  final IconData icon;
  final String label;

  const _TabSpec(this.icon, this.label);
}

List<_TabSpec> _tabs(AppLocalizations t) => [
      _TabSpec(Icons.home_rounded, t.navPrayer),
      _TabSpec(Icons.grid_view_rounded, t.navMore),
      _TabSpec(Icons.tune_rounded, t.navSettings),
    ];

/// A floating, pill-shaped nav bar in the style of Samsung One UI 8.5/9 —
/// detached from the screen edge, glassy/blurred, with a filled capsule
/// that morphs to the selected tab instead of a fixed underline/bar.
class FloatingTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const FloatingTabBar({super.key, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs(AppLocalizations.of(context)!);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neutral900.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      _FloatingTabButton(
                        spec: tabs[i],
                        selected: i == index,
                        onTap: () => onSelect(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTabButton extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _FloatingTabButton({required this.spec, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: selected ? 20 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              spec.icon,
              size: 20,
              color: selected ? AppColors.bg : AppColors.text.withValues(alpha: 0.55),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        spec.label,
                        style: AppTextStyles.body(
                          fontSize: 13,
                          color: AppColors.bg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : const SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}
