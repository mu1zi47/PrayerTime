import '../widgets/app_tap.dart';
import '../widgets/ambient_surface.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'mosque_map_screen.dart';
import 'names_screen.dart';
import 'tasbih_screen.dart';
import 'prayer_calendar_screen.dart';

class _MoreItemSpec {
  final IconData icon;
  final String label;
  final WidgetBuilder screenBuilder;

  const _MoreItemSpec({
    required this.icon,
    required this.label,
    required this.screenBuilder,
  });
}

List<_MoreItemSpec> _items(AppState appState, AppLocalizations t) => [
  _MoreItemSpec(
    icon: Icons.auto_awesome_rounded,
    label: t.allahNamesTitle,
    screenBuilder: (_) => NamesScreen(appState: appState),
  ),
  _MoreItemSpec(
    icon: Icons.calendar_month_rounded,
    label: t.calendarScreenTitle,
    screenBuilder: (_) => PrayerCalendarScreen(appState: appState),
  ),
  _MoreItemSpec(
    icon: Icons.mosque_rounded,
    label: t.mosqueMapTitle,
    screenBuilder: (_) => MosqueMapScreen(appState: appState),
  ),
  _MoreItemSpec(
    icon: Icons.touch_app_rounded,
    label: t.tasbihTitle,
    screenBuilder: (_) => const TasbihScreen(),
  ),
];

class MoreScreen extends StatelessWidget {
  final AppState appState;

  const MoreScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    // No SafeArea — see HomeScreen's build() for why: the title and grid
    // should scroll edge-to-edge, under the transparent status bar, rather
    // than stop short of it. CustomScrollView (instead of ListView) so the
    // title and the grid share one scroll position.
    final t = AppLocalizations.of(context)!;
    final topInset = MediaQuery.paddingOf(context).top;
    final items = _items(appState, t);
    return ScreenContentInset(
      margin: EdgeInsets.fromLTRB(18, topInset + 16, 18, 130),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                t.navMore,
                style: AppTextStyles.heading(fontSize: 22),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverToBoxAdapter(
              child: GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const PanelDivider(),
                      _MoreTile(spec: items[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final _MoreItemSpec spec;

  const _MoreTile({required this.spec});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AppTap(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: spec.screenBuilder)),

      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent100,
                shape: BoxShape.circle,
              ),
              child: Icon(spec.icon, size: 19, color: AppColors.accent700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                spec.label,
                style: AppTextStyles.heading(fontSize: 16),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.text.withValues(alpha: .4),
            ),
          ],
        ),
      ),
    );
  }
}
