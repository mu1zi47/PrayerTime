import '../widgets/app_modal_sheet.dart';
import '../widgets/ambient_surface.dart';
import '../widgets/app_tap.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/notif_sound.dart';
import '../services/notification_sounds_bridge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
  return showAppModalBottomSheet<NotifSound>(
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

  late final _selected = ValueNotifier<NotifSound>(widget.current);
  final _scroll = ScrollController();
  double? _selectedOffset;
  Object? _metricsKey;
  _SoundMetrics? _metrics;
  List<SystemSound>? _sounds;
  String? _defaultTitle;

  /// On the row picked when the sheet opened, so the list can glide there
  /// rather than leave it somewhere among a few dozen sounds.

  @override
  void initState() {
    super.initState();
    // Paint the sheet and its loading indicator before asking Android for
    // the sound catalogue.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _bridge.stop();
    _scroll.dispose();
    _selected.dispose();
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
    if (!mounted || !_scroll.hasClients || _selectedOffset == null) return;
    _scroll.animateTo(
      (_selectedOffset! - _scroll.position.viewportDimension * .35).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  void _select(NotifSound sound) {
    _selected.value = sound;
    _bridge.play(sound.uri);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sounds = _sounds;

    // A fixed height from the first frame: the sheet slides up already the
    // size it will be, rather than growing again once the sounds arrive.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 16),
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
                layoutBuilder: (current, previous) =>
                    current ?? const SizedBox.shrink(),
                transitionBuilder: (child, animation) =>
                    child.key == const ValueKey('loading')
                    ? FadeTransition(opacity: animation, child: child)
                    : SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(0, .025),
                            end: Offset.zero,
                          ),
                        ),
                        child: child,
                      ),
                child: sounds == null
                    ? Center(
                        key: const ValueKey('loading'),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: LayoutBuilder(
                          builder: (context, constraints) => _soundList(
                            context,
                            t,
                            sounds,
                            constraints.maxWidth,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            ActionGroup(
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).pop(_selected.value),
                  child: Text(
                    t.soundPickerDone,
                    style: AppTextStyles.body(
                      fontSize: 15,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _soundList(
    BuildContext context,
    AppLocalizations t,
    List<SystemSound> sounds,
    double width,
  ) {
    final key = (
      width,
      MediaQuery.textScalerOf(context),
      t.localeName,
      _defaultTitle,
    );
    if (key != _metricsKey) {
      _metricsKey = key;
      _metrics = _SoundMetrics(context, width, t, _defaultTitle != null);
    }
    final metrics = _metrics!;
    double offset = metrics.defaultHeight;
    _selectedOffset = widget.current.isDefault ? 0 : null;
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: ActionGroup(
          children: [
            SizedBox(
              height: metrics.defaultHeight,
              child: _row(
                const NotifSound.phoneDefault(),
                t.soundDefault,
                detail: _defaultTitle,
              ),
            ),
          ],
        ),
      ),
      if (sounds.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: Text(t.soundListUnavailable)),
        ),
    ];
    for (final kind in SystemSoundKind.values) {
      final section = sounds.where((s) => s.kind == kind).toList();
      if (section.isEmpty) continue;
      final title = switch (kind) {
        SystemSoundKind.notification => t.soundKindNotification,
        SystemSoundKind.ringtone => t.soundKindRingtone,
        SystemSoundKind.alarm => t.soundKindAlarm,
      };
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SectionKicker(title),
          ),
        ),
      );
      offset += metrics.headerHeight(title);
      final selectedIndex = section.indexWhere(
        (sound) => sound.uri == widget.current.uri,
      );
      if (selectedIndex >= 0) {
        _selectedOffset = offset + selectedIndex * metrics.rowExtent;
      }
      slivers.add(
        DecoratedSliver(
          decoration: glassDecoration().copyWith(
            border: Border.fromBorderSide(BorderSide.none),
            boxShadow: const [],
          ),
          sliver: DecoratedSliver(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.text.withValues(alpha: .08)),
            ),
            sliver: SliverFixedExtentList(
              itemExtent: metrics.rowExtent,
              delegate: SliverChildBuilderDelegate((context, index) {
                final sound = section[index];
                final radius = BorderRadius.vertical(
                  top: index == 0
                      ? const Radius.circular(AppRadius.lg)
                      : Radius.zero,
                  bottom: index == section.length - 1
                      ? const Radius.circular(AppRadius.lg)
                      : Radius.zero,
                );
                return ClipRRect(
                  borderRadius: radius,
                  child: Column(
                    children: [
                      Expanded(
                        child: _row(
                          NotifSound(uri: sound.uri, title: sound.title),
                          sound.title,
                        ),
                      ),
                      if (index < section.length - 1)
                        const PanelDivider()
                      else
                        const SizedBox(height: 1),
                    ],
                  ),
                );
              }, childCount: section.length),
            ),
          ),
        ),
      );
      offset += section.length * metrics.rowExtent;
    }
    return CustomScrollView(
      key: const ValueKey('sounds'),
      controller: _scroll,
      slivers: slivers,
    );
  }

  Widget _row(NotifSound sound, String label, {String? detail}) =>
      ValueListenableBuilder<NotifSound>(
        valueListenable: _selected,
        builder: (context, selected, _) => _PickerRow(
          label: label,
          detail: detail,
          selected: sound == selected,
          onTap: () => _select(sound),
        ),
      );
}

class _SoundMetrics {
  final BuildContext context;
  final double width;
  final Map<String, double> _headers = {};
  late final double rowExtent = 32 + _line(15, FontWeight.w700) + 1;
  late final double defaultHeight =
      rowExtent - 1 + (hasDetail ? _line(12.5, FontWeight.w500) : 0);
  final bool hasDetail;
  _SoundMetrics(this.context, this.width, AppLocalizations t, this.hasDetail);
  double _line(
    double size,
    FontWeight weight, {
    String text = ' ',
    double maxWidth = double.infinity,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(
          context,
        ).style.merge(AppTextStyles.body(fontSize: size, fontWeight: weight)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  double headerHeight(String title) => _headers.putIfAbsent(
    title,
    () => 16 + 8 + _line(13, FontWeight.w800, text: title, maxWidth: width - 2),
  );
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
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final fg = selected ? AppColors.accent700 : AppColors.text;
    return Padding(
      padding: EdgeInsets.zero,
      child: AppTap(
        feedbackOnChild: false,
        onTap: onTap,

        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.selectionGradient : null,
            borderRadius: BorderRadius.zero,
          ),
          child: AppPressContent(
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
                    selected
                        ? Icons.volume_up_rounded
                        : Icons.music_note_rounded,
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
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (detail != null)
                        AnimatedDefaultTextStyle(
                          duration: _duration,
                          style: AppTextStyles.body(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: fg.withValues(alpha: 0.6),
                          ),
                          child: Text(
                            detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
      ),
    );
  }
}
