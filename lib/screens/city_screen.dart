import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';

class CityScreen extends StatefulWidget {
  final AppState appState;

  const CityScreen({super.key, required this.appState});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cities = ReferenceData.cities
        .where((c) => cityNameFor(t, c.id).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status/navigation bars.
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
                Text(t.citySelectTitle, style: AppTextStyles.heading(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 16, color: AppColors.text.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: AppTextStyles.body(fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: t.citySearchHint,
                        hintStyle: AppTextStyles.body(fontSize: 14, color: AppColors.text).copyWith(
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // "Определить автоматически" — no location permission/geolocation
            // wiring yet; hidden for now rather than removed outright.
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            //   decoration: BoxDecoration(
            //     color: AppColors.accent2_100,
            //     borderRadius: BorderRadius.circular(AppRadius.md),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(Icons.my_location_rounded, size: 18, color: AppColors.accent2_800),
            //       const SizedBox(width: 10),
            //       Text(
            //         t.cityAutoDetect,
            //         style: AppTextStyles.body(fontSize: 15, color: AppColors.accent2_800),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 8),
            for (final c in cities)
              _CityRow(
                name: cityNameFor(t, c.id),
                country: cityCountryFor(t, c.id),
                selected: c.id == widget.appState.selectedCityId,
                onTap: () {
                  widget.appState.selectCity(c.id);
                  Navigator.of(context).pop();
                },
              ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  final String name;
  final String country;
  final bool selected;
  final VoidCallback onTap;

  const _CityRow({
    required this.name,
    required this.country,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent100 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
              child: Icon(Icons.location_on_rounded, size: 15, color: AppColors.text),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.heading(fontSize: 14)),
                  Text(
                    country,
                    style: AppTextStyles.body(fontSize: 11, color: AppColors.text).copyWith(
                      color: AppColors.text.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
