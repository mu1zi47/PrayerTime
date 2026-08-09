import 'package:flutter/material.dart';

import '../data/allah_names.dart';
import '../models/allah_name.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

/// Allah and the 99 names (Asma-ul-Husna), pushed from [MoreScreen].
class NamesScreen extends StatelessWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content (including
    // the back button/title row) should scroll edge-to-edge, under the
    // transparent status/navigation bars, not stop short of them.
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, padding.bottom + 18),
        children: [
          Row(
            children: [
              ScreenBackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Text('Имена Аллаха', style: AppTextStyles.heading(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Аль-Асма уль-Хусна',
              style: AppTextStyles.body(fontSize: 13, color: AppColors.text).copyWith(
                color: AppColors.text.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final name in AllahNames.all) _NameRow(name: name),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  final AllahName name;

  const _NameRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.accent100, shape: BoxShape.circle),
            child: Text(
              '${name.number}',
              style: AppTextStyles.body(fontSize: 12, color: AppColors.accent700, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.transliteration, style: AppTextStyles.heading(fontSize: 14)),
                Text(
                  name.meaning,
                  style: AppTextStyles.body(fontSize: 12, color: AppColors.text).copyWith(
                    color: AppColors.text.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name.arabic,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.heading(fontSize: 18, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
