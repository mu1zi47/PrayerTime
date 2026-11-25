import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/nearest_mosque.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../screens/mosque_map_screen.dart';
import '../services/location_service.dart';
import '../services/nearby_mosque_service.dart';
import '../state/app_state.dart';
import '../theme/app_design_system.dart';
import 'ambient_surface.dart';
import 'app_tap.dart';
import 'mosque_tiles.dart';
import 'pill_button.dart';

class NearbyMosqueCard extends StatefulWidget {
  const NearbyMosqueCard({
    super.key,
    required this.appState,
    this.location,
    this.mosques,
  });

  final AppState appState;
  final LocationService? location;
  final NearbyMosqueService? mosques;

  @override
  State<NearbyMosqueCard> createState() => _NearbyMosqueCardState();
}

class _NearbyMosqueCardState extends State<NearbyMosqueCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final _location = widget.location ?? LocationService();
  late final _mosques = widget.mosques ?? NearbyMosqueService();
  late final AppLifecycleListener _lifecycle;
  LatLng? _position;
  NearbyMosque? _nearest;
  LocationError? _locationError;
  bool _approximate = false;
  bool _loading = false;
  bool _lookupFailed = false;
  bool _tilesReady = false;
  bool _tilesFailed = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => _load());
    unawaited(_load());
  }

  Future<void> _load({bool requestPermission = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _locationError = null;
      _lookupFailed = false;
    });
    try {
      final fix = await _location.mapPosition(
        requestPermission: requestPermission,
      );
      if (!mounted) return;
      if (fix == null) {
        setState(() {
          _position = null;
          _nearest = null;
        });
        return;
      }
      final point = LatLng(fix.latitude, fix.longitude);
      try {
        final nearest = await _mosques.find(point);
        if (!mounted) return;
        final changedArea =
            _position == null ||
            const Distance().as(LengthUnit.Meter, _position!, point) > 100 ||
            _nearest?.mosque.id != nearest?.mosque.id;
        setState(() {
          _position = point;
          _nearest = nearest;
          _approximate = fix.accuracy > 150;
          if (changedArea) {
            _tilesReady = false;
            _tilesFailed = false;
          }
        });
      } catch (_) {
        if (mounted) setState(() => _lookupFailed = true);
      }
    } on LocationException catch (error) {
      if (mounted) {
        setState(() {
          _locationError = error.error;
          _position = null;
          _nearest = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _position = null;
          _nearest = null;
          if (requestPermission) _locationError = LocationError.unknown;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestLocation() async {
    if (_locationError == LocationError.permissionDeniedForever) {
      await _location.openAppSettings();
    } else if (_locationError == LocationError.serviceDisabled) {
      await _location.openLocationSettings();
    } else {
      await _load(requestPermission: true);
    }
  }

  void _openMap() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MosqueMapScreen(
          appState: widget.appState,
          initialPosition: _position,
          initialMosque: _nearest?.mosque,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _mosques.cancel();
    super.dispose();
  }

  String _distance(AppLocalizations t, double meters) {
    final distance = meters < 1000
        ? t.mosqueDistanceMeters('${(meters / 10).round() * 10}')
        : t.mosqueDistanceKm(
            NumberFormat('0.0', t.localeName).format(meters / 1000),
          );
    return t.mosquePreviewDistance(distance);
  }

  String _mosqueName(AppLocalizations t, NearbyMosque nearest) {
    final language = switch (widget.appState.locale) {
      AppLocale.ru => 'ru',
      AppLocale.en => 'en',
      AppLocale.uzLatin => 'uz',
      AppLocale.uzCyrillic => 'uz-Cyrl',
    };
    return nearest.mosque.localizedName(language) ?? t.mosqueUnnamed;
  }

  double get _textScale =>
      MediaQuery.textScalerOf(context).scale(AppFontSize.small) /
      AppFontSize.small;
  double _cardWidth = 360;
  double get _previewHeight {
    final t = AppLocalizations.of(context)!;
    double height(String text, double width) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: AppTextStyles.body(
            fontSize: AppFontSize.small,
          ).copyWith(height: 1.4),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: math.max(1, width));
      final result = painter.height;
      painter.dispose();
      return result;
    }

    final body =
        [
              t.mosquePreviewLoadingHint,
              t.mosqueLoadError,
              t.mosquePreviewEmpty,
              t.cityLocationServiceDisabled,
              t.mosquePreviewPermissionSettings,
              t.mosquePreviewLocationHint,
              t.cityLocationErrorGeneric,
            ]
            .map((text) => height(text, _cardWidth - AppSpacing.md * 2))
            .reduce(math.max);
    final button =
        [
              t.cityOpenSettingsButton,
              t.mosquePreviewEnable,
              t.retryButton,
              t.mosquePreviewSearching,
            ]
            .map(
              (text) => height(
                text,
                _cardWidth -
                    AppSpacing.md * 4 -
                    AppIconSize.small -
                    AppSpacing.xs,
              ),
            )
            .reduce(math.max);
    return math.max(
      AppSize.mapPreview * math.max(1, _textScale),
      body +
          AppSpacing.micro +
          MediaQuery.textScalerOf(context).scale(AppFontSize.small) * 1.4 +
          math.max(AppSize.touchTarget, button + AppSpacing.xs * 2) +
          AppSpacing.xs +
          AppSpacing.sm +
          AppSpacing.lg,
    );
  }

  double get _footerHeight =>
      (AppSize.nearbyCard - AppSize.mapPreview) *
      (_textScale < 1 ? 1 : _textScale);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    final point = _position;
    final nearest = _nearest;

    return LayoutBuilder(
      builder: (context, constraints) {
        _cardWidth = constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: GlassPanel(
            child: point == null || nearest == null
                ? _locationPrompt(t)
                : AppTap(
                    feedbackOnChild: false,
                    behavior: HitTestBehavior.opaque,
                    onTap: _openMap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _map(point, nearest, t),
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: _footerHeight),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _mosqueName(t, nearest),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.heading(
                                          fontSize: AppFontSize.body,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        _distance(t, nearest.meters),
                                        style: AppTextStyles.body(
                                          fontSize: AppFontSize.small,
                                          color: AppColors.text.withValues(
                                            alpha: AppOpacity.secondary,
                                          ),
                                        ),
                                      ),

                                      if (_approximate)
                                        Text(
                                          t.mosquePreviewApproximate,
                                          style: AppTextStyles.body(
                                            fontSize: AppFontSize.small,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.accent,
                                  size: AppIconSize.medium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _tilesLoaded(LatLng point, String? mosqueId) {
    if (!mounted ||
        _tilesReady ||
        point != _position ||
        mosqueId != _nearest?.mosque.id) {
      return;
    }
    setState(() {
      _tilesReady = true;
      _tilesFailed = false;
    });
  }

  void _tilesError(LatLng point, String? mosqueId) {
    if (!mounted ||
        _tilesReady ||
        _tilesFailed ||
        point != _position ||
        mosqueId != _nearest?.mosque.id) {
      return;
    }
    setState(() => _tilesFailed = true);
  }

  Widget _locationPrompt(AppLocalizations t) {
    final String explanation;
    if (_loading) {
      explanation = t.mosquePreviewLoadingHint;
    } else if (_lookupFailed) {
      explanation = t.mosqueLoadError;
    } else if (_position != null) {
      explanation = t.mosquePreviewEmpty;
    } else {
      explanation = switch (_locationError) {
        LocationError.serviceDisabled => t.cityLocationServiceDisabled,
        LocationError.permissionDeniedForever =>
          t.mosquePreviewPermissionSettings,
        LocationError.permissionDenied => t.mosquePreviewLocationHint,
        LocationError.unknown => t.cityLocationErrorGeneric,
        null => t.mosquePreviewLocationHint,
      };
    }

    final openSettings =
        _locationError == LocationError.permissionDeniedForever ||
        _locationError == LocationError.serviceDisabled;
    final label = openSettings
        ? t.cityOpenSettingsButton
        : _lookupFailed ||
              _position != null ||
              _locationError == LocationError.unknown
        ? t.retryButton
        : t.mosquePreviewEnable;
    final muted = AppColors.text.withValues(alpha: AppOpacity.secondary);

    final city = widget.appState.selectedCity;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _previewHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: AppSpacing.compact,
                      sigmaY: AppSpacing.compact,
                    ),
                    child: FlutterMap(
                      key: ValueKey(('location-preview', city.id)),
                      options: MapOptions(
                        initialCenter: LatLng(city.latitude, city.longitude),
                        initialZoom: 13,
                        backgroundColor: AppColors.surface,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: const [MosqueTiles()],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.bg.withValues(alpha: AppOpacity.secondary),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          explanation,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                            fontSize: AppFontSize.small,
                          ).copyWith(height: 1.4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      PillButton(
                        key: const ValueKey('nearby-mosque-enable-location'),
                        label: _loading ? t.mosquePreviewSearching : label,
                        loading: _loading,
                        onTap: _loading ? null : _requestLocation,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: AppSpacing.xs,
                child: Text(
                  '© OpenStreetMap',
                  style: AppTextStyles.body(
                    fontSize: AppFontSize.caption,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppTap(
          onTap: _openMap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: _footerHeight),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: AppIconSize.medium,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t.mosqueMapTitle,
                      style: AppTextStyles.heading(fontSize: AppFontSize.body),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: AppIconSize.medium,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _map(LatLng point, NearbyMosque? nearest, AppLocalizations t) {
    final target = nearest == null
        ? point
        : LatLng(nearest.mosque.latitude, nearest.mosque.longitude);
    return SizedBox(
      height: _previewHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: FlutterMap(
                  key: ValueKey((point, nearest?.mosque.id)),
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    initialCameraFit: nearest == null
                        ? null
                        : CameraFit.coordinates(
                            coordinates: [point, target],
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.xxl,
                              AppSpacing.xl,
                              AppSpacing.xl,
                            ),
                            maxZoom: 16,
                          ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                    backgroundColor: AppColors.surface,
                  ),
                  children: [
                    MosqueTiles(
                      onLoaded: _tilesReady
                          ? null
                          : () => _tilesLoaded(point, nearest?.mosque.id),
                      onError: _tilesReady
                          ? null
                          : () => _tilesError(point, nearest?.mosque.id),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: AppSize.badge,
                          height: AppSize.badge,
                          child: Center(
                            child: Container(
                              width: AppIconSize.small,
                              height: AppIconSize.small,
                              decoration: BoxDecoration(
                                color: AppColors.location,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white,
                                  width: AppSpacing.micro,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (nearest != null)
                          Marker(
                            point: target,
                            width: AppSize.badge,
                            height: AppSize.badge,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mosque_outlined,
                                size: AppIconSize.medium,
                                color: AppColors.bg,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_tilesReady)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: AppColors.surface,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_tilesFailed)
                            Icon(
                              Icons.map_outlined,
                              size: AppIconSize.medium,
                              color: AppColors.text.withValues(
                                alpha: AppOpacity.secondary,
                              ),
                            )
                          else
                            SizedBox.square(
                              dimension: AppIconSize.small,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSpacing.micro,
                                color: AppColors.accent,
                              ),
                            ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              _tilesFailed
                                  ? t.mosquePreviewTileError
                                  : t.mosquePreviewTileLoading,
                              style: AppTextStyles.body(
                                fontSize: AppFontSize.small,
                                color: AppColors.text.withValues(
                                  alpha: AppOpacity.secondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_tilesReady)
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: AppOpacity.strong),
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    t.mosquePreviewTitle,
                    style: AppTextStyles.body(fontSize: AppFontSize.small),
                  ),
                ),
              ),
            ),
          if (_tilesReady)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => launchUrl(
                  Uri.parse('https://www.openstreetmap.org/copyright'),
                  mode: LaunchMode.externalApplication,
                ),
                child: SizedBox(
                  height: AppSize.touchTarget,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: ColoredBox(
                      color: AppColors.surface.withValues(
                        alpha: AppOpacity.strong,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: Text(
                          '© OpenStreetMap',
                          style: AppTextStyles.body(
                            fontSize: AppFontSize.caption,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
