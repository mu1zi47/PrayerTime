import '../widgets/app_tap.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/ambient_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/tasbih_counter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  TasbihCounter? _counter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final counter = await TasbihCounter.load();
    if (!mounted) {
      counter.dispose();
      return;
    }
    counter.addListener(_changed);
    setState(() => _counter = counter);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _counter?.removeListener(_changed);
    _counter?.dispose();
    super.dispose();
  }

  Future<void> _clear() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ClearTasbihSheet(),
    );
    if (mounted && confirmed == true) _counter?.clear();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final counter = _counter;
    return AmbientScaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ScreenContentInset(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  children: [
                    ScreenBackButton(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Text(
                      t.tasbihTitle,
                      style: AppTextStyles.heading(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                if (counter == null)
                  const Padding(
                    padding: EdgeInsets.all(64),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: glassDecoration(radius: AppRadius.md),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final limits = [33, 99, 0];
                          final selected = limits.indexOf(counter.limit);
                          return Stack(
                            children: [
                              AnimatedPositionedDirectional(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                start: selected * constraints.maxWidth / 3,
                                top: 0,
                                bottom: 0,
                                width: constraints.maxWidth / 3,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.selectionGradient,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (final limit in limits)
                                    Expanded(
                                      child: Semantics(
                                        selected: counter.limit == limit,
                                        button: true,
                                        child: AppTap(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => counter.setLimit(limit),
                                          child: Padding(
                                            key: ValueKey('tasbih-mode-$limit'),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              style: AppTextStyles.body(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: counter.limit == limit
                                                    ? AppColors.onControlFill
                                                    : AppColors.text.withValues(
                                                        alpha: 0.5,
                                                      ),
                                              ),
                                              child: Text(
                                                limit == 0
                                                    ? t.tasbihUnlimited
                                                    : '$limit',
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 270),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Semantics(
                          button: true,
                          label: t.tasbihTapHint,
                          value: '${counter.current}',
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _AnimatedTasbihRing(
                                current: counter.current,
                                total: counter.total,
                                limit: counter.limit,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Material(
                                  color: AppColors.surface,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    key: const ValueKey('tasbih-tap'),
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      counter.increment();
                                      if (counter.limit != 0 &&
                                          counter.current == 0) {
                                        HapticFeedback.mediumImpact();
                                      } else {
                                        HapticFeedback.selectionClick();
                                      }
                                    },
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _AnimatedCount(
                                          value: counter.current,
                                          textKey: const ValueKey(
                                            'tasbih-current',
                                          ),
                                          style: AppTextStyles.heading(
                                            fontSize: 64,
                                            color: AppColors.accent700,
                                          ),
                                        ),
                                        AnimatedSize(
                                          duration: const Duration(
                                            milliseconds: 240,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: counter.limit == 0
                                                ? const SizedBox.shrink(
                                                    key: ValueKey(0),
                                                  )
                                                : Text(
                                                    '/ ${counter.limit}',
                                                    key: ValueKey(
                                                      counter.limit,
                                                    ),
                                                    style: AppTextStyles.body(
                                                      fontSize: 16,
                                                      color: AppColors.text
                                                          .withValues(
                                                            alpha: 0.45,
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.tasbihTapHint,
                    style: AppTextStyles.body(
                      fontSize: 13,
                      color: AppColors.text.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    t.tasbihTotal,
                    style: AppTextStyles.body(
                      fontSize: 13,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _AnimatedCount(
                    value: counter.total,
                    textKey: const ValueKey('tasbih-total'),
                    style: AppTextStyles.heading(fontSize: 28),
                  ),
                  const SizedBox(height: 28),
                  TextButton.icon(
                    onPressed: counter.total == 0 ? null : _clear,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(t.tasbihClear),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearTasbihSheet extends StatelessWidget {
  const _ClearTasbihSheet();

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                t.tasbihClearTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                t.tasbihClearBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              ActionGroup(
                children: [
                  OptRow(
                    onTap: () => Navigator.pop(context, true),
                    child: Text(
                      t.tasbihClear,
                      style: AppTextStyles.body(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OptRow(
                    onTap: () => Navigator.pop(context, false),
                    child: Text(t.tasbihCancel, style: AppTextStyles.body()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCount extends StatelessWidget {
  final int value;
  final Key textKey;
  final TextStyle style;

  const _AnimatedCount({
    required this.value,
    required this.textKey,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    builder: (context, number, _) =>
        Text('${number.round()}', key: textKey, style: style),
  );
}

class _AnimatedTasbihRing extends StatefulWidget {
  final int current;
  final int total;
  final int limit;

  const _AnimatedTasbihRing({
    required this.current,
    required this.total,
    required this.limit,
  });

  @override
  State<_AnimatedTasbihRing> createState() => _AnimatedTasbihRingState();
}

class _AnimatedTasbihRingState extends State<_AnimatedTasbihRing> {
  late int _steps = widget.current;
  double get _progress => widget.limit == 0 ? 0 : _steps / widget.limit;

  @override
  void didUpdateWidget(_AnimatedTasbihRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.limit == 0) {
      _steps = 0;
    } else if (oldWidget.limit == widget.limit &&
        widget.total > oldWidget.total) {
      // Animate forward through a completed round, then wrap to zero.
      _steps += widget.total - oldWidget.total;
    } else if (oldWidget.limit != widget.limit ||
        widget.total < oldWidget.total) {
      _steps = widget.current;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AnimatedOpacity(
      opacity: widget.limit == 0 ? 0 : 1,
      duration: const Duration(milliseconds: 220),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _progress),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CircularProgressIndicator(
          value: value % 1,
          strokeWidth: 4,
          strokeCap: StrokeCap.round,
          color: AppColors.accent,
          backgroundColor: AppColors.accent100,
        ),
      ),
    );
  }
}
