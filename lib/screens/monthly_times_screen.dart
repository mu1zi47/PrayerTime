import 'package:flutter/material.dart';

import '../data/date_labels.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../services/prayer_times_api.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

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
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      // A real app bar rather than a pinned SliverAppBar: it stays put over
      // all three month pages, which each scroll on their own.
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 62,
        leadingWidth: 56,
        titleSpacing: 14,
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
              style: AppTextStyles.heading(fontSize: 19),
            ),
            Text(
              widget.appState.cityLabel(t),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                fontSize: 11.5,
                color: AppColors.text,
              ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
      // A PageView builds only the page on screen, so opening the screen
      // fetches one month; a neighbour starts loading as the swipe brings it
      // into view, and [AppState.monthDays] caches it from then on.
      body: PageView.builder(
        controller: _controller,
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
    super.build(context);
    final t = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final now = widget.appState.cityNow;
    final today = DateTime(now.year, now.month, now.day);
    final showTahajjud = widget.appState.tahajjudEnabled;
    final days = _days;
    final styles = _RowStyles.of();

    // The month and its arrows scroll away with the days — they belong to
    // the month being read. The column headings above the rows don't: a
    // month of bare times loses its labels the moment they scroll off.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MonthNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: widget.onPrev,
                ),
                Text(
                  DateLabels.monthYearLabel(t, widget.month),
                  style: AppTextStyles.heading(fontSize: 16),
                ),
                _MonthNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: widget.onNext,
                ),
              ],
            ),
          ),
        ),
        if (days != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _ColumnHeadingsHeader(
              // Built here, so the delegate has nothing to build while the
              // days scroll under it.
              child: _HeaderRow(showTahajjud: showTahajjud),
            ),
          ),
        if (_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          )
        else if (_error != null)
          SliverToBoxAdapter(
            child: _ErrorBlock(message: _error!, onRetry: _load),
          )
        else if (days != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, padding.bottom + 24),
            // Every row is the same height, so one prototype is measured and
            // the rest are placed from it — the list never lays a child out
            // just to learn how tall it is, which is what a month of rows
            // scrolling under a pinned header would otherwise pay for on
            // every frame. A prototype rather than a hard-coded extent, so
            // the row still grows with the system text size.
            sliver: SliverPrototypeExtentList.builder(
              prototypeItem: _DayRow(
                day: days.first,
                showTahajjud: showTahajjud,
                isToday: false,
                styles: styles,
                weekday: '',
              ),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final d = days[i];
                return _DayRow(
                  day: d,
                  showTahajjud: showTahajjud,
                  isToday:
                      d.date.year == today.year &&
                      d.date.month == today.month &&
                      d.date.day == today.day,
                  styles: styles,
                  weekday: DateLabels.shortWeekday(t, d.date),
                );
              },
            ),
          ),
      ],
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
      color: AppColors.text.withValues(alpha: 0.8),
    ),
    timeToday: AppTextStyles.body(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
    day: AppTextStyles.body(
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
      color: AppColors.text,
    ),
    dayToday: AppTextStyles.body(
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
      color: AppColors.accent,
    ),
    weekday: AppTextStyles.body(
      fontSize: 10,
      color: AppColors.text.withValues(alpha: 0.45),
    ),
  );
}

/// Keeps the column headings under the title bar while the days scroll past
/// them — without it, a month's worth of bare times loses its labels as soon
/// as it moves.
class _ColumnHeadingsHeader extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _ColumnHeadingsHeader({required this.child});

  static const _height = 40.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      // Opaque so the rows pass behind it rather than through it.
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: Container(
        height: _height - 6,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(_ColumnHeadingsHeader oldDelegate) =>
      oldDelegate.child != child;
}

/// Column widths are shared by the header and every row so the times line up
/// as a table without a Table widget's sizing pass on a 31-row list.
const _dayColumnWidth = 44.0;

class _HeaderRow extends StatelessWidget {
  final bool showTahajjud;

  const _HeaderRow({required this.showTahajjud});

  @override
  Widget build(BuildContext context) {
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
  final PrayerDay day;
  final bool showTahajjud;
  final bool isToday;
  final _RowStyles styles;

  /// Resolved by the page rather than here, so a row needs no localization
  /// lookup of its own.
  final String weekday;

  const _DayRow({
    required this.day,
    required this.showTahajjud,
    required this.isToday,
    required this.styles,
    required this.weekday,
  });

  @override
  Widget build(BuildContext context) {
    final timeStyle = isToday ? styles.timeToday : styles.time;

    Widget time(String value) => Expanded(
      child: Center(child: Text(value, style: timeStyle)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: isToday ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        // Same width either way: a border insets its own box, so a thicker
        // one on today's row alone would make that row a hair shorter than
        // the rest — and the list sizes every row from one prototype.
        border: Border.all(
          color: isToday ? AppColors.accent : AppColors.divider,
          width: 1.4,
        ),
      ),
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

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
