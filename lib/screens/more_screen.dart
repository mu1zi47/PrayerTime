import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'names_screen.dart';
import 'prayer_log_screen.dart';

class _MoreItemSpec {
  final IconData icon;
  final String label;
  final WidgetBuilder screenBuilder;

  const _MoreItemSpec({required this.icon, required this.label, required this.screenBuilder});
}

List<_MoreItemSpec> _items(AppState appState, AppLocalizations t) => [
      _MoreItemSpec(
        icon: Icons.auto_awesome_rounded,
        label: t.allahNamesTitle,
        screenBuilder: (_) => NamesScreen(appState: appState),
      ),
      _MoreItemSpec(
        icon: Icons.checklist_rounded,
        label: t.myPrayersTitle,
        screenBuilder: (_) => PrayerLogScreen(appState: appState),
      ),
    ];

class MoreScreen extends StatelessWidget {
  final AppState appState;

  const MoreScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: the title and grid
    // should scroll edge-to-edge, under the transparent status bar, rather
    // than stop short of it. CustomScrollView (instead of ListView) so the
    // title and the grid share one scroll position.
    final t = AppLocalizations.of(context)!;
    final topInset = MediaQuery.paddingOf(context).top;
    final items = _items(appState, t);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 16),
          sliver: SliverToBoxAdapter(
            child: Text(t.navMore, style: AppTextStyles.heading(fontSize: 22)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _MoreTile(spec: items[i]),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final _MoreItemSpec spec;

  const _MoreTile({required this.spec});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: spec.screenBuilder)),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.accent100, shape: BoxShape.circle),
              child: Icon(spec.icon, size: 19, color: AppColors.accent700),
            ),
            Text(spec.label, style: AppTextStyles.heading(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
