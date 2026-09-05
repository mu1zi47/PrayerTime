import 'package:flutter/material.dart';

import '../data/date_labels.dart';
import '../data/day_completion.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

class PrayerCalendarScreen extends StatefulWidget {
  final AppState appState;

  const PrayerCalendarScreen({super.key, required this.appState});

  @override
  State<PrayerCalendarScreen> createState() => _PrayerCalendarScreenState();
}

class _PrayerCalendarScreenState extends State<PrayerCalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.appState.cityNow;
    _visibleMonth = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = widget.appState.cityNow;
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  void _shiftMonth(int delta) {
    setState(
      () => _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              padding.top + 16,
              18,
              padding.bottom + 18,
            ),
            children: [
              Row(
                children: [
                  ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text(
                    t.calendarScreenTitle,
                    style: AppTextStyles.heading(fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MonthNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _shiftMonth(-1),
                  ),
                  Text(
                    DateLabels.monthYearLabel(t, _visibleMonth),
                    style: AppTextStyles.heading(fontSize: 16),
                  ),
                  _MonthNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _isCurrentMonth ? null : () => _shiftMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CalendarGrid(appState: widget.appState, month: _visibleMonth),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendItem(color: AppColors.accent2, label: t.legendOnTime),
                  _LegendItem(color: AppColors.accent, label: t.legendQada),
                  _LegendItem(
                    color: AppColors.neutral300,
                    label: t.legendMissed,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.text
              : AppColors.text.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final AppState appState;
  final DateTime month;

  const _CalendarGrid({required this.appState, required this.month});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final firstOfMonth = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Dart's weekday is 1=Mon..7=Sun — how many blank leading cells this
    // Monday-first grid needs before the 1st.
    final leadingBlanks = firstOfMonth.weekday - 1;

    final now = appState.cityNow;
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        Row(
          children: [
            for (final w in [
              t.weekdayShortMon,
              t.weekdayShortTue,
              t.weekdayShortWed,
              t.weekdayShortThu,
              t.weekdayShortFri,
              t.weekdayShortSat,
              t.weekdayShortSun,
            ])
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: AppTextStyles.body(
                      fontSize: 11,
                      color: AppColors.text,
                    ).copyWith(color: AppColors.text.withValues(alpha: 0.5)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingBlanks + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, i) {
            if (i < leadingBlanks) return const SizedBox.shrink();
            final date = DateTime(
              month.year,
              month.month,
              i - leadingBlanks + 1,
            );
            return _DayCell(
              day: date.day,
              isToday:
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day,
              completion: classifyDay(
                appState.prayerLogFor(date),
                isLocked: appState.isDayLocked(date),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final DayCompletion completion;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.completion,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (completion) {
      DayCompletion.onTime => (AppColors.accent2, AppColors.bg),
      DayCompletion.qada => (AppColors.accent, AppColors.bg),
      DayCompletion.missed => (
        AppColors.neutral300,
        AppColors.text.withValues(alpha: 0.4),
      ),
      DayCompletion.upcoming => (
        Colors.transparent,
        AppColors.text.withValues(alpha: 0.75),
      ),
    };

    return Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isToday && completion == DayCompletion.upcoming
              ? Border.all(color: AppColors.accent, width: 1.6)
              : null,
        ),
        child: Text(
          '$day',
          style: AppTextStyles.body(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.body(
            fontSize: 12,
            color: AppColors.text,
          ).copyWith(color: AppColors.text.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
