import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/allah_names.dart';
import '../l10n/app_localizations.dart';
import '../models/allah_name.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/segmented_control.dart';
import 'allah_name_detail_screen.dart';

const _searchBarReserve = 76.0;

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
  bool _searchVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    setState(() => _tabIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward && !_searchVisible) {
      setState(() => _searchVisible = true);
    } else if (notification.direction == ScrollDirection.reverse && _searchVisible) {
      setState(() => _searchVisible = false);
    }
    return false;
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
    // No SafeArea — see HomeScreen's build() for why: content (including
    // the back button/title row) should scroll edge-to-edge, under the
    // transparent status/navigation bars, not stop short of them.
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final t = AppLocalizations.of(context)!;
          final favorites = widget.appState.favoriteNames;
          final allFiltered = _filter(AllahNames.all);
          final favoriteSource = AllahNames.all.where((n) => favorites.contains(n.number)).toList();
          final favFiltered = _filter(favoriteSource);
          final hasQuery = _query.trim().isNotEmpty;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 12),
                        Text(t.allahNamesTitle, style: AppTextStyles.heading(fontSize: 22)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          t.allahNamesSubtitle,
                          style: AppTextStyles.body(fontSize: 13, color: AppColors.text).copyWith(
                            color: AppColors.text.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedControl(
                      options: [t.tabAll, t.tabFavorites],
                      selectedIndex: _tabIndex,
                      onSelect: _goToTab,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    NotificationListener<UserScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _tabIndex = i),
                        children: [
                          _NamesList(
                            names: allFiltered,
                            favorites: favorites,
                            appState: widget.appState,
                            bottomPadding: padding.bottom + _searchBarReserve,
                            emptyMessage: hasQuery ? t.nothingFound : null,
                          ),
                          _NamesList(
                            names: favFiltered,
                            favorites: favorites,
                            appState: widget.appState,
                            bottomPadding: padding.bottom + _searchBarReserve,
                            emptyMessage: favoriteSource.isEmpty
                                ? t.favoritesEmpty
                                : (hasQuery ? t.nothingFound : null),
                          ),
                        ],
                      ),
                    ),
                    // Floats at the bottom of the screen, same spot as
                    // [FloatingTabBar] on the root tabs — this screen is
                    // pushed on top of that shell, so nothing else needs
                    // the space.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: 16),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          offset: _searchVisible ? Offset.zero : const Offset(0, 1.4),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            opacity: _searchVisible ? 1 : 0,
                            child: _FloatingSearchBar(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ),
                      ),
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

class _FloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _FloatingSearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neutral900.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 17, color: AppColors.text.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: AppTextStyles.body(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: t.namesSearchHint,
                      hintStyle: AppTextStyles.body(fontSize: 13, color: AppColors.text).copyWith(
                        color: AppColors.text.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.close_rounded, size: 16, color: AppColors.text.withValues(alpha: 0.5)),
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

class _NamesList extends StatelessWidget {
  final List<AllahName> names;
  final Set<int> favorites;
  final AppState appState;
  final double bottomPadding;
  final String? emptyMessage;

  const _NamesList({
    required this.names,
    required this.favorites,
    required this.appState,
    required this.bottomPadding,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty && emptyMessage != null) {
      return ListView(
        padding: EdgeInsets.fromLTRB(18, 24, 18, bottomPadding),
        children: [
          Text(
            emptyMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(fontSize: 14, color: AppColors.text).copyWith(
              color: AppColors.text.withValues(alpha: 0.55),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPadding),
      children: [
        for (final name in names)
          _NameRow(
            name: name,
            isFavorite: favorites.contains(name.number),
            onToggleFavorite: () => appState.toggleFavoriteName(name.number),
            appState: appState,
          ),
      ],
    );
  }
}

class _NameRow extends StatelessWidget {
  final AllahName name;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final AppState appState;

  const _NameRow({
    required this.name,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AllahNameDetailScreen(name: name, appState: appState)),
      ),
      child: Container(
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
            const SizedBox(width: 8),
            Text(
              name.arabic,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.heading(fontSize: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onToggleFavorite,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 22,
                  color: isFavorite ? AppColors.accent : AppColors.text.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
