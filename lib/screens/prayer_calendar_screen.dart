import 'package:flutter/material.dart';

import '../data/date_labels.dart';
import '../data/day_completion.dart';
import '../data/next_prayer.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_log_status.dart';
import '../state/app_state.dart';
import '../theme/status_colors.dart';
import '../widgets/icon_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/log_prayer_sheet.dart';
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

  /// Opens the same sheet the home screen's prayer rows use, so a day
  /// filled in here and a day marked as it happened go through one path.
  void _editPrayer(DateTime date, String prayerKey, PrayerKind kind) {
    final t = AppLocalizations.of(context)!;
    showLogPrayerSheet(
      context,
      prayerName: nameForPrayer(t, kind),
      current: widget.appState.prayerStatusFor(date, prayerKey),
      onPick: (status) =>
          widget.appState.setPrayerStatus(date, prayerKey, status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final markable = _markablePrayers(_selectedDay);
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
              _CalendarGrid(
                appState: widget.appState,
                month: _visibleMonth,
                selected: _selectedDay,
                onSelect: (date) => setState(() => _selectedDay = date),
              ),
              const SizedBox(height: 20),
              if (markable.isNotEmpty) ...[
                _DayLogPanel(
                  appState: widget.appState,
                  date: _selectedDay,
                  prayers: markable,
                  onEdit: _editPrayer,
                ),
                const SizedBox(height: 20),
              ],
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendItem(
                    color: StatusColors.onTime,
                    label: t.legendOnTime,
                  ),
                  _LegendItem(color: StatusColors.qada, label: t.legendQada),
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
    final (bg, fg) = switch (completion) {
      DayCompletion.onTime => (StatusColors.onTime, StatusColors.onOnTime),
      DayCompletion.qada => (StatusColors.qada, StatusColors.onQada),
      DayCompletion.missed => (
        AppColors.neutral300,
        AppColors.text.withValues(alpha: 0.4),
      ),
      DayCompletion.upcoming => (
        Colors.transparent,
        AppColors.text.withValues(alpha: 0.75),
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border,
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
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateLabels.fullLabel(t, date),
            style: AppTextStyles.heading(fontSize: 17),
          ),
          const SizedBox(height: 2),
          Text(
            t.calendarDayPanelKicker,
            style: AppTextStyles.body(
              fontSize: 12.5,
              color: AppColors.text,
            ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 10),
          for (final (key, kind) in prayers)
            _PrayerLogRow(
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
  final String label;
  final IconData icon;
  final PrayerLogStatus? status;
  final VoidCallback? onTap;

  const _PrayerLogRow({
    required this.label,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final (statusLabel, statusColor) = switch (status) {
      PrayerLogStatus.onTime => (t.legendOnTime, StatusColors.onTime),
      PrayerLogStatus.qada => (t.legendQada, StatusColors.qada),
      null => (t.calendarNotMarked, AppColors.text.withValues(alpha: 0.4)),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            IconBadge(icon, size: 32, iconSize: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              statusLabel,
              style: AppTextStyles.body(fontSize: 13, color: statusColor),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: AppColors.text.withValues(alpha: 0.35),
              ),
            ],
          ],
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
