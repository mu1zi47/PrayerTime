import 'dart:async';

import 'package:flutter/material.dart';

import '../data/next_prayer.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/date_pill.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/prayer_row.dart';

/// Ported from the "Главный" screen in the design.
class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _todayIndex = 0;

  int _selectedIndex = _todayIndex;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keeps the next-prayer countdown fresh without any extra network
    // calls — just recomputes from the already-fetched schedule.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final days = appState.days;

    if (appState.isLoadingDays && days.isEmpty) {
      return const _LoadingView();
    }
    if (appState.daysError != null && days.isEmpty) {
      return _ErrorView(message: appState.daysError!, onRetry: appState.loadPrayerTimes);
    }
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedIndex = _selectedIndex < days.length ? _selectedIndex : _todayIndex;
    final selectedDay = days[selectedIndex];
    final showingToday = selectedIndex == _todayIndex;
    final next = computeNextPrayer(days, appState.cityNow);
    final current = computeCurrentPrayer(days, appState.cityNow);

    // No SafeArea: content scrolls edge-to-edge, up under the transparent
    // status bar. The top inset is baked into the scroll padding instead,
    // so it only reserves space at rest — scrolling still carries content
    // past it, rather than a fixed gap nothing can enter.
    final topInset = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 130),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent2_100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: AppColors.accent2_800),
                const SizedBox(width: 6),
                Text(
                  appState.selectedCity,
                  style: AppTextStyles.body(fontSize: 12, color: AppColors.accent2_800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(selectedDay.fullLabel, style: AppTextStyles.heading(fontSize: 22)),
            ),
            const SizedBox(width: 8),
            _TodayChip(
              isToday: showingToday,
              onTap: () => setState(() => _selectedIndex = _todayIndex),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (next != null) _NextPrayerCard(info: next),
        const SizedBox(height: 16),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = days[i];
              return DatePill(
                weekday: d.weekdayShort,
                dayNumber: d.dayNumber,
                selected: i == selectedIndex,
                isToday: i == _todayIndex,
                onTap: () => setState(() => _selectedIndex = i),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            PrayerRow(
              kind: PrayerKind.fajr,
              time: selectedDay.fajr,
              active: showingToday && next?.kind == PrayerKind.fajr,
              current: showingToday && current == PrayerKind.fajr,
            ),
            const SizedBox(height: 8),
            PrayerRow(kind: PrayerKind.sunrise, time: selectedDay.sunrise),
            const SizedBox(height: 8),
            PrayerRow(
              kind: PrayerKind.zuhr,
              time: selectedDay.zuhr,
              active: showingToday && next?.kind == PrayerKind.zuhr,
              current: showingToday && current == PrayerKind.zuhr,
            ),
            const SizedBox(height: 8),
            PrayerRow(
              kind: PrayerKind.asr,
              time: selectedDay.asr,
              active: showingToday && next?.kind == PrayerKind.asr,
              current: showingToday && current == PrayerKind.asr,
            ),
            const SizedBox(height: 8),
            PrayerRow(
              kind: PrayerKind.maghrib,
              time: selectedDay.maghrib,
              active: showingToday && next?.kind == PrayerKind.maghrib,
              current: showingToday && current == PrayerKind.maghrib,
            ),
            const SizedBox(height: 8),
            PrayerRow(
              kind: PrayerKind.isha,
              time: selectedDay.isha,
              active: showingToday && next?.kind == PrayerKind.isha,
              current: showingToday && current == PrayerKind.isha,
            ),
          ],
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final NextPrayerInfo info;

  const _NextPrayerCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Следующий намаз',
                  style: AppTextStyles.body(
                    fontSize: 11,
                    color: AppColors.bg,
                  ).copyWith(letterSpacing: 1.1, color: AppColors.bg.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 4),
                Text(
                  nameForPrayer(info.kind),
                  style: AppTextStyles.heading(fontSize: 24, color: AppColors.bg),
                ),
                Text(
                  arabicForPrayer(info.kind),
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.body(
                    fontSize: 13,
                    color: AppColors.bg,
                  ).copyWith(color: AppColors.bg.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 4),
                Text(
                  info.countdownLabel,
                  style: AppTextStyles.body(
                    fontSize: 12,
                    color: AppColors.bg,
                  ).copyWith(color: AppColors.bg.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          Text(info.time, style: AppTextStyles.heading(fontSize: 30, color: AppColors.bg)),
        ],
      ),
    );
  }
}

/// Always occupies the same slot next to the date title — when a past/
/// future day is selected it's an active "jump to today" button; when
/// today is already selected it becomes a quiet status pill instead of
/// disappearing, so the title's available width (and everything below)
/// never shifts depending on selection.
class _TodayChip extends StatelessWidget {
  final bool isToday;
  final VoidCallback onTap;

  const _TodayChip({required this.isToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              'Сегодня',
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppColors.accent));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.accent700),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: 14, color: AppColors.text),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Повторить',
                  style: AppTextStyles.body(
                    fontSize: 14,
                    color: AppColors.bg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
