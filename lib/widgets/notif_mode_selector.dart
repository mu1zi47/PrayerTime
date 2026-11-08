import 'app_tap.dart';
import 'package:flutter/material.dart';

import '../models/notif_mode.dart';
import '../theme/app_colors.dart';

class NotifModeSelector extends StatelessWidget {
  final NotifMode value;
  final ValueChanged<NotifMode> onChanged;

  /// False while the phone isn't letting notifications through at all (see
  /// AppState.notificationsAllowed): any mode but "off" would be a promise
  /// nothing keeps, so the selector sits on "off", dimmed, and a tap goes to
  /// [onBlockedTap] instead of changing anything. [value] is left alone.
  final bool enabled;
  final VoidCallback? onBlockedTap;

  const NotifModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.onBlockedTap,
  });

  static const _modes = NotifMode.values;
  static const _segmentSize = 34.0;

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final shown = enabled ? value : NotifMode.off;
    final selectedIndex = _modes.indexOf(shown);
    // Semantic colors interpolate across the reversed light/dark ramps.
    final soft = AppColors.onControlFill;
    final selector = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.text.withValues(alpha: .08)),
        color: AppColors.text.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(AppRadius.md),
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
                border: Border.all(
                  color: AppColors.text.withValues(alpha: .08),
                ),
                gradient: AppColors.selectionGradient,
                borderRadius: BorderRadius.circular(AppRadius.inner),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in _modes)
                AppTap(
                  onTap: enabled ? () => onChanged(mode) : onBlockedTap,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _segmentSize,
                    height: _segmentSize,
                    child: Icon(
                      mode.icon,
                      size: 16,
                      color: mode == shown
                          ? soft
                          : AppColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: selector,
    );
  }
}
