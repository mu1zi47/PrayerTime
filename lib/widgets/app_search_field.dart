import '../theme/app_design_system.dart';
import 'package:flutter/material.dart';

import 'ambient_surface.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool loading;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hint,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: SizedBox(
        height: 56,
        child: GlassPanel(
          padding: EdgeInsets.zero,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Center(
                    child: Icon(
                      Icons.search_rounded,
                      size: AppIconSize.medium,
                      color: AppColors.text.withValues(alpha: .55),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    cursorColor: AppColors.accent,
                    style: AppTextStyles.body(fontSize: AppFontSize.body),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: hint,
                      hintStyle: AppTextStyles.body(
                        fontSize: AppFontSize.body,
                        color: AppColors.text.withValues(alpha: .5),
                      ),
                    ),
                  ),
                ),
                if (loading)
                  SizedBox(
                    width: 52,
                    child: Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  )
                else if (value.text.isNotEmpty)
                  SizedBox(
                    width: 52,
                    child: IconButton(
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      constraints: const BoxConstraints.tightFor(
                        width: 52,
                        height: 56,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.close_rounded,
                        size: AppIconSize.medium,
                        color: AppColors.text.withValues(alpha: .55),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
