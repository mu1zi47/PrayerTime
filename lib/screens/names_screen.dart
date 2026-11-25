import '../theme/app_design_system.dart';
import '../widgets/app_modal_sheet.dart';
import '../widgets/icon_badge.dart';
import '../widgets/app_tap.dart';
import '../widgets/app_search_field.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/ambient_surface.dart';

import 'package:flutter/material.dart';

import '../data/allah_names.dart';
import '../l10n/app_localizations.dart';
import '../models/allah_name.dart';
import '../models/app_locale.dart';
import '../state/app_state.dart';
import '../widgets/edge_gesture_guard.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/segmented_control.dart';
import 'allah_name_detail_screen.dart';

class NamesScreen extends StatefulWidget {
  final AppState appState;

  const NamesScreen({super.key, required this.appState});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  int _tabIndex = 0;
  late final PageController _pageController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
    // Everyone gets the accuracy disclaimer. Anyone not reading in Uzbek
    // Cyrillic gets the language explanation on top of it, since the names
    // exist only in that script and the screen otherwise looks like it
    // ignored their choice.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showNotice();
    });
  }

  Future<void> _showNotice() {
    final t = AppLocalizations.of(context)!;
    final readsUzbek = widget.appState.locale == AppLocale.uzCyrillic;
    return showAppModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
        child: _NoticeSheet(
          icon: readsUzbek
              ? Icons.info_outline_rounded
              : Icons.translate_rounded,
          title: readsUzbek ? t.namesDisclaimerTitle : t.namesNoticeTitle,
          body: readsUzbek ? null : t.namesNoticeBody,
          disclaimer: t.namesNoticeDisclaimer,
          button: t.namesNoticeButton,
          onDismiss: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    setState(() => _tabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  List<AllahName> _filter(List<AllahName> source) {
    final query = _query.trim();
    if (query.isEmpty) return source;
    final lower = query.toLowerCase();
    return source
        .where(
          (n) =>
              n.number.toString().contains(query) ||
              n.transliteration.toLowerCase().contains(lower) ||
              n.arabic.contains(query) ||
              n.meaning.toLowerCase().contains(lower),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    // No SafeArea — see HomeScreen's build() for why: content (including
    // the back button/title row) should scroll edge-to-edge, under the
    // transparent status/navigation bars, not stop short of them.
    final padding = MediaQuery.paddingOf(context);
    return AmbientScaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final t = AppLocalizations.of(context)!;
          final favorites = widget.appState.favoriteNames;
          final allFiltered = _filter(AllahNames.all);
          final favoriteSource = AllahNames.all
              .where((n) => favorites.contains(n.number))
              .toList();
          final favFiltered = _filter(favoriteSource);
          final hasQuery = _query.trim().isNotEmpty;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  padding.top + AppSpacing.md,
                  AppSpacing.screen,
                  AppSpacing.none,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ScreenBackButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          t.allahNamesTitle,
                          style: AppTextStyles.heading(
                            fontSize: AppFontSize.heading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.micro),
                        child: Text(
                          t.allahNamesSubtitle,
                          style:
                              AppTextStyles.body(
                                fontSize: AppFontSize.small,
                                color: AppColors.text,
                              ).copyWith(
                                color: AppColors.text.withValues(alpha: 0.55),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedControl(
                        options: [
                          t.tabAll,
                          favorites.isEmpty
                              ? t.tabFavorites
                              : '${t.tabFavorites} (${favorites.length})',
                        ],
                        selectedIndex: _tabIndex,
                        onSelect: _goToTab,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: GlassPanel(
                    child: EdgeGestureGuard(
                      left: true,
                      right: true,
                      bottom: true,
                      child: AmbientPageMotion(
                        positions: const [
                          Alignment(-.6, .65),
                          Alignment(.8, -.2),
                        ],
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (i) => setState(() => _tabIndex = i),
                          children: [
                            RepaintBoundary(
                              child: _NamesList(
                                names: allFiltered,
                                navigationSource: AllahNames.all,
                                favorites: favorites,
                                appState: widget.appState,
                                bottomPadding: 0,
                                emptyMessage: hasQuery ? t.nothingFound : null,
                              ),
                            ),
                            RepaintBoundary(
                              child: _NamesList(
                                names: favFiltered,
                                // Back/Forward inside a name pushed from here
                                // stays within favorites — not the full list,
                                // and not narrowed further by any search text.
                                navigationSource: favoriteSource,
                                favorites: favorites,
                                appState: widget.appState,
                                bottomPadding: 0,
                                emptyMessage: favoriteSource.isEmpty
                                    ? t.favoritesEmpty
                                    : (hasQuery ? t.nothingFound : null),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppSearchField(
                  controller: _searchController,
                  hint: AppLocalizations.of(context)!.namesSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoticeSheet extends StatelessWidget {
  final IconData icon;
  final String title;

  /// The "why is this in Uzbek" explanation — null when the reader is
  /// already on Uzbek Cyrillic and only the disclaimer applies.
  final String? body;

  /// The names and their commentary were transcribed by hand, so this says
  /// plainly that mistakes are possible and points at where to report one.
  final String disclaimer;

  final String button;
  final VoidCallback onDismiss;

  const _NoticeSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.disclaimer,
    required this.button,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        bottomInset + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppSize.sheetHandleWidth,
              height: AppSize.sheetHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          Center(
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: iconBadgeDecoration(),
              child: Icon(
                icon,
                size: AppIconSize.action,
                color: AppColors.accent700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(fontSize: AppFontSize.title),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body!,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body(
                    fontSize: AppFontSize.body,
                    color: AppColors.text,
                  ).copyWith(
                    color: AppColors.text.withValues(alpha: 0.62),
                    height: 1.45,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: glassDecoration(radius: AppRadius.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: AppIconSize.small,
                  color: AppColors.accent700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    disclaimer,
                    style:
                        AppTextStyles.body(
                          fontSize: AppFontSize.small,
                          color: AppColors.text,
                        ).copyWith(
                          color: AppColors.text.withValues(alpha: 0.62),
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          ActionGroup(
            children: [
              OptRow(
                onTap: onDismiss,
                child: Text(
                  button,
                  style: AppTextStyles.body(
                    fontSize: AppFontSize.body,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NamesList extends StatelessWidget {
  final List<AllahName> names;
  final List<AllahName> navigationSource;
  final Set<int> favorites;
  final AppState appState;
  final double bottomPadding;
  final String? emptyMessage;

  const _NamesList({
    required this.names,
    required this.navigationSource,
    required this.favorites,
    required this.appState,
    required this.bottomPadding,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    if (names.isEmpty && emptyMessage != null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          bottomPadding,
        ),
        children: [
          Text(
            emptyMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              fontSize: AppFontSize.body,
              color: AppColors.text,
            ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottomPadding),
      itemCount: names.length,
      itemBuilder: (context, i) {
        final name = names[i];
        return Container(
          padding: EdgeInsets.zero,

          child: _NameRow(
            showDivider: i < names.length - 1,
            name: name,
            navigationSource: navigationSource,
            isFavorite: favorites.contains(name.number),
            onToggleFavorite: () => appState.toggleFavoriteName(name.number),
            appState: appState,
          ),
        );
      },
    );
  }
}

class _NameRow extends StatelessWidget {
  final bool showDivider;
  final AllahName name;
  final List<AllahName> navigationSource;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final AppState appState;

  const _NameRow({
    this.showDivider = true,
    required this.name,
    required this.navigationSource,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AppTap(
      feedbackOnChild: false,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AllahNameDetailScreen(
            name: name,
            names: navigationSource,
            appState: appState,
          ),
        ),
      ),
      child: PanelRow(
        showDivider: showDivider,
        child: AppPressContent(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              NumberBadge(
                name.number,
                size: AppIconSize.display,
                fontSize: AppFontSize.small,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.transliteration,
                      style: AppTextStyles.heading(fontSize: AppFontSize.body),
                    ),
                    Text(
                      name.meaning,
                      style: AppTextStyles.body(
                        fontSize: AppFontSize.small,
                        color: AppColors.text,
                      ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                name.arabic,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.heading(
                  fontSize: AppFontSize.title,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              AppTap(
                feedbackOnChild: false,
                onTap: onToggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.compact),
                  child: AppPressContent(
                    child: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: AppIconSize.action,
                      color: isFavorite
                          ? AppColors.accent
                          : AppColors.text.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
