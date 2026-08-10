import 'package:flutter/material.dart';

import '../data/allah_names.dart';
import '../l10n/app_localizations.dart';
import '../models/allah_name.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

class AllahNameDetailScreen extends StatefulWidget {
  final AllahName name;
  final AppState appState;

  const AllahNameDetailScreen({
    super.key,
    required this.name,
    required this.appState,
  });

  @override
  State<AllahNameDetailScreen> createState() => _AllahNameDetailScreenState();
}

class _AllahNameDetailScreenState extends State<AllahNameDetailScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = AllahNames.all.indexWhere((n) => n.number == widget.name.number);
    if (_index < 0) _index = 0;
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= AllahNames.all.length) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final name = AllahNames.all[_index];
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final t = AppLocalizations.of(context)!;
          final isFavorite = widget.appState.isFavoriteName(name.number);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              padding.top + 16,
              18,
              padding.bottom + 24,
            ),
            children: [
              Row(
                children: [
                  ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.allahNamesTitle,
                      style: AppTextStyles.heading(fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        widget.appState.toggleFavoriteName(name.number),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 20,
                        color: isFavorite ? AppColors.accent : AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -250) {
                        _step(1);
                      } else if (velocity > 250) {
                        _step(-1);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 44,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.bg.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${name.number}',
                              style: AppTextStyles.body(
                                fontSize: 13,
                                color: AppColors.bg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            name.arabic,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading(
                              fontSize: 40,
                              color: AppColors.bg,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name.transliteration,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading(
                              fontSize: 22,
                              color: AppColors.bg,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name.meaning,
                            textAlign: TextAlign.center,
                            style:
                                AppTextStyles.body(
                                  fontSize: 14,
                                  color: AppColors.bg,
                                ).copyWith(
                                  color: AppColors.bg.withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    child: _NavArrowButton(
                      icon: Icons.chevron_left_rounded,
                      enabled: _index > 0,
                      onTap: () => _step(-1),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    child: _NavArrowButton(
                      icon: Icons.chevron_right_rounded,
                      enabled: _index < AllahNames.all.length - 1,
                      onTap: () => _step(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.descriptionLabel,
                      style: AppTextStyles.heading(
                        fontSize: 15,
                      ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name.description,
                      style: AppTextStyles.body(
                        fontSize: 15,
                        color: AppColors.text,
                      ).copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: enabled ? 0.24 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: AppColors.bg.withValues(alpha: enabled ? 1 : 0.4),
        ),
      ),
    );
  }
}
