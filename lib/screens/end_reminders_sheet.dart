import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';

import '../data/prayer_window.dart';
import '../l10n/app_localizations.dart';
import '../models/end_reminders.dart';
import '../models/notif_mode.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/status_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/icon_badge.dart';
import '../widgets/pill_button.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/swipe_actions.dart';

/// Deleting is the one thing on these screens that can't be taken back, so
/// it takes the color that says so everywhere else, rather than the app's
/// own golds. Muted enough to sit in either theme.
const _deleteColor = Color(0xFFC4523F);

/// Today's window for [prayerKey], or null before any times are on hand.
/// The reminders are listed against it so each one reads as a clock time,
/// like an alarm — it shifts by a minute or two from day to day, but that's
/// close enough to choose by.
({DateTime start, DateTime end})? _todayWindow(
  AppState appState,
  String prayerKey,
) {
  final days = appState.days;
  if (days.isEmpty) return null;
  final index = appState.todayIndex;
  final end = prayerWindowEnd(days, index, prayerKey);
  if (end == null) return null;
  return (start: prayerWindowStart(days[index], prayerKey), end: end);
}

/// Every prayer's "window is closing" reminders in one place, set the way
/// alarms are: pick the prayer up top, then a list of its reminders, each
/// with when it would go off today, one tap to change one and another to
/// remove it, and a button for one more.
Future<void> showEndRemindersSheet(BuildContext context, AppState appState) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _EndRemindersSheet(appState: appState),
  );
}

const _prayers = [
  ('fajr', PrayerKind.fajr),
  ('zuhr', PrayerKind.zuhr),
  ('asr', PrayerKind.asr),
  ('maghrib', PrayerKind.maghrib),
  ('isha', PrayerKind.isha),
];

class _EndRemindersSheet extends StatefulWidget {
  final AppState appState;

  const _EndRemindersSheet({required this.appState});

  @override
  State<_EndRemindersSheet> createState() => _EndRemindersSheetState();
}

class _EndRemindersSheetState extends State<_EndRemindersSheet> {
  int _selected = 0;

  /// The reminder whose actions are swiped open, if any — see
  /// SwipeActionTile.openTile.
  final _openTile = ValueNotifier<Object?>(null);

  @override
  void dispose() {
    _openTile.dispose();
    super.dispose();
  }

  AppState get _appState => widget.appState;
  String get _prayerKey => _prayers[_selected].$1;
  PrayerKind get _kind => _prayers[_selected].$2;

  /// What a new reminder's picker opens on: the first of a few common
  /// leads this prayer doesn't have yet and can.
  int _suggestedLead() {
    final leads = _appState.endRemindersFor(_prayerKey);
    final max = _appState.maxEndReminderLeadFor(_prayerKey);
    for (final m in const [30, 15, 10, 60, 45, 20, 5]) {
      if (m <= max && !leads.contains(m)) return m;
    }
    return max;
  }

  Future<int?> _pick(int initial) => showLeadPicker(
    context,
    initial: initial,
    max: _appState.maxEndReminderLeadFor(_prayerKey),
    window: _todayWindow(_appState, _prayerKey),
  );

  Future<void> _add() async {
    final t = AppLocalizations.of(context)!;
    final key = _prayerKey;
    final minutes = await _pick(_suggestedLead());
    if (minutes == null || !mounted) return;
    if (!_appState.addEndReminder(key, minutes)) {
      AppToast.show(context, t.endReminderDuplicate, icon: Icons.alarm_rounded);
    }
  }

  Future<void> _edit(int lead) async {
    final t = AppLocalizations.of(context)!;
    final key = _prayerKey;
    final minutes = await _pick(lead);
    if (minutes == null || !mounted) return;
    if (!_appState.changeEndReminder(key, lead, minutes)) {
      AppToast.show(context, t.endReminderDuplicate, icon: Icons.alarm_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final muted = AppColors.text.withValues(alpha: 0.6);
        final leads = _appState.endRemindersFor(_prayerKey);
        final window = _todayWindow(_appState, _prayerKey);
        final prayerOff =
            (_appState.notifMode[_prayerKey] ?? NotifMode.notification) ==
            NotifMode.off;
        final full = leads.length >= kMaxEndReminders;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                Text(
                  t.endRemindersName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(fontSize: 18),
                ),
                // When the chosen prayer's time ends today, so the
                // reminders below can be read against it.
                if (window != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    t.endRemindersWindowEnds(
                      nameForPrayer(t, _kind),
                      formatClock(window.end),
                    ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(fontSize: 13.5, color: muted),
                  ),
                ],
                const SizedBox(height: 18),
                _PrayerSwitcher(
                  selected: _selected,
                  counts: [
                    for (final (key, _) in _prayers)
                      _appState.endRemindersFor(key).length,
                  ],
                  onSelect: (i) => setState(() => _selected = i),
                ),
                const SizedBox(height: 16),
                if (prayerOff) ...[
                  Text(
                    t.endRemindersPrayerOff,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: muted,
                    ).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                ],
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (leads.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                t.endRemindersEmpty,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(
                                  fontSize: 14,
                                  color: muted,
                                ),
                              ),
                            ),
                          if (leads.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 2,
                                bottom: 8,
                              ),
                              child: Text(
                                t.endRemindersListHeader,
                                style: AppTextStyles.body(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: muted,
                                ),
                              ),
                            ),
                          for (final lead in leads)
                            _ReminderTile(
                              key: ValueKey('$_prayerKey-$lead'),
                              lead: lead,
                              window: window,
                              offToday: _appState.isEndReminderOffToday(
                                _prayerKey,
                                lead,
                              ),
                              openTile: _openTile,
                              onTap: () => _edit(lead),
                              onDelete: () =>
                                  _appState.removeEndReminder(_prayerKey, lead),
                              onToggleToday: () => _appState
                                  .toggleEndReminderOffToday(_prayerKey, lead),
                            ),
                          // Swiping is the only way to these, so it's said
                          // once, under the list.
                          if (leads.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                t.endRemindersSwipeHint,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.text.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: full
                      ? t.endRemindersLimit(kMaxEndReminders)
                      : t.endReminderAdd,
                  icon: full ? null : Icons.add_rounded,
                  onTap: full ? null : _add,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The five prayers side by side, the chosen one in the app's selected
/// colors (soft gold behind, deep gold on top — see IconBadge), each with
/// a small count of its reminders so the ones set up show at a glance.
class _PrayerSwitcher extends StatelessWidget {
  final int selected;
  final List<int> counts;
  final ValueChanged<int> onSelect;

  const _PrayerSwitcher({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        for (var i = 0; i < _prayers.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == selected
                      ? AppColors.accent100
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Icon(
                      iconForPrayer(_prayers[i].$2),
                      size: 18,
                      color: i == selected
                          ? AppColors.accent700
                          : AppColors.text.withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nameForPrayer(t, _prayers[i].$2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: i == selected
                            ? AppColors.accent700
                            : AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${counts[i]}',
                      style: AppTextStyles.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: i == selected
                            ? AppColors.accent700.withValues(alpha: 0.75)
                            : AppColors.text.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final int lead;
  final ({DateTime start, DateTime end})? window;
  final bool offToday;
  final ValueNotifier<Object?> openTile;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleToday;

  const _ReminderTile({
    super.key,
    required this.lead,
    required this.window,
    required this.offToday,
    required this.openTile,
    required this.onTap,
    required this.onDelete,
    required this.onToggleToday,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final muted = AppColors.text.withValues(alpha: 0.55);
    final window = this.window;
    final fire = window?.end.subtract(Duration(minutes: lead));
    // The picker never allows a lead this long (see maxEndReminderLead),
    // but one set under another city's times could still be: it isn't
    // booked (see NotificationService.plan), so it shows no time either.
    final showsTime = window != null && !fire!.isBefore(window.start);
    final radius = BorderRadius.circular(AppRadius.md);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwipeActionTile(
        openTile: openTile,
        borderRadius: radius,
        onTap: onTap,
        actions: [
          SwipeAction(
            icon: Icons.delete_outline_rounded,
            label: t.endReminderDelete,
            color: _deleteColor,
            foreground: Colors.white,
            onPressed: onDelete,
          ),
          SwipeAction(
            icon: offToday ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
            label: offToday ? t.endReminderOnToday : t.endReminderOffToday,
            color: StatusColors.onTime,
            foreground: StatusColors.onOnTime,
            onPressed: onToggleToday,
          ),
        ],
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: offToday ? 0.55 : 1,
            child: Row(
              children: [
                IconBadge(
                  offToday ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                  size: 34,
                  iconSize: 17,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.endReminderLead(formatLeadTime(t, lead)),
                        style: AppTextStyles.body(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (offToday || showsTime) ...[
                        const SizedBox(height: 2),
                        Text(
                          offToday
                              ? t.endReminderOffTodayStatus
                              : t.endReminderAtShort(formatClock(fire!)),
                          style: AppTextStyles.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Picks a lead — how long before the prayer's end to remind — on two
/// wheels, hours and minutes, the way an alarm's time is set. The wheels
/// stop at [max] (see maxEndReminderLead) rather than offer a lead that
/// wouldn't fit. Resolves to the minutes chosen, or null when dismissed.
Future<int?> showLeadPicker(
  BuildContext context, {
  required int initial,
  required int max,
  ({DateTime start, DateTime end})? window,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _LeadPickerSheet(initial: initial, max: max, window: window),
  );
}

class _LeadPickerSheet extends StatefulWidget {
  final int initial;
  final int max;
  final ({DateTime start, DateTime end})? window;

  const _LeadPickerSheet({
    required this.initial,
    required this.max,
    required this.window,
  });

  @override
  State<_LeadPickerSheet> createState() => _LeadPickerSheetState();
}

class _LeadPickerSheetState extends State<_LeadPickerSheet> {
  static const _step = kEndReminderStep;
  static const _itemExtent = 44.0;

  late int _hours;
  late int _minutes;
  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;

  int get _max => widget.max;
  int get _maxHours => _max ~/ 60;
  int get _total => _hours * 60 + _minutes;

  @override
  void initState() {
    super.initState();
    final start = widget.initial.clamp(kMinEndReminderMinutes, _max);
    _hours = start ~/ 60;
    _minutes = start % 60 ~/ _step * _step;
    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(
      initialItem: _minutes ~/ _step,
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  /// How many minute values the wheel offers under [hours]: all of them,
  /// except in the last hour, where it stops at [_max].
  int _minuteCount(int hours) =>
      hours == _maxHours ? _max % 60 ~/ _step + 1 : 60 ~/ _step;

  void _onHours(int hours) {
    final last = _minuteCount(hours) - 1;
    setState(() {
      _hours = hours;
      if (_minutes ~/ _step > last) _minutes = last * _step;
    });
    // The minute wheel just got shorter under its current pick: moved to
    // its new last value once it has been rebuilt with that many.
    if (_minutesController.hasClients &&
        _minutesController.selectedItem > last) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_minutesController.hasClients) _minutesController.jumpToItem(last);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final muted = AppColors.text.withValues(alpha: 0.6);
    final valid = _total >= kMinEndReminderMinutes && _total <= _max;
    final window = widget.window;
    final fire = window?.end.subtract(Duration(minutes: _total));
    final wheelStyle = AppTextStyles.heading(fontSize: 24);
    final labelStyle = AppTextStyles.body(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.accent700,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Text(
            t.endRemindersName,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(fontSize: 18),
          ),
          const SizedBox(height: 4),
          // Says the wheels' value back as a sentence, as they turn.
          Text(
            t.endReminderPickerSummary(formatLeadTime(t, _total)),
            textAlign: TextAlign.center,
            style: AppTextStyles.body(fontSize: 13.5, color: muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _itemExtent * 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // One highlight across both wheels, so hours and minutes
                // read as a single value, the way an alarm's time does.
                Container(
                  height: _itemExtent,
                  decoration: BoxDecoration(
                    color: AppColors.accent100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // A prayer whose limit is under an hour has nothing for
                    // an hours wheel to offer.
                    if (_maxHours > 0) ...[
                      SizedBox(
                        width: 64,
                        child: _Wheel(
                          controller: _hoursController,
                          count: _maxHours + 1,
                          itemExtent: _itemExtent,
                          label: (i) => '$i',
                          style: wheelStyle,
                          onChanged: _onHours,
                        ),
                      ),
                      Text(t.wheelHoursLabel, style: labelStyle),
                      const SizedBox(width: 20),
                    ],
                    SizedBox(
                      width: 64,
                      child: _Wheel(
                        controller: _minutesController,
                        count: _minuteCount(_hours),
                        itemExtent: _itemExtent,
                        label: (i) => (i * _step).toString().padLeft(2, '0'),
                        style: wheelStyle,
                        onChanged: (i) => setState(() => _minutes = i * _step),
                      ),
                    ),
                    Text(t.wheelMinutesLabel, style: labelStyle),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Kept at a fixed height so the button below doesn't jump while
          // the wheels pass through a value that can't be saved.
          SizedBox(
            height: 20,
            child: valid && fire != null
                ? Text(
                    t.endReminderAt(formatClock(fire)),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          PillButton(
            label: t.endReminderSave,
            onTap: valid ? () => Navigator.of(context).pop(_total) : null,
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int count;
  final double itemExtent;
  final String Function(int index) label;
  final TextStyle style;
  final ValueChanged<int> onChanged;

  const _Wheel({
    required this.controller,
    required this.count,
    required this.itemExtent,
    required this.label,
    required this.style,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: itemExtent,
      // The shared highlight behind both wheels stands in for this.
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onChanged,
      children: [
        for (var i = 0; i < count; i++)
          Center(child: Text(label(i), style: style)),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
