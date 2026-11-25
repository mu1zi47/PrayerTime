import '../theme/app_design_system.dart';
import '../widgets/app_tap.dart';
import '../widgets/app_chevron.dart';
import '../widgets/ambient_surface.dart';
import 'package:flutter/material.dart';

import '../data/date_labels.dart';
import '../data/day_completion.dart';
import '../data/next_prayer.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_log_status.dart';
import '../state/app_state.dart';
import '../widgets/icon_badge.dart';
import '../widgets/prayer_mark_indicator.dart';
import '../widgets/prayer_row_layout.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/screen_back_button.dart';

class PrayerCalendarScreen extends StatefulWidget {
  final AppState appState;

  const PrayerCalendarScreen({super.key, required this.appState});

  @override
  State<PrayerCalendarScreen> createState() => _PrayerCalendarScreenState();
}

class _PrayerCalendarScreenState extends State<PrayerCalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = widget.appState.cityNow;
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
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

  static const _allPrayers = [
    ('fajr', PrayerKind.fajr),
    ('zuhr', PrayerKind.zuhr),
    ('asr', PrayerKind.asr),
    ('maghrib', PrayerKind.maghrib),
    ('isha', PrayerKind.isha),
  ];

  /// Which prayers of [date] can be marked at all: a prayer that hasn't
  /// happened yet can't have been prayed. A future day yields nothing (the
  /// panel disappears entirely), today yields the ones whose time has
  /// arrived — including the one running right now — and any past day
  /// yields all five.
  List<(String, PrayerKind)> _markablePrayers(DateTime date) {
    final now = widget.appState.cityNow;
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target.isAfter(today)) return const [];
    if (target.isBefore(today)) return _allPrayers;

    final day = widget.appState.todayPrayerDay;
    if (day == null) return const [];
    return _allPrayers
        .where((p) => hasPrayerTimePassed(day, p.$2, now))
        .toList();
  }

  void _editPrayer(DateTime date, String prayerKey, PrayerKind kind) {
    widget.appState.setPrayerStatus(date, prayerKey, PrayerLogStatus.onTime);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final padding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final markable = _markablePrayers(_selectedDay);
        return AmbientScaffold(
          backgroundColor: AppColors.bg,
          body: ScreenContentInset(
            margin: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              padding.top + AppSpacing.md,
              AppSpacing.screen,
              padding.bottom + AppSpacing.screen,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Row(
                  children: [
                    ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        t.calendarScreenTitle,
                        style: AppTextStyles.heading(
                          fontSize: AppFontSize.heading,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MonthNavButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => _shiftMonth(-1),
                    ),
                    Text(
                      DateLabels.monthYearLabel(t, _visibleMonth),
                      style: AppTextStyles.heading(
                        fontSize: AppFontSize.bodyLarge,
                      ),
                    ),
                    _MonthNavButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _isCurrentMonth ? null : () => _shiftMonth(1),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GlassPanel(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _CalendarGrid(
                    appState: widget.appState,
                    month: _visibleMonth,
                    selected: _selectedDay,
                    onSelect: (date) => setState(() => _selectedDay = date),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (markable.isNotEmpty) ...[
                  _DayLogPanel(
                    appState: widget.appState,
                    date: _selectedDay,
                    prayers: markable,
                    onEdit: _editPrayer,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegendItem(
                      color: StatusColors.onTime,
                      label: t.widgetMarkedLabel,
                    ),
                    _LegendItem(
                      color: AppColors.transparent,
                      label: t.calendarNotMarked,
                    ),
                  ],
                ),
              ],
            ),
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
    AppColors.watch(context);
    final enabled = onTap != null;
    return AppTap(
      feedbackOnChild: false,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.text.withValues(alpha: AppOpacity.border),
          ),
        ),
        child: AppPressContent(
          child: AppChevron(icon: icon, enabled: enabled),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final AppState appState;
  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _CalendarGrid({
    required this.appState,
    required this.month,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
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
                      fontSize: AppFontSize.caption,
                      color: AppColors.text,
                    ).copyWith(color: AppColors.text.withValues(alpha: 0.5)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
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
              isSelected:
                  date.year == selected.year &&
                  date.month == selected.month &&
                  date.day == selected.day,
              completion: classifyDay(
                appState.prayerLogFor(date),
                isLocked: appState.isDayLocked(date),
              ),
              onTap: () => onSelect(date),
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
  final bool isSelected;
  final DayCompletion completion;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.completion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final (bg, fg) = switch (completion) {
      DayCompletion.onTime => (StatusColors.onTime, StatusColors.onOnTime),
      DayCompletion.missed || DayCompletion.upcoming => (
        AppColors.transparent,
        AppColors.text.withValues(alpha: AppOpacity.secondary),
      ),
    };

    // The selection ring wins over today's, since today starts out selected
    // anyway and the ring is what tells you which day the panel below is
    // about.
    final border = isSelected
        ? Border.all(color: AppColors.text, width: 2)
        : isToday && completion == DayCompletion.upcoming
        ? Border.all(color: AppColors.accent, width: 1.6)
        : null;

    return AppTap(
      feedbackOnChild: false,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: AppSize.badge,
          height: AppSize.badge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border,
          ),
          child: AppPressContent(
            child: Text(
              '$day',
              style: AppTextStyles.body(
                fontSize: AppFontSize.small,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The day the calendar has selected, laid out prayer by prayer so a missed
/// one can be filled in after the fact — the home screen only ever reaches
/// back as far as yesterday.
class _DayLogPanel extends StatelessWidget {
  final AppState appState;
  final DateTime date;

  /// Only the prayers that have actually happened — see
  /// _PrayerCalendarScreenState._markablePrayers.
  final List<(String, PrayerKind)> prayers;

  final void Function(DateTime date, String prayerKey, PrayerKind kind) onEdit;

  const _DayLogPanel({
    required this.appState,
    required this.date,
    required this.prayers,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.zero,
      decoration: glassDecoration(radius: AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.none,
            ),
            child: Text(
              DateLabels.fullLabel(t, date),
              style: AppTextStyles.heading(fontSize: AppFontSize.bodyLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              t.calendarDayPanelKicker,
              style: AppTextStyles.body(
                fontSize: AppFontSize.small,
                color: AppColors.text,
              ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (key, kind) in prayers)
            _PrayerLogRow(
              showDivider: (key, kind) != prayers.last,
              label: nameForPrayer(t, kind),
              icon: iconForPrayer(kind),
              status: appState.prayerStatusFor(date, key),
              onTap: () => onEdit(date, key, kind),
            ),
        ],
      ),
    );
  }
}

class _PrayerLogRow extends StatelessWidget {
  final bool showDivider;
  final String label;
  final IconData icon;
  final PrayerLogStatus? status;
  final VoidCallback? onTap;

  const _PrayerLogRow({
    this.showDivider = true,
    required this.label,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return PanelRow(
      padding: EdgeInsets.zero,
      showDivider: showDivider,
      child: PrayerRowLayout(
        leading: IconBadge(
          icon,
          size: AppSize.badge,
          iconSize: AppIconSize.small,
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.prayerName(),
        ),
        mark: PrayerMarkIndicator(status: status, onTap: onTap),
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
    AppColors.watch(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.text.withValues(alpha: AppOpacity.secondary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.compact),
        Text(
          label,
          style: AppTextStyles.body(
            fontSize: AppFontSize.small,
            color: AppColors.text,
          ).copyWith(color: AppColors.text.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
