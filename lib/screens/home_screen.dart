import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../data/date_labels.dart';
import '../data/next_prayer.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../models/prayer_log_status.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/log_prayer_sheet.dart';
import '../widgets/prayer_icon.dart';
import 'city_screen.dart';

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Color get _textMuted => AppColors.text.withValues(alpha: 0.56);
Color get _textFaint => AppColors.text.withValues(alpha: 0.36);

// AppColors.accent (gold) is bright/medium in *both* themes, so the icon or
// label drawn on top of a filled-accent shape (the retry button, a "qada"
// log mark) always wants dark text — unlike everywhere else on this screen,
// this one doesn't flip with the theme.
const _onAccentFill = Color(0xFF201404);

// AppColors.accent2 (deep gold) is deliberately tuned dark in both themes too
// (see _ScheduleRow's "current" fill) so light text reads on it either way.
const _onAccent2Fill = Color(0xFFF4EFE3);

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Width of one _RulerTick (36) plus the 6px gap this screen's own
  // separator puts after it.
  static const _dayTickExtent = 42.0;

  // null = "follow today" (the common case); set only once the user taps a
  // specific day in the strip, and cleared again by _onAppStateChanged or
  // the "Today" button.
  int? _selectedIndex;
  Timer? _ticker;
  AppLifecycleListener? _lifecycle;
  String? _lastScheduleKey;
  final _dayScrollController = ScrollController();
  // The todayIndex last centered on — re-centering exactly when this goes
  // stale (initial load, a new schedule, or midnight quietly moving "today"
  // one slot over while the app stays open) rather than on every rebuild.
  int? _lastCenteredTodayIndex;

  @override
  void initState() {
    super.initState();
    _startTicker();
    // Nothing on screen can go stale while the app is hidden, so the
    // per-minute rebuild is suspended until it comes back — and comes back
    // with an immediate refresh, since the countdown will have moved on by
    // more than a minute.
    _lifecycle = AppLifecycleListener(
      onHide: _stopTicker,
      onShow: () {
        if (mounted) setState(() {});
        _startTicker();
      },
    );
    // Listens directly rather than relying on a parent AnimatedBuilder (see
    // RootShell) — that used to rebuild this, MoreScreen and SettingsScreen
    // together on every single AppState change anywhere in the app (e.g.
    // toggling a setting on a totally different screen), which is what made
    // so many unrelated actions feel janky.
    widget.appState.addListener(_onAppStateChanged);
  }

  // Keeps the next-prayer countdown fresh without any extra network calls —
  // just recomputes from the already-fetched schedule.
  void _startTicker() {
    _ticker ??= Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onAppStateChanged() {
    // Selecting a new city/method/madhab reloads the schedule — the
    // previously selected day index may no longer make sense against it, so
    // this mirrors what remounting via a ValueKey used to do.
    final key =
        '${widget.appState.selectedCityId}|${widget.appState.method}|${widget.appState.madhab}';
    if (_lastScheduleKey != null && _lastScheduleKey != key) {
      _selectedIndex = null;
      _lastCenteredTodayIndex = null;
    }
    _lastScheduleKey = key;
    setState(() {});
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _stopTicker();
    _dayScrollController.dispose();
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  // The day strip now spans _pastDays..._futureDays around today (see
  // AppState), so "today" is rarely index 0 — without this it'd load
  // scrolled to the past end, with today off-screen to the right.
  void _centerOnToday(int todayIndex, double viewportWidth) {
    if (!_dayScrollController.hasClients) return;
    final target = todayIndex * _dayTickExtent - viewportWidth / 2 + 18;
    _dayScrollController.jumpTo(
      target.clamp(0.0, _dayScrollController.position.maxScrollExtent),
    );
  }

  void _goToToday(int todayIndex, double viewportWidth) {
    setState(() => _selectedIndex = null);
    if (!_dayScrollController.hasClients) return;
    final target = todayIndex * _dayTickExtent - viewportWidth / 2 + 18;
    _dayScrollController.animateTo(
      target.clamp(0.0, _dayScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = widget.appState;
    final days = appState.days;

    if (appState.isLoadingDays && days.isEmpty) {
      return const _LoadingView();
    }
    if (appState.daysError != null && days.isEmpty) {
      return _ErrorView(
        message: appState.daysError!,
        onRetry: appState.loadPrayerTimes,
      );
    }
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final todayIndex = appState.todayIndex;
    final dayStripWidth = MediaQuery.sizeOf(context).width - 36;
    if (_selectedIndex == null && _lastCenteredTodayIndex != todayIndex) {
      _lastCenteredTodayIndex = todayIndex;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerOnToday(todayIndex, dayStripWidth),
      );
    }

    final selectedIndex =
        (_selectedIndex != null && _selectedIndex! < days.length)
        ? _selectedIndex!
        : todayIndex;
    final selectedDay = days[selectedIndex];
    final showingToday = selectedIndex == todayIndex;
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
    final todayDate = days[todayIndex].date;
    // Which prayer (if any) is highlighted on *whichever day is currently
    // browsed* — not just today. Across midnight, `current`/`next` can
    // belong to yesterday or tomorrow's own record (see
    // computeCurrentPrayer/computeNextPrayer's cross-midnight handling); by
    // matching on the actual date those carry rather than gating on
    // `showingToday`, browsing to that specific day shows the highlight on
    // its own row — e.g. at 00:01, paging back one day shows Isha as
    // current there; at 23:59, paging forward one day shows Fajr as next
    // there. The separate "Вчера"/"Завтра" callouts below are untouched by
    // this — they still only ever show on today's own page.
    final currentKindOnSelectedDay =
        current != null && _isSameDate(current.date, selectedDay.date)
        ? current.kind
        : null;
    final nextKindOnSelectedDay =
        next != null && _isSameDate(next.date, selectedDay.date)
        ? next.kind
        : null;
    final nextIsTomorrow = next != null && !_isSameDate(next.date, todayDate);

    VoidCallback? logTap(PrayerKind kind, String key) =>
        _logTapFor(context, appState, selectedDay, kind, key);

    final rows = <_RowSpec>[
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

    // No SafeArea: content scrolls edge-to-edge, up under the transparent
    // status bar. The top inset is baked into the scroll padding instead,
    // so it only reserves space at rest — scrolling still carries content
    // past it, rather than a fixed gap nothing can enter.
    //
    // The city row below sits inside RootShell's guarded PageView (see
    // EdgeGestureGuard there) — its topExclusion is what keeps that button
    // tappable near the screen edges, rather than any padding or special
    // layout here.
    //
    // The Container fills the whole page with AppColors.bg — this screen
    // carries its own color scheme (see home_palette.dart) independent of
    // the shared AppColors the rest of the app still uses, since this
    // restyle is scoped to HomeScreen only for now.
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 130),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CityScreen(appState: appState),
                  ),
                ),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: _textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      appState.cityLabel(t),
                      style: AppTextStyles.body(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: _textFaint,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDay.weekdayFullCapitalized(t),
                      style: AppTextStyles.body(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDay.dateLabel(t),
                      style: AppTextStyles.heading(
                        fontSize: 24,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              _TodayLink(
                isToday: showingToday,
                onTap: () => _goToToday(todayIndex, dayStripWidth),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Always visible, regardless of which day is being browsed below —
          // this is "what's actually coming up right now" in real time, not
          // tied to selectedDay.
          if (next != null)
            _NextPrayerPanel(info: next, isTomorrow: nextIsTomorrow),
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: ListView.separated(
              controller: _dayScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final d = days[i];
                return _RulerTick(
                  dayNumber: d.dayNumber,
                  selected: i == selectedIndex,
                  isToday: i == todayIndex,
                  onTap: () => setState(() => _selectedIndex = i),
                );
              },
            ),
          ),
          Divider(color: AppColors.divider, height: 21),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < rows.length; i++)
                _ScheduleRow(
                  spec: rows[i],
                  showDivider:
                      i < rows.length - 1 &&
                      !rows[i].current &&
                      !rows[i + 1].current,
                ),
              if (showingToday && next != null && nextIsTomorrow) ...[
                const SizedBox(height: 14),
                _Kicker(
                  t.nextPrayerTomorrowLabel(DateLabels.dateLabel(t, next.date)),
                ),
                _ScheduleRow(
                  spec: _RowSpec(
                    kind: next.kind,
                    time: next.time,
                    active: true,
                  ),
                ),
              ],
              if (showingToday &&
                  current != null &&
                  current.isFromPreviousDay) ...[
                const SizedBox(height: 14),
                _Kicker(
                  t.yesterdayCurrentLabel(
                    DateLabels.dateLabel(t, current.date),
                  ),
                ),
                _ScheduleRow(
                  spec: _RowSpec(
                    kind: PrayerKind.isha,
                    time: current.time,
                    current: true,
                    logStatus: appState.prayerStatusFor(current.date, 'isha'),
                    onTapLog: _logTapFor(
                      context,
                      appState,
                      days[todayIndex - 1],
                      PrayerKind.isha,
                      'isha',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Only a prayer that has actually happened can be marked. On a past day
  // that's all of them — the day strip reaches a week back, and filling in
  // what was missed is the point of being able to browse there at all. On
  // today it's the ones whose time has arrived, and on a future day none:
  // a prayer still ahead can't have been prayed.
  //
  // Returns null for the rest, which disables both the tap and the swipe —
  // see _ScheduleRow/_SwipeToLog.
  //
  // Always opens the sheet — including for the still-current prayer, which
  // used to skip straight to "on time" on a plain tap. Now that logging
  // only happens via a deliberate swipe (see _SwipeToLog) rather than a
  // small always-visible badge, that shortcut isn't needed: one gesture,
  // one sheet, every time.
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
    return () {
      final t = AppLocalizations.of(context)!;
      showLogPrayerSheet(
        context,
        prayerName: nameForPrayer(t, kind),
        current: appState.prayerStatusFor(day.date, key),
        onPick: (status) => appState.setPrayerStatus(day.date, key, status),
      );
    };
  }
}

/// The next-prayer callout, drawn as a flagged bulletin strip — a thick
/// accent stripe down the left edge of an otherwise plain panel — rather
/// than a filled card, so it reads as "the one flagged item" among the
/// plain schedule rows below it instead of just another colored box.
class _NextPrayerPanel extends StatelessWidget {
  final NextPrayerInfo info;

  /// True once every prayer today has already passed and [info] is
  /// actually tomorrow's — reads "Завтра, {date}" instead of the generic
  /// kicker in that case.
  final bool isTomorrow;

  const _NextPrayerPanel({required this.info, required this.isTomorrow});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final kicker = isTomorrow
        ? t.nextPrayerTomorrowLabel(DateLabels.dateLabel(t, info.date))
        : t.nextPrayerLabel;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: AppColors.accent, width: 5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kicker.toUpperCase(),
                  style: AppTextStyles.body(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ).copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(height: 5),
                Text(
                  nameForPrayer(t, info.kind),
                  style: AppTextStyles.heading(
                    fontSize: 21,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  arabicForPrayer(info.kind),
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.body(fontSize: 12, color: _textMuted),
                ),
                const SizedBox(height: 5),
                Text(
                  info.countdownLabel(t),
                  style: AppTextStyles.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          Text(
            info.time,
            style: AppTextStyles.heading(fontSize: 32, color: AppColors.text)
                .copyWith(
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  final String label;

  const _Kicker(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.body(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ).copyWith(letterSpacing: 1.0),
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

/// One line of the schedule "table". No per-row card/background in the
/// common case — [_RowSpec.current] is the only thing that gets a filled
/// block (today's one true highlight, in [AppColors.accent2]); [_RowSpec.active]
/// (next up) is marked with nothing more than [AppColors.accent] on its own
/// text, so the two states stay visually distinct instead of piling up
/// chrome. There's no always-visible log button any more — see
/// [_SwipeToLog] — just [_StatusDot], a quiet, untappable record of
/// whatever was last logged.
class _ScheduleRow extends StatelessWidget {
  final _RowSpec spec;
  final bool showDivider;

  const _ScheduleRow({required this.spec, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final current = spec.current;
    final active = spec.active;
    final fg = current
        ? _onAccent2Fill
        : active
        ? AppColors.accent
        : _textMuted;
    final nameColor = current
        ? _onAccent2Fill
        : active
        ? AppColors.text
        : AppColors.text.withValues(alpha: 0.8);

    final row = Container(
      decoration: BoxDecoration(
        color: current ? AppColors.accent2 : Colors.transparent,
        borderRadius: current ? BorderRadius.circular(10) : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: current ? 12 : 2, vertical: 12),
      child: Row(
        children: [
          Icon(iconForPrayer(spec.kind), size: 17, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nameForPrayer(t, spec.kind),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading(fontSize: 15, color: nameColor),
                ),
                Text(
                  arabicForPrayer(spec.kind),
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.body(
                    fontSize: 10.5,
                    color: current
                        ? _onAccent2Fill.withValues(alpha: 0.75)
                        : _textFaint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            spec.time,
            style: AppTextStyles.heading(
              fontSize: 16,
              color: fg,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          // Shown whenever there's a status to show, not just when the row
          // is loggable — a future day still shows whatever it somehow has
          // on record, it just can't be changed (spec.onTapLog is null
          // there, so _SwipeToLog below is skipped and this dot is the only
          // trace).
          if (spec.onTapLog != null || spec.logStatus != null) ...[
            const SizedBox(width: 8),
            _StatusDot(status: spec.logStatus, onFill: current),
          ],
        ],
      ),
    );

    final content = spec.onTapLog != null
        ? _SwipeToLog(onLog: spec.onTapLog!, status: spec.logStatus, child: row)
        : row;

    if (!showDivider) return content;
    return Column(
      children: [
        content,
        Divider(color: AppColors.divider, height: 1),
      ],
    );
  }
}

/// A quiet, untappable record of a prayer's log status — since logging now
/// only happens through [_SwipeToLog], there's no button here to double as
/// a status readout any more, just this small dot.
class _StatusDot extends StatelessWidget {
  final PrayerLogStatus? status;

  /// True when this is the row for the prayer whose window is open right
  /// now (drawn on top of the filled deep-gold "current" block). _ScheduleRow
  /// only ever builds this widget once the prayer's time has actually
  /// arrived (see its onTapLog/logStatus gate), so a null [status] means
  /// "not marked yet" whether that's because it's still current or because
  /// a later prayer has already taken over — either way, the same hollow
  /// ring: still-open and already-missed read the same rather than singling
  /// the latter out as a verdict.
  final bool onFill;

  const _StatusDot({required this.status, required this.onFill});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      final ringColor = onFill
          ? _onAccent2Fill.withValues(alpha: 0.7)
          : AppColors.text.withValues(alpha: 0.35);
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 1.4),
        ),
      );
    }
    final color = onFill
        ? _onAccent2Fill
        : status == PrayerLogStatus.onTime
        ? AppColors.accent2
        : AppColors.accent;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Wraps a loggable [_ScheduleRow] so it can be marked prayed either with a
/// swipe or a plain tap on the row — there's no always-visible button any
/// more (see [_StatusDot]). The swipe still sidesteps an edge-tap problem
/// the old button had: it sat close to the screen's right edge, which on
/// Android can fall inside the system back-gesture margin, where
/// EdgeGestureGuard (see root_shell.dart) deliberately lets touches fall
/// through to the OS instead of this app. A swipe starts wherever the
/// finger first lands, almost always well inside that margin, so it's never
/// caught by the guard to begin with.
///
/// Dragging past the threshold reveals a round button (not a full-width
/// colored panel — a small circle reads as "a button appeared" rather than
/// "the row turned into a rectangle") and, on release, opens the same log
/// sheet a tap on the old badge used to.
class _SwipeToLog extends StatefulWidget {
  final Widget child;
  final VoidCallback onLog;

  /// What the revealed button previews — the same status [_StatusDot] shows
  /// on the row at rest, so the swipe doesn't always promise "mark as
  /// prayed on time" when it might really be "already logged late, tap to
  /// change" or "nothing logged yet, tap to add one".
  final PrayerLogStatus? status;

  const _SwipeToLog({
    required this.child,
    required this.onLog,
    required this.status,
  });

  @override
  State<_SwipeToLog> createState() => _SwipeToLogState();
}

class _SwipeToLogState extends State<_SwipeToLog>
    with SingleTickerProviderStateMixin {
  static const _maxDrag = 68.0;
  static const _triggerDrag = 42.0;

  late final AnimationController _snapBack;
  Tween<double>? _snapTween;

  // A ValueNotifier rather than setState: the drag and the snap-back both
  // run at frame rate, and setState here rebuilt the entire prayer row —
  // icon, both labels, the time, the status dot — on every one of those
  // frames. Only the two things that actually move listen to it now.
  final _dragX = ValueNotifier<double>(0);
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _snapBack =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          _dragX.value = _snapTween!.evaluate(_snapBack);
        });
  }

  @override
  void dispose() {
    _snapBack.dispose();
    _dragX.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _snapBack.stop();
    final next = (_dragX.value + d.delta.dx).clamp(-_maxDrag, 0.0);
    final nowArmed = next <= -_triggerDrag;
    if (nowArmed != _armed) HapticFeedback.selectionClick();
    _armed = nowArmed;
    _dragX.value = next;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_armed) widget.onLog();
    _armed = false;
    _snapTween = Tween(begin: _dragX.value, end: 0);
    _snapBack.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Mirrors _StatusDot's own color logic — the button previews whatever
    // swiping it will actually open, not a generic "mark done" checkmark
    // regardless of what's already logged.
    final (bg, border, icon, iconColor) = switch (widget.status) {
      PrayerLogStatus.onTime => (
        AppColors.accent2,
        Colors.transparent,
        Icons.check_rounded,
        _onAccent2Fill,
      ),
      PrayerLogStatus.qada => (
        AppColors.accent,
        Colors.transparent,
        Icons.history_toggle_off_rounded,
        _onAccentFill,
      ),
      null => (
        AppColors.surface,
        AppColors.text.withValues(alpha: 0.3),
        Icons.check_rounded,
        AppColors.text.withValues(alpha: 0.55),
      ),
    };
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: ValueListenableBuilder<double>(
            valueListenable: _dragX,
            child: Icon(icon, color: iconColor, size: 17),
            builder: (context, dragX, child) {
              final reveal = (dragX.abs() / _triggerDrag).clamp(0.0, 1.0);
              return Transform.scale(
                scale: 0.4 + reveal * 0.6,
                child: Opacity(
                  opacity: reveal,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                      border: Border.all(color: border, width: 1.6),
                    ),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
        GestureDetector(
          onTap: widget.onLog,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: ValueListenableBuilder<double>(
            valueListenable: _dragX,
            child: Container(color: AppColors.bg, child: widget.child),
            builder: (context, dragX, child) =>
                Transform.translate(offset: Offset(dragX, 0), child: child),
          ),
        ),
      ],
    );
  }
}

class _TodayLink extends StatelessWidget {
  final bool isToday;
  final VoidCallback onTap;

  const _TodayLink({required this.isToday, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: isToday ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isToday) ...[
            Icon(Icons.replay_rounded, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
          ],
          Text(
            t.todayLabel,
            style: AppTextStyles.body(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isToday ? _textFaint : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tick of the day strip, drawn as a small mark bottom-aligned against
/// the row's baseline (see the enclosing Row/divider in HomeScreen) rather
/// than a standalone pill — the run of ticks reads as a single ruler rather
/// than a series of separate buttons.
class _RulerTick extends StatelessWidget {
  final String dayNumber;
  final bool selected;
  final bool isToday;
  final VoidCallback? onTap;

  const _RulerTick({
    required this.dayNumber,
    this.selected = false,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.accent
        : isToday
        ? AppColors.text.withValues(alpha: 0.85)
        : _textFaint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              dayNumber,
              style: AppTextStyles.heading(
                fontSize: selected ? 17 : 14,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 20 : (isToday ? 8 : 3),
              height: 3,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent
                    : isToday
                    ? AppColors.accent.withValues(alpha: 0.6)
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
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
    return Container(
      color: AppColors.bg,
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
    final t = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.accent),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    t.retryButton,
                    style: AppTextStyles.body(
                      fontSize: 14,
                      color: _onAccentFill,
                      fontWeight: FontWeight.w700,
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
