import '../theme/app_design_system.dart';
import 'app_modal_sheet.dart';
import 'app_tap.dart';
import 'settings_widgets.dart';
import 'package:flutter/material.dart';

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
  return showAppModalBottomSheet(
    context: context,
    backgroundColor: AppColors.transparent,
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
    AppColors.watch(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        bottomInset + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSize.sheetHandleWidth,
              height: AppSize.sheetHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(fontSize: AppFontSize.title),
          ),
          const SizedBox(height: AppSpacing.screen),
          ActionGroup(
            children: [
              for (var i = 0; i < options.length; i++)
                _ChoiceOption(
                  option: options[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
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
    AppColors.watch(context);
    final fg = selected ? AppColors.accent700 : AppColors.text;
    return AppTap(
      feedbackOnChild: false,
      onTap: onTap,

      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: option.icon != null ? AppSpacing.sm : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.selectionGradient : null,
          borderRadius: BorderRadius.zero,
        ),
        child: AppPressContent(
          child: Row(
            children: [
              if (option.icon != null) ...[
                IconBadge(
                  option.icon!,
                  size: AppIconSize.display,
                  iconSize: AppIconSize.small,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: AppTextStyles.body(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: AppIconSize.medium,
                  color: AppColors.accent700,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
