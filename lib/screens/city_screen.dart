import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../widgets/icon_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_toast.dart';
import '../widgets/edge_gesture_guard.dart';
import '../widgets/screen_back_button.dart';

const _searchBarReserve = 76.0;

class CityScreen extends StatefulWidget {
  final AppState appState;

  const CityScreen({super.key, required this.appState});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final _searchController = TextEditingController();
  final _geocoding = GeocodingService();
  final _location = LocationService();

  String _query = '';
  Timer? _debounce;
  int _searchGeneration = 0;
  bool _searching = false;
  List<GeocodeResult> _onlineResults = [];

  bool _locating = false;
  String? _locationError;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _onlineResults = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(value));
  }

  Future<void> _search(String query) async {
    final t = AppLocalizations.of(context)!;
    final generation = ++_searchGeneration;
    setState(() => _searching = true);
    final results = await _geocoding.search(query, language: t.localeName);
    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _onlineResults = results;
      _searching = false;
    });
  }

  Future<void> _autoDetect() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final position = await _location.determinePosition();
      if (!mounted) return;

      final geocoded = await _geocoding.reverse(
        position.latitude,
        position.longitude,
        language: t.localeName,
      );
      if (!mounted) return;

      final city = City(
        id: City.customId(position.latitude, position.longitude),
        englishCity: geocoded?.city ?? t.cityCurrentLocation,
        englishCountry: geocoded?.country ?? '',
        latitude: position.latitude,
        longitude: position.longitude,
        timeZone: '',
        isCustom: true,
      );

      final applied = await widget.appState.selectCity(city);
      if (!mounted) return;
      if (applied) {
        Navigator.of(context).pop();
      } else {
        setState(() => _locating = false);
        AppToast.show(
          context,
          t.errorOfflineSettingsChange,
          icon: Icons.wifi_off_rounded,
        );
      }
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = switch (e.error) {
          LocationError.serviceDisabled => t.cityLocationServiceDisabled,
          LocationError.permissionDenied ||
          LocationError.permissionDeniedForever =>
            t.cityLocationPermissionDenied,
          LocationError.unknown => t.cityLocationErrorGeneric,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = t.cityLocationErrorGeneric;
      });
    }
  }

  Future<void> _selectCity(City city) async {
    final t = AppLocalizations.of(context)!;
    final applied = await widget.appState.selectCity(city);
    if (!mounted) return;
    if (applied) {
      Navigator.of(context).pop();
    } else {
      AppToast.show(
        context,
        t.errorOfflineSettingsChange,
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  void _selectOnlineResult(GeocodeResult result) {
    _selectCity(
      City(
        id: City.customId(result.latitude, result.longitude),
        englishCity: result.city,
        englishCountry: result.country,
        latitude: result.latitude,
        longitude: result.longitude,
        timeZone: '',
        isCustom: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cities = ReferenceData.cities
        .where(
          (c) => cityNameFor(t, c).toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final hasQuery = _query.trim().isNotEmpty;

    // No SafeArea — see HomeScreen's build() for why: content (including the
    // back button/title row) should scroll edge-to-edge, under the
    // transparent status/navigation bars, not stop short of them.
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    Text(
                      t.citySelectTitle,
                      style: AppTextStyles.heading(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _locating ? null : _autoDetect,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent100,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        // The badge is filled the other way round, since
                        // the button itself is already soft gold.
                        if (_locating)
                          Container(
                            width: 30,
                            height: 30,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.accent700,
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent100,
                            ),
                          )
                        else
                          IconBadge(
                            Icons.my_location_rounded,
                            size: 30,
                            iconSize: 16,
                            background: AppColors.accent700,
                            foreground: AppColors.accent100,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _locating ? t.cityAutoDetecting : t.cityAutoDetect,
                            style: AppTextStyles.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_locationError != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _locationError!,
                          style:
                              AppTextStyles.body(
                                fontSize: 12,
                                color: AppColors.text,
                              ).copyWith(
                                color: AppColors.text.withValues(alpha: 0.6),
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _location.openAppSettings(),
                        child: Text(
                          t.cityOpenSettingsButton,
                          style: AppTextStyles.body(
                            fontSize: 12,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                // Bottom is guarded here (scoped to just this scrolling
                // content, not the search bar below) so swipe-up-to-minimize
                // starting near the edge isn't read as list scrolling. No
                // left/right guard needed — this list has no horizontal
                // swipe to conflict with the OS back gesture, and a guard
                // here would only risk swallowing taps near the edges (see
                // RootShell's PageView for where left/right actually
                // matters).
                EdgeGestureGuard(
                  bottom: true,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      0,
                      18,
                      padding.bottom + _searchBarReserve,
                    ),
                    children: [
                      for (final c in cities)
                        _CityRow(
                          name: cityNameFor(t, c),
                          country: cityCountryFor(t, c),
                          selected: c.id == widget.appState.selectedCityId,
                          onTap: () => _selectCity(c),
                        ),
                      if (_onlineResults.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            t.cityOnlineResultsTitle,
                            style:
                                AppTextStyles.body(
                                  fontSize: 12,
                                  color: AppColors.text,
                                ).copyWith(
                                  color: AppColors.text.withValues(alpha: 0.55),
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final r in _onlineResults)
                          _CityRow(
                            name: r.city,
                            country: r.country,
                            selected:
                                City.customId(r.latitude, r.longitude) ==
                                widget.appState.selectedCityId,
                            onTap: () => _selectOnlineResult(r),
                          ),
                      ] else if (hasQuery && cities.isEmpty && !_searching)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            t.nothingFound,
                            textAlign: TextAlign.center,
                            style:
                                AppTextStyles.body(
                                  fontSize: 14,
                                  color: AppColors.text,
                                ).copyWith(
                                  color: AppColors.text.withValues(alpha: 0.55),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Floats at the bottom of the screen, same spot as
                // [FloatingTabBar] on the root tabs — this screen is pushed
                // on top of that shell, so nothing else needs the space.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 16),
                    child: _FloatingSearchBar(
                      controller: _searchController,
                      onChanged: _onQueryChanged,
                      searching: _searching,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool searching;

  const _FloatingSearchBar({
    required this.controller,
    required this.onChanged,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: AppColors.text.withValues(alpha: 0.6),
                ),
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
                      hintText: t.citySearchHint,
                      hintStyle: AppTextStyles.body(
                        fontSize: 13,
                        color: AppColors.text,
                      ).copyWith(color: AppColors.text.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                if (searching)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.text.withValues(alpha: 0.5),
                    ),
                  )
                else if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.text.withValues(alpha: 0.5),
                      ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 32,
              margin: const EdgeInsets.only(right: 11),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // The chosen city's badge is filled the other way round, so it
            // stands out from the rest of the list.
            IconBadge(
              Icons.location_on_rounded,
              size: 32,
              iconSize: 16,
              background: selected ? AppColors.accent700 : null,
              foreground: selected ? AppColors.accent100 : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.heading(
                      fontSize: 14,
                      color: selected ? AppColors.accent : AppColors.text,
                    ),
                  ),
                  Text(
                    country,
                    style: AppTextStyles.body(
                      fontSize: 11,
                      color: AppColors.text,
                    ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 16, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
