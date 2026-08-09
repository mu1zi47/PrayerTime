import 'package:flutter/material.dart';

import '../models/notif_mode.dart';
import '../theme/app_colors.dart';

/// Компактный переключатель на 3 иконки — азан / уведомление / без звука.
/// Тот же язык дизайна, что у [SegmentedControl]: скользящая капсула
/// в акцентном цвете вокруг выбранной иконки.
class NotifModeSelector extends StatelessWidget {
  final NotifMode value;
  final ValueChanged<NotifMode> onChanged;

  const NotifModeSelector({super.key, required this.value, required this.onChanged});

  static const _modes = NotifMode.values;
  static const _segmentSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _modes.indexOf(value);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: selectedIndex * _segmentSize,
            width: _segmentSize,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in _modes)
                GestureDetector(
                  onTap: () => onChanged(mode),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _segmentSize,
                    height: _segmentSize,
                    child: Icon(
                      mode.icon,
                      size: 16,
                      color: mode == value ? AppColors.bg : AppColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
