import 'package:flutter/material.dart';

import '../models/app_locale.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

/// Language picker. Only persists the choice for now — see [AppLocale]'s
/// doc comment: none of the app's strings are translated yet, so picking
/// a language here doesn't change any visible text.
class LanguageScreen extends StatelessWidget {
  final AppState appState;

  const LanguageScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status/navigation bars.
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, padding.bottom + 18),
            children: [
              Row(
                children: [
                  ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text('Язык', style: AppTextStyles.heading(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 16),
              for (final locale in AppLocale.values)
                _LanguageRow(
                  locale: locale,
                  selected: locale == appState.locale,
                  onTap: () => appState.setLocale(locale),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLocale locale;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({required this.locale, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent100 : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(child: Text(locale.label, style: AppTextStyles.body(fontSize: 15))),
              if (selected) Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
