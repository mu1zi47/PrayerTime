import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'icon_badge.dart';

class ChoiceSheetOption {
  final String label;
  final IconData? icon;

  const ChoiceSheetOption({required this.label, this.icon});
}

/// A bottom sheet for picking one of a short list of options — the same
/// "tap a row, something opens" gesture as OptRow's full-screen pushes (see
/// CityScreen), just weighted for a short choice that doesn't need a whole
/// screen of its own (theme, madhab, calculation method, ...) rather than
/// an inline segmented toggle or a dedicated picker screen.
Future<void> showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<ChoiceSheetOption> options,
  required int selectedIndex,
  required ValueChanged<int> onSelect,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ChoiceSheet(
      title: title,
      options: options,
      selectedIndex: selectedIndex,
      onSelect: (i) {
        Navigator.of(sheetContext).pop();
        onSelect(i);
      },
    ),
  );
}

class _ChoiceSheet extends StatelessWidget {
  final String title;
  final List<ChoiceSheetOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(fontSize: 18),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ChoiceOption(
              option: options[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  final ChoiceSheetOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  /// In the app's icon colors (see [IconBadge]): the chosen option filled
  /// soft gold with deep gold text, the rest plain surface — and each
  /// option's icon, if any, in a badge (inverted on the chosen one, which
  /// is already soft gold).
  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.accent700 : AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: option.icon != null ? 10 : 15,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent100 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            if (option.icon != null) ...[
              IconBadge(
                option.icon!,
                size: 32,
                iconSize: 16,
                background: selected ? AppColors.accent700 : null,
                foreground: selected ? AppColors.accent100 : null,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                option.label,
                style: AppTextStyles.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 19, color: AppColors.accent700),
          ],
        ),
      ),
    );
  }
}
