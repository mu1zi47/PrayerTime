import 'dart:async';

import 'package:flutter/material.dart';

import '../data/date_labels.dart';
import '../data/next_prayer.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_log_status.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/date_pill.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/screen_back_button.dart';

const _loggedPrayers = [
  ('fajr', PrayerKind.fajr),
  ('zuhr', PrayerKind.zuhr),
  ('asr', PrayerKind.asr),
  ('maghrib', PrayerKind.maghrib),
  ('isha', PrayerKind.isha),
];

class PrayerLogScreen extends StatefulWidget {
  final AppState appState;

  const PrayerLogScreen({super.key, required this.appState});

  @override
  State<PrayerLogScreen> createState() => _PrayerLogScreenState();
}

class _PrayerLogScreenState extends State<PrayerLogScreen> {
  static const _daysBack = 7;

  late final DateTime _today;
  late int _selectedOffset;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final now = widget.appState.cityNow;
    _today = DateTime(now.year, now.month, now.day);
    _selectedOffset = 0;
    // Unlocks a prayer's buttons the moment its time arrives, for anyone
    // who has this screen open and waiting rather than reopening it —
    // same idea as HomeScreen's own countdown ticker.
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _shiftDay(int delta) {
    setState(
      () => _selectedOffset = (_selectedOffset + delta).clamp(0, _daysBack - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final selectedDate = _today.subtract(Duration(days: _selectedOffset));
    final showingToday = _selectedOffset == 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // Swipe right = back towards today, swipe left = further back in
        // time.
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -200) {
            _shiftDay(-1);
          } else if (velocity > 200) {
            _shiftDay(1);
          }
        },
        child: AnimatedBuilder(
          animation: widget.appState,
          builder: (context, _) {
            final t = AppLocalizations.of(context)!;
            final dayLog = widget.appState.prayerLogFor(selectedDate);
            final qadaCount = dayLog.values
                .where((s) => s == PrayerLogStatus.qada)
                .length;

            // Only today can have prayers still ahead of "now" — every
            // earlier day is entirely in the past already. Falls back to
            // "nothing's blocked" if the schedule hasn't loaded yet, rather
            // than freezing the whole screen on a data hiccup.
            final todayPrayerDay =
                showingToday && widget.appState.days.isNotEmpty
                ? widget.appState.days.first
                : null;

            return ListView(
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
                      t.myPrayersTitle,
                      style: AppTextStyles.heading(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    t.myPrayersSubtitle,
                    style: AppTextStyles.body(
                      fontSize: 13,
                      color: AppColors.text,
                    ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    reverse: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: _daysBack,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final d = _today.subtract(Duration(days: i));
                      return DatePill(
                        weekday: DateLabels.shortWeekday(t, d),
                        dayNumber: '${d.day}',
                        selected: i == _selectedOffset,
                        isToday: i == 0,
                        onTap: () => setState(() => _selectedOffset = i),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        DateLabels.fullLabel(t, selectedDate),
                        style: AppTextStyles.heading(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TodayChip(
                      isToday: showingToday,
                      onTap: () => setState(() => _selectedOffset = 0),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    t.prayerLogDone(dayLog.length, _loggedPrayers.length) +
                        (qadaCount > 0 ? t.prayerLogLateSuffix(qadaCount) : ''),
                    style: AppTextStyles.body(
                      fontSize: 13,
                      color: AppColors.text,
                    ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    for (final (key, kind) in _loggedPrayers) ...[
                      _LogRow(
                        kind: kind,
                        status: dayLog[key],
                        notYetDue:
                            todayPrayerDay != null &&
                            !hasPrayerTimePassed(
                              todayPrayerDay,
                              kind,
                              widget.appState.cityNow,
                            ),
                        onSetStatus: (status) => widget.appState
                            .setPrayerStatus(selectedDate, key, status),
                      ),
                      if (kind != _loggedPrayers.last.$2)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  final bool isToday;
  final VoidCallback onTap;

  const _TodayChip({required this.isToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: isToday ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isToday ? AppColors.accent2_100 : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isToday) ...[
              Icon(Icons.check_rounded, size: 13, color: AppColors.accent2_800),
              const SizedBox(width: 4),
            ],
            Text(
              t.todayLabel,
              style: AppTextStyles.body(
                fontSize: 12,
                color: isToday ? AppColors.accent2_800 : AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final PrayerKind kind;
  final PrayerLogStatus? status;
  final bool notYetDue;
  final ValueChanged<PrayerLogStatus> onSetStatus;

  const _LogRow({
    required this.kind,
    required this.status,
    required this.notYetDue,
    required this.onSetStatus,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final (bg, border) = switch (status) {
      PrayerLogStatus.onTime => (AppColors.accent2_100, AppColors.accent2),
      PrayerLogStatus.qada => (AppColors.accent100, AppColors.accent),
      null => (AppColors.surface, Colors.transparent),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconForPrayer(kind),
              size: 19,
              color: AppColors.accent700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nameForPrayer(t, kind),
                  style: AppTextStyles.heading(fontSize: 15),
                ),
                const SizedBox(height: 1),
                Text(
                  arabicForPrayer(kind),
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.body(
                    fontSize: 11,
                    color: AppColors.text,
                  ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (notYetDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                t.notYetDue,
                style: AppTextStyles.body(
                  fontSize: 11,
                  color: AppColors.text,
                ).copyWith(color: AppColors.text.withValues(alpha: 0.45)),
              ),
            )
          else ...[
            _StatusButton(
              icon: Icons.check_rounded,
              tooltip: t.statusOnTime,
              active: status == PrayerLogStatus.onTime,
              color: AppColors.accent2,
              onTap: () => onSetStatus(PrayerLogStatus.onTime),
            ),
            const SizedBox(width: 6),
            _StatusButton(
              icon: Icons.watch_later_rounded,
              tooltip: t.statusLate,
              active: status == PrayerLogStatus.qada,
              color: AppColors.accent,
              onTap: () => onSetStatus(PrayerLogStatus.qada),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : AppColors.bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? color : AppColors.divider,
              width: 1.4,
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: active
                ? AppColors.bg
                : AppColors.text.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
