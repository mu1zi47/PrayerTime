import '../theme/app_design_system.dart';
import '../widgets/app_tap.dart';
import '../widgets/ambient_surface.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/next_prayer.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../models/prayer_log_status.dart';
import '../state/app_state.dart';
import '../widgets/prayer_mark_indicator.dart';
import '../widgets/prayer_row_layout.dart';
import '../widgets/icon_badge.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/nearby_mosque_card.dart';
import '../widgets/pill_button.dart';
import 'city_screen.dart';
import 'monthly_times_screen.dart';
import 'prayer_calendar_screen.dart';
import 'names_screen.dart';
import 'settings_screen.dart';
import 'tasbih_screen.dart';

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color get _textMuted => AppColors.text.withValues(alpha: AppOpacity.secondary);
Color get _textFaint => AppColors.text.withValues(alpha: AppOpacity.disabled);

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _startTicker();
    // Nothing on screen can go stale while the app is hidden, so the
    // per-second rebuild is suspended until it comes back — and comes back
    // with an immediate refresh, since the countdown will have moved on by
    // more than a second.
    _lifecycle = AppLifecycleListener(
      onHide: _stopTicker,
      onShow: () {
        if (mounted) setState(() {});
        _startTicker();
      },
    );
    widget.appState.addListener(_onAppStateChanged);
  }

  // Keeps the next-prayer countdown fresh without any extra network calls —
  // just recomputes from the already-fetched schedule.
  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onAppStateChanged() => setState(() {});

  @override
  void dispose() {
    _lifecycle?.dispose();
    _stopTicker();
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final appState = widget.appState;
    final days = appState.days;

    final todayIndex = appState.todayIndex;
    final selectedDay = days.isEmpty ? null : days[todayIndex];
    final next = computeNextPrayer(
      days,
      appState.cityNow,
      includeTahajjud: appState.tahajjudEnabled,
      todayIndex: todayIndex,
    );
    final current = computeCurrentPrayer(
      days,
      appState.cityNow,
      includeTahajjud: appState.tahajjudEnabled,
      todayIndex: todayIndex,
    );
    final todayDate = selectedDay?.date ?? appState.cityNow;
    // Which prayer (if any) is highlighted on today's own rows. Across
    // midnight, `current`/`next` can belong to yesterday or tomorrow's own
    // record (see computeCurrentPrayer/computeNextPrayer's cross-midnight
    // handling), so these match on the actual date those carry. Before
    // today's first prayer, yesterday's Isha doesn't highlight today's row.
    final currentKindOnSelectedDay =
        current != null &&
            selectedDay != null &&
            _isSameDate(current.date, selectedDay.date)
        ? current.kind
        : null;
    final nextKindOnSelectedDay =
        next != null &&
            selectedDay != null &&
            _isSameDate(next.date, selectedDay.date)
        ? next.kind
        : null;
    final nextIsTomorrow = next != null && !_isSameDate(next.date, todayDate);

    VoidCallback? logTap(PrayerKind kind, String key) => selectedDay == null
        ? null
        : _logTapFor(context, appState, selectedDay, kind, key);

    final rows = selectedDay == null
        ? <_RowSpec>[]
        : <_RowSpec>[
            if (appState.tahajjudEnabled)
              _RowSpec(
                kind: PrayerKind.tahajjud,
                time: selectedDay.tahajjud,
                active: nextKindOnSelectedDay == PrayerKind.tahajjud,
                current: currentKindOnSelectedDay == PrayerKind.tahajjud,
              ),
            _RowSpec(
              kind: PrayerKind.fajr,
              time: selectedDay.fajr,
              active: nextKindOnSelectedDay == PrayerKind.fajr,
              current: currentKindOnSelectedDay == PrayerKind.fajr,
              logStatus: appState.prayerStatusFor(selectedDay.date, 'fajr'),
              onTapLog: logTap(PrayerKind.fajr, 'fajr'),
            ),
            _RowSpec(
              kind: PrayerKind.sunrise,
              time: selectedDay.sunrise,
              current: currentKindOnSelectedDay == PrayerKind.sunrise,
            ),
            _RowSpec(
              kind: PrayerKind.zuhr,
              time: selectedDay.zuhr,
              active: nextKindOnSelectedDay == PrayerKind.zuhr,
              current: currentKindOnSelectedDay == PrayerKind.zuhr,
              logStatus: appState.prayerStatusFor(selectedDay.date, 'zuhr'),
              onTapLog: logTap(PrayerKind.zuhr, 'zuhr'),
            ),
            _RowSpec(
              kind: PrayerKind.asr,
              time: selectedDay.asr,
              active: nextKindOnSelectedDay == PrayerKind.asr,
              current: currentKindOnSelectedDay == PrayerKind.asr,
              logStatus: appState.prayerStatusFor(selectedDay.date, 'asr'),
              onTapLog: logTap(PrayerKind.asr, 'asr'),
            ),
            _RowSpec(
              kind: PrayerKind.maghrib,
              time: selectedDay.maghrib,
              active: nextKindOnSelectedDay == PrayerKind.maghrib,
              current: currentKindOnSelectedDay == PrayerKind.maghrib,
              logStatus: appState.prayerStatusFor(selectedDay.date, 'maghrib'),
              onTapLog: logTap(PrayerKind.maghrib, 'maghrib'),
            ),
            _RowSpec(
              kind: PrayerKind.isha,
              time: selectedDay.isha,
              active: nextKindOnSelectedDay == PrayerKind.isha,
              current: currentKindOnSelectedDay == PrayerKind.isha,
              logStatus: appState.prayerStatusFor(selectedDay.date, 'isha'),
              onTapLog: logTap(PrayerKind.isha, 'isha'),
            ),
          ];

    return ScreenContentInset(
      child: ListView(
        key: const ValueKey('home-scroll'),
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + AppSpacing.md,
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
          left: MediaQuery.paddingOf(context).left,
          right: MediaQuery.paddingOf(context).right,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                Expanded(
                  child: AppTap(
                    feedbackOnChild: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CityScreen(appState: appState),
                      ),
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: AppPressContent(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              appState.cityLabel(t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(
                                fontSize: AppFontSize.small,
                                fontWeight: AppFontWeight.medium,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.compact),
                          Icon(
                            Icons.expand_more_rounded,
                            size: AppIconSize.small,
                            color: _textFaint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (next != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: _NextPrayerPanel(info: next, isTomorrow: nextIsTomorrow),
            ),
          const SizedBox(height: AppSpacing.md),
          _HomeActions(
            actions: [
              (
                key: const ValueKey('home-monthly-times'),
                label: t.homeScheduleButton,
                icon: Icons.calendar_month_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MonthlyTimesScreen(appState: appState),
                  ),
                ),
              ),
              (
                key: const ValueKey('home-prayer-calendar'),
                label: t.homeCalendarButton,
                icon: Icons.event_available_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrayerCalendarScreen(appState: appState),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Column(
              key: const ValueKey('today-prayers-panel'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++)
                  _ScheduleRow(spec: rows[i], showDivider: i < rows.length - 1),
              ],
            ),
          ),
          if (rows.isEmpty && appState.isLoadingDays)
            const _LoadingView()
          else if (rows.isEmpty && appState.daysError != null)
            _ErrorView(
              message: appState.daysError!,
              onRetry: appState.loadPrayerTimes,
            ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: NearbyMosqueCard(
              key: const ValueKey('home-nearby-mosque'),
              appState: appState,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _HomeActions(
            secondary: true,
            actions: [
              (
                key: const ValueKey('home-allah-names'),
                label: t.allahNamesTitle,
                icon: Icons.auto_awesome_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NamesScreen(appState: appState),
                  ),
                ),
              ),
              (
                key: const ValueKey('home-tasbih'),
                label: t.tasbihTitle,
                icon: Icons.touch_app_rounded,
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TasbihScreen())),
              ),
              (
                key: const ValueKey('home-settings'),
                label: t.settingsScreenTitle,
                icon: Icons.settings_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(appState: appState),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Future prayers remain informational until their start time.
  VoidCallback? _logTapFor(
    BuildContext context,
    AppState appState,
    PrayerDay day,
    PrayerKind kind,
    String key,
  ) {
    final now = appState.cityNow;
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(day.date.year, day.date.month, day.date.day);
    if (target.isAfter(today)) return null;
    if (_isSameDate(target, today) && !hasPrayerTimePassed(day, kind, now)) {
      return null;
    }
    return () =>
        appState.setPrayerStatus(day.date, key, PrayerLogStatus.onTime);
  }
}

class _NextPrayerPanel extends StatelessWidget {
  final NextPrayerInfo info;

  final bool isTomorrow;

  const _NextPrayerPanel({required this.info, required this.isTomorrow});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final kicker = isTomorrow ? t.homeNextPrayerTomorrow : t.nextPrayerLabel;
    final seconds = info.remaining.isNegative
        ? 0
        : (info.remaining.inMicroseconds +
                  Duration.microsecondsPerSecond -
                  1) ~/
              Duration.microsecondsPerSecond;
    final countdown = [
      seconds ~/ 3600,
      seconds ~/ 60 % 60,
      seconds % 60,
    ].map((part) => part.toString().padLeft(2, '0')).join(':');
    return SizedBox(
      key: const ValueKey('next-prayer-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                kicker,
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.body(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.medium,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.compact),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nameForPrayer(t, info.kind),
                      style: AppTextStyles.heading(
                        fontSize: AppFontSize.heading,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      arabicForPrayer(info.kind),
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.body(
                        fontSize: AppFontSize.small,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Semantics(
                    label: info.countdownLabel(t),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        countdown,
                        key: const ValueKey('next-prayer-countdown'),
                        textDirection: TextDirection.ltr,
                        style:
                            AppTextStyles.heading(
                              fontSize: AppFontSize.timer,
                              color: AppColors.text,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
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

/// One line of a prayer's data, independent of how [_ScheduleRow] renders
/// it — lets the schedule be built as a plain list and mapped over (for
/// inter-row dividers) instead of six near-identical widgets typed out by
/// hand.
class _RowSpec {
  final PrayerKind kind;
  final String time;
  final bool active;
  final bool current;
  final PrayerLogStatus? logStatus;
  final VoidCallback? onTapLog;

  const _RowSpec({
    required this.kind,
    required this.time,
    this.active = false,
    this.current = false,
    this.logStatus,
    this.onTapLog,
  });
}

class _ScheduleRow extends StatelessWidget {
  final _RowSpec spec;
  final bool showDivider;

  const _ScheduleRow({required this.spec, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final current = spec.current;
    final fg = current ? AppColors.accent : _textMuted;
    final nameColor = current ? AppColors.accent : _textMuted;

    final row = KeyedSubtree(
      key: current ? const ValueKey('current-prayer-row') : null,
      child: PrayerRowLayout(
        key: ValueKey('prayer-row-${spec.kind.name}'),
        variant: PrayerRowVariant.plain,
        leading: IconBadge(
          iconForPrayer(spec.kind),
          size: AppSize.badge,
          iconSize: AppIconSize.small,
          foreground: current ? AppColors.accent : _textMuted,
        ),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    nameForPrayer(t, spec.kind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.prayerName(color: nameColor),
                  ),
                ),
                if (current) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      t.homeCurrentPrayer,
                      key: const ValueKey('current-prayer-label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.prayerInlineLabel(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    arabicForPrayer(spec.kind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.prayerSubtitle(color: _textFaint),
                  ),
                ),
              ],
            ),
          ],
        ),
        time: Text(
          spec.time,
          style: AppTextStyles.heading(
            fontSize: AppFontSize.bodyLarge,
            color: fg,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        mark:
            spec.kind == PrayerKind.sunrise || spec.kind == PrayerKind.tahajjud
            ? null
            : PrayerMarkIndicator(
                key: ValueKey('prayer-mark-${spec.kind.name}'),
                status: spec.logStatus,
                onTap: spec.onTapLog,
              ),
      ),
    );

    final content = row;

    if (!showDivider) return content;
    return Column(
      children: [
        content,
        Divider(
          key: ValueKey('prayer-divider-${spec.kind.name}'),
          height: 1,
          thickness: .6,
          color: AppColors.text.withValues(alpha: AppOpacity.tint),
        ),
      ],
    );
  }
}

typedef _HomeAction = ({
  Key key,
  String label,
  IconData icon,
  VoidCallback onTap,
});

/// Shared two-column actions; large text stacks without horizontal scrolling.
class _HomeActions extends StatelessWidget {
  const _HomeActions({required this.actions, this.secondary = false});
  final List<_HomeAction> actions;
  final bool secondary;

  @override
  Widget build(BuildContext context) => Padding(
    key: ValueKey(
      secondary ? 'home-secondary-actions' : 'home-schedule-actions',
    ),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            MediaQuery.textScalerOf(context).scale(AppFontSize.body) >
            AppFontSize.body * 1.4;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final action in actions)
              SizedBox(
                key: action.key,
                width: stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - AppSpacing.xs) / 2,
                child: PillButton(
                  label: action.label,
                  icon: action.icon,
                  onTap: action.onTap,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Container(
      color: AppColors.transparent,
      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: AppIconSize.hero,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  fontSize: AppFontSize.body,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTap(
                feedbackOnChild: false,
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.text.withValues(
                        alpha: AppOpacity.border,
                      ),
                    ),
                    color: AppColors.text.withValues(alpha: AppOpacity.border),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: AppPressContent(
                    child: Text(
                      t.retryButton,
                      style: AppTextStyles.body(
                        fontSize: AppFontSize.body,
                        color: AppColors.accent,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
