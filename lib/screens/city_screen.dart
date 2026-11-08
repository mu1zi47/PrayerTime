import '../widgets/app_tap.dart';
import '../widgets/app_search_field.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/ambient_surface.dart';
import 'dart:async';

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
    _geocoding.close();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchGeneration++;
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
    AppColors.watch(context);
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
    return AmbientScaffold(
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
                ActionGroup(
                  children: [
                    OptRow(
                      onTap: _locating ? null : _autoDetect,
                      child: Row(
                        children: [
                          if (_locating) ...[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              _locating
                                  ? t.cityAutoDetecting
                                  : t.cityAutoDetect,
                              style: AppTextStyles.body(
                                fontSize: 15,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GlassPanel(
                child: EdgeGestureGuard(
                  bottom: true,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Column(
                        children: [
                          for (final c in cities)
                            _CityRow(
                              showDivider: c != cities.last,
                              name: cityNameFor(t, c),
                              country: cityCountryFor(t, c),
                              selected: c.id == widget.appState.selectedCityId,
                              onTap: () => _selectCity(c),
                            ),
                        ],
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
                            showDivider: r != _onlineResults.last,
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
              ),
            ),
          ),
          const SizedBox(height: 12),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 16),
            child: AppSearchField(
              controller: _searchController,
              hint: AppLocalizations.of(context)!.citySearchHint,
              onChanged: _onQueryChanged,
              loading: _searching,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  final bool showDivider;
  final String name;
  final String country;
  final bool selected;
  final VoidCallback onTap;

  const _CityRow({
    this.showDivider = true,
    required this.name,
    required this.country,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return AppTap(
      onTap: onTap,
      child: PanelRow(
        showDivider: showDivider,
        selected: selected,
        child: Row(
          children: [
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
