import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        height: 56,
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.text.withValues(alpha: .55),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    cursorColor: AppColors.accent,
                    style: AppTextStyles.body(fontSize: 15),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: hint,
                      hintStyle: AppTextStyles.body(
                        fontSize: 15,
                        color: AppColors.text.withValues(alpha: .5),
                      ),
                    ),
                  ),
                ),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                else if (value.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    padding: const EdgeInsets.all(8),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.text.withValues(alpha: .55),
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
