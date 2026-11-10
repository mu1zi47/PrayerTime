import '../widgets/app_tap.dart';
import '../widgets/app_chevron.dart';
import '../widgets/ambient_surface.dart';
import 'package:flutter/material.dart';

import '../data/date_labels.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../services/prayer_times_api.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/edge_gesture_guard.dart';

/// A month-at-a-time table of prayer times, reachable from the home screen.
/// Unlike [PrayerCalendarScreen] nothing is marked here — it's a lookup: one
/// month back through one month ahead of today, which is past the ±7-day
/// window [AppState.days] keeps, so each month is fetched on demand via
/// [AppState.monthDays].
///
/// Those three months are the three pages of a [PageView], so they're
/// swiped between as well as stepped through with the arrows.
class MonthlyTimesScreen extends StatefulWidget {
  final AppState appState;

  const MonthlyTimesScreen({super.key, required this.appState});

  @override
  State<MonthlyTimesScreen> createState() => _MonthlyTimesScreenState();
}

class _MonthlyTimesScreenState extends State<MonthlyTimesScreen> {
  static const _currentPage = 1;

  late final List<DateTime> _months;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final now = widget.appState.cityNow;
    _months = [
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    ];
    _controller = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    return AmbientScaffold(
      backgroundColor: Colors.transparent,
      // A real app bar rather than a pinned SliverAppBar: it stays put over
      // all three month pages, which each scroll on their own.
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        leadingWidth: 56,
        titleSpacing: 12,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ScreenBackButton(onTap: () => Navigator.of(context).pop()),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.monthlyTimesTitle,
              style: AppTextStyles.heading(fontSize: 22),
            ),
            Text(
              widget.appState.cityLabel(t),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                fontSize: 13,
                color: AppColors.text,
              ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
      // A PageView builds only the page on screen, so opening the screen
      // fetches one month; a neighbour starts loading as the swipe brings it
      // into view, and [AppState.monthDays] caches it from then on.
      body: ValueListenableBuilder<bool>(
        valueListenable: Navigator.of(context).userGestureInProgressNotifier,
        builder: (context, systemBack, _) => EdgeGestureGuard(
          left: true,
          right: true,
          bottom: true,
          child: AmbientPageMotion(
            positions: const [
              Alignment(.75, -.5),
              Alignment(-.65, -.8),
              Alignment(.65, .6),
            ],
            child: PageView.builder(
              controller: _controller,
              physics: systemBack ? const NeverScrollableScrollPhysics() : null,
              itemCount: _months.length,
              itemBuilder: (context, i) => _MonthPage(
                appState: widget.appState,
                month: _months[i],
                // Disabled at the ends rather than hidden, so the arrows stay
                // where the eye expects them — and they agree with what the swipe
                // can reach.
                onPrev: i > 0 ? () => _goToPage(i - 1) : null,
                onNext: i < _months.length - 1 ? () => _goToPage(i + 1) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One month's page: its own scroll, its own fetch, and its own pinned
/// column headings.
class _MonthPage extends StatefulWidget {
  final AppState appState;
  final DateTime month;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _MonthPage({
    required this.appState,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<_MonthPage> createState() => _MonthPageState();
}

class _MonthPageState extends State<_MonthPage>
    with AutomaticKeepAliveClientMixin {
  List<PrayerDay>? _days;
  String? _error;
  bool _loading = false;

  // Keeps a month that's already been fetched and scrolled around exactly as
  // it was when it's swiped back to.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final days = await widget.appState.monthDays(
        widget.month.year,
        widget.month.month,
      );
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        // An empty month is nothing to show — it reads as a failed load
        // rather than a blank page with a retry nobody can find.
        _days = days.isEmpty ? null : days;
        _error = days.isEmpty ? t.genericLoadError : null;
      });
    } catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _days = null;
        _error =
            e is PrayerApiException && e.error == PrayerApiError.noConnection
            ? t.errorNoConnection
            : t.genericLoadError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    super.build(context);
    final t = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final now = widget.appState.cityNow;
    final today = DateTime(now.year, now.month, now.day);
    final showTahajjud = widget.appState.tahajjudEnabled;
    final days = _days;
    final styles = _RowStyles.of();

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, padding.bottom + 18),
      child: Column(
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MonthNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: widget.onPrev,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateLabels.monthYearLabel(t, widget.month),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading(fontSize: 17),
                  ),
                ),
                const SizedBox(width: 12),
                _MonthNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: widget.onNext,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GlassPanel(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: _HeaderRow(showTahajjud: showTahajjud),
                  ),
                  const PanelDivider(),
                  Expanded(
                    child: _loading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: _ErrorBlock(
                              message: _error!,
                              onRetry: _load,
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: days?.length ?? 0,
                            itemBuilder: (context, i) {
                              final day = days![i];
                              return _DayRow(
                                day: day,
                                showTahajjud: showTahajjud,
                                isToday: DateUtils.isSameDay(day.date, today),
                                styles: styles,
                                weekday: DateLabels.shortWeekday(t, day.date),
                                showDivider: i < days.length - 1,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The handful of styles every row of the table shares, built once per page
/// rather than per row: a month is 31 rows of eight cells each, and each one
/// was allocating its own copies.
class _RowStyles {
  final TextStyle time;
  final TextStyle timeToday;
  final TextStyle day;
  final TextStyle dayToday;
  final TextStyle weekday;

  const _RowStyles({
    required this.time,
    required this.timeToday,
    required this.day,
    required this.dayToday,
    required this.weekday,
  });

  factory _RowStyles.of() => _RowStyles(
    time: AppTextStyles.body(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.text.withValues(alpha: 0.85),
    ),
    timeToday: AppTextStyles.body(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: AppColors.accent700,
    ),
    day: AppTextStyles.body(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
    dayToday: AppTextStyles.body(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AppColors.accent,
    ),
    weekday: AppTextStyles.body(
      fontSize: 11,
      color: AppColors.text.withValues(alpha: 0.45),
    ),
  );
}

/// Column widths are shared by the header and every row so the times line up
/// as a table without a Table widget's sizing pass on a 31-row list.
const _dayColumnWidth = 36.0;

class _HeaderRow extends StatelessWidget {
  final bool showTahajjud;

  const _HeaderRow({required this.showTahajjud});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final style = AppTextStyles.body(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ).copyWith(color: AppColors.text.withValues(alpha: 0.5));
    return Row(
      children: [
        SizedBox(
          width: _dayColumnWidth,
          child: Text('', style: style),
        ),
        if (showTahajjud)
          Expanded(
            child: Center(child: Text(t.prayerTahajjud, style: style)),
          ),
        Expanded(
          child: Center(child: Text(t.prayerFajr, style: style)),
        ),
        Expanded(
          child: Center(child: Text(t.prayerSunrise, style: style)),
        ),
        Expanded(
          child: Center(child: Text(t.prayerZuhr, style: style)),
        ),
        Expanded(
          child: Center(child: Text(t.prayerAsr, style: style)),
        ),
        Expanded(
          child: Center(child: Text(t.prayerMaghrib, style: style)),
        ),
        Expanded(
          child: Center(child: Text(t.prayerIsha, style: style)),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final bool showDivider;
  final PrayerDay day;
  final bool showTahajjud;
  final bool isToday;
  final _RowStyles styles;

  /// Resolved by the page rather than here, so a row needs no localization
  /// lookup of its own.
  final String weekday;

  const _DayRow({
    this.showDivider = true,
    required this.day,
    required this.showTahajjud,
    required this.isToday,
    required this.styles,
    required this.weekday,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final timeStyle = isToday ? styles.timeToday : styles.time;

    Widget time(String value) => Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: timeStyle),
        ),
      ),
    );

    return PanelRow(
      showDivider: showDivider,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      selected: isToday,
      child: Row(
        children: [
          SizedBox(
            width: _dayColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.date.day}',
                  style: isToday ? styles.dayToday : styles.day,
                ),
                Text(weekday, style: styles.weekday),
              ],
            ),
          ),
          if (showTahajjud) time(day.tahajjud),
          time(day.fajr),
          time(day.sunrise),
          time(day.zuhr),
          time(day.asr),
          time(day.maghrib),
          time(day.isha),
        ],
      ),
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
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: .04),
          border: Border.all(color: AppColors.text.withValues(alpha: .08)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AppPressContent(
          child: AppChevron(icon: icon, enabled: enabled),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(t.retryButton)),
        ],
      ),
    );
  }
}
