import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/notif_sound.dart';
import '../services/notification_sounds_bridge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/pill_button.dart';
import '../widgets/settings_widgets.dart';

/// The phone's sounds to pick the notifications' one from — its default
/// first, then its notification, ringtone and alarm sounds — each played on
/// a tap, the way the phone's own sound settings do. Resolves to the sound
/// picked, or null when dismissed.
Future<NotifSound?> showSoundPicker(
  BuildContext context, {
  required String title,
  required NotifSound current,
}) {
  return showModalBottomSheet<NotifSound>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    // A touch slower than the default and easing out, so the sheet glides
    // up rather than snaps — it's a tall one.
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (_) => _SoundPickerSheet(title: title, current: current),
  );
}

class _SoundPickerSheet extends StatefulWidget {
  final String title;
  final NotifSound current;

  const _SoundPickerSheet({required this.title, required this.current});

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  static const _bridge = NotificationSoundsBridge();

  late NotifSound _selected = widget.current;
  List<SystemSound>? _sounds;
  String? _defaultTitle;

  /// On the row picked when the sheet opened, so the list can glide there
  /// rather than leave it somewhere among a few dozen sounds.
  final _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bridge.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([_bridge.list(), _bridge.defaultTitle()]);
    if (!mounted) return;
    setState(() {
      _sounds = results[0] as List<SystemSound>;
      _defaultTitle = results[1] as String?;
    });
    if (widget.current.isDefault) return;
    // Once the rows have started coming in, not before — scrolling an
    // empty list would go nowhere.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final row = _currentKey.currentContext;
    if (!mounted || row == null || !row.mounted) return;
    Scrollable.ensureVisible(
      row,
      alignment: 0.35,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  void _select(NotifSound sound) {
    setState(() => _selected = sound);
    _bridge.play(sound.uri);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sounds = _sounds;

    // A fixed height from the first frame: the sheet slides up already the
    // size it will be, rather than growing again once the sounds arrive.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: sounds == null
                    ? Center(
                        key: const ValueKey('loading'),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : SingleChildScrollView(
                        key: const ValueKey('sounds'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _rows(t, sounds),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: t.soundPickerDone,
              onTap: () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _rows(AppLocalizations t, List<SystemSound> sounds) {
    var index = 0;
    Widget enter(Widget child) => _Entrance(index: index++, child: child);

    Widget row(NotifSound sound, String label, {String? detail}) => enter(
      _PickerRow(
        key: sound == widget.current ? _currentKey : null,
        label: label,
        detail: detail,
        selected: sound == _selected,
        onTap: () => _select(sound),
      ),
    );

    return [
      row(
        const NotifSound.phoneDefault(),
        t.soundDefault,
        detail: _defaultTitle,
      ),
      if (sounds.isEmpty)
        enter(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              t.soundListUnavailable,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                fontSize: 13.5,
                color: AppColors.text.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      for (final kind in SystemSoundKind.values)
        if (sounds.any((s) => s.kind == kind)) ...[
          enter(
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SectionKicker(switch (kind) {
                SystemSoundKind.notification => t.soundKindNotification,
                SystemSoundKind.ringtone => t.soundKindRingtone,
                SystemSoundKind.alarm => t.soundKindAlarm,
              }),
            ),
          ),
          for (final sound in sounds.where((s) => s.kind == kind))
            row(NotifSound(uri: sound.uri, title: sound.title), sound.title),
        ],
    ];
  }
}

/// Fades a row in and lifts it into place, each one a beat after the one
/// above — the list arrives as a cascade rather than all at once. Only the
/// first rows are staggered; the rest are off screen by then and simply
/// come in with the last of them.
class _Entrance extends StatefulWidget {
  final int index;
  final Widget child;

  const _Entrance({required this.index, required this.child});

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  static const _staggered = 14;
  static const _step = Duration(milliseconds: 28);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = _step * widget.index.clamp(0, _staggered);
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

/// A sound in the picker, styled like the app's other pickers (see
/// ChoiceSheet): the chosen one filled soft gold with a check, the change
/// between them eased rather than switched.
class _PickerRow extends StatelessWidget {
  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  const _PickerRow({
    super.key,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.accent700 : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent100 : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              // The note turns into a speaker on the one playing, with a
              // small pop.
              AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  selected ? Icons.volume_up_rounded : Icons.music_note_rounded,
                  key: ValueKey(selected),
                  size: 18,
                  color: selected
                      ? AppColors.accent700
                      : AppColors.text.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: _duration,
                      style: AppTextStyles.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                      child: Text(label),
                    ),
                    if (detail != null)
                      AnimatedDefaultTextStyle(
                        duration: _duration,
                        style: AppTextStyles.body(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: fg.withValues(alpha: 0.6),
                        ),
                        child: Text(detail!),
                      ),
                  ],
                ),
              ),
              AnimatedScale(
                duration: _duration,
                curve: selected ? Curves.easeOutBack : Curves.easeInCubic,
                scale: selected ? 1 : 0,
                child: Icon(
                  Icons.check_rounded,
                  size: 19,
                  color: AppColors.accent700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
