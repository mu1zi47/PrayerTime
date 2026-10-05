import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/mosque_clusters.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/mosque.dart';
import '../services/location_service.dart';
import '../services/mosque_cache.dart';
import '../services/mosque_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_toast.dart';
import '../widgets/icon_badge.dart';
import '../widgets/map_zoom_strip.dart';
import '../widgets/pill_button.dart';
import '../widgets/screen_back_button.dart';

// OpenStreetMap's own tile servers: keyless, and their usage policy allows
// native apps that identify themselves (userAgentPackageName below), keep
// the attribution visible and honour the cache headers — which flutter_map's
// built-in tile cache does. No prefetching or "download for offline" on top
// of these: the policy forbids it. (CARTO's basemaps, the obvious
// alternative with a ready dark style, need an API key since Sept 2026.)
const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _copyrightUrl = 'https://www.openstreetmap.org/copyright';

/// Inverts the tiles and turns the hues back round — the same matrix as
/// flutter_map's darkModeTileBuilder.
const _darkTileFilter = ColorFilter.matrix(<double>[
  0.574, -1.43, -0.144, 0, 255, //
  -0.426, -0.43, -0.144, 0, 255, //
  -0.426, -1.43, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
]);

const _minZoom = 3.0;
const _maxZoom = 19.0;

/// From this zoom in, areas outside the bundled region are looked up —
/// further out a lookup would cover a whole province and take too long to
/// be useful.
const _liveMinZoom = 11.0;

/// The map is looked up, cached and remembered as loaded in cells of this
/// many degrees (~11 km): small enough that a lookup covers little more
/// than the screen, so answers stay small and come back fast.
const _cellDegrees = 0.1;

/// A phone screen at [_liveMinZoom] spans about a dozen cells; this many
/// means a tablet or something odd, and is where it asks to zoom in instead.
const _maxCellsPerQuery = 40;

/// How long a looked-up cell is trusted. Older ones still show at once, and
/// are quietly looked up again in the background.
const _cacheFreshFor = Duration(days: 30);

MosqueCell _cellOf(double latitude, double longitude) =>
    ((latitude / _cellDegrees).floor(), (longitude / _cellDegrees).floor());

class MosqueMapScreen extends StatefulWidget {
  final AppState appState;

  const MosqueMapScreen({super.key, required this.appState});

  @override
  State<MosqueMapScreen> createState() => _MosqueMapScreenState();
}

class _MosqueMapScreenState extends State<MosqueMapScreen>
    with SingleTickerProviderStateMixin {
  final _service = MosqueService();
  final _cache = MosqueCache();
  final _location = LocationService();
  final _mapController = MapController();

  final Map<String, Mosque> _mosques = {};

  /// The pins at every zoom level, regrouped in the background whenever
  /// mosques are added. A notifier rather than state, so a regrouping
  /// repaints the pin layer alone instead of rebuilding the whole screen.
  final _clusters = ValueNotifier(MosqueClusters.empty);
  bool _clustering = false;
  bool _reclusterQueued = false;
  final _hits = _PinHits();

  /// Which edge the zoom strip sits on — the user's to choose, by holding
  /// it (see MapZoomStrip), and remembered between visits.
  bool _zoomOnLeft = false;
  bool _zoomSideLoaded = false;
  static const _kZoomSide = 'mosque_map_zoom_side';

  /// Pinged whenever the map is touched — the zoom strip puts its "move"
  /// button away.
  final _mapTouches = ValueNotifier(0);

  // Tap detection on the map itself (see _onPointerUp).
  int? _tapPointer;
  Offset? _tapDownAt;
  Duration? _tapDownTime;
  int _pointersDown = 0;

  /// Built once: a new MapOptions on every rebuild would have FlutterMap
  /// re-apply them each time.
  late final MapOptions _mapOptions = MapOptions(
    initialCenter: LatLng(
      widget.appState.selectedCity.latitude,
      widget.appState.selectedCity.longitude,
    ),
    initialZoom: 13,
    minZoom: _minZoom,
    maxZoom: _maxZoom,
    backgroundColor: AppColors.bg,
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    ),
    onMapReady: _onMapReady,
    onPositionChanged: _onPositionChanged,
  );

  // Where the mosques come from, cheapest first: the bundled region (never
  // looked up), then the on-device cache, then Overpass.
  bool _bundleLoaded = false;
  ({int rowFrom, int rowTo, int colFrom, int colTo})? _bundledCells;
  final Set<MosqueCell> _cacheChecked = {};
  final Set<MosqueCell> _freshCells = {};
  final Set<MosqueCell> _staleCells = {};

  ({Set<MosqueCell> cells, MosqueFetch fetch})? _inFlight;
  bool _syncing = false;
  bool _syncQueued = false;
  bool _syncAfterFetch = false;
  bool _errorShown = false;
  bool _showZoomHint = false;

  bool _mapReady = false;
  Timer? _settleTimer;

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addListener(_onFlightTick);
  ({LatLng center, double zoom})? _flightFrom;
  ({LatLng center, double zoom})? _flightTo;

  LatLng? _userPosition;

  /// How far off [_userPosition] may be, in meters — drawn as a circle
  /// around the dot, so an approximate fix looks approximate.
  double? _userAccuracy;
  StreamSubscription<Position>? _positionSub;
  bool _locating = false;

  /// Caps how long "my location" spins waiting for a first fix — indoors or
  /// with no signal one may never come.
  Timer? _locateTimeout;

  /// Whether the next fix should bring the camera to it: set when the
  /// screen opens and when "my location" is pressed, cleared as soon as the
  /// user drags or zooms — a late fix shouldn't yank the view away from
  /// where they're looking.
  bool _centerOnNextFix = false;

  @override
  void initState() {
    super.initState();
    _loadBundled();
    _locateSilently();
    _loadZoomSide();
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _positionSub?.cancel();
    _locateTimeout?.cancel();
    _inFlight?.fetch.cancel();
    _flight.dispose();
    _clusters.dispose();
    _mapTouches.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadBundled() async {
    try {
      final bundled = await _service.loadBundled();
      final box = bundled.box;
      // The box sits on whole cells (see tool/update_mosques.dart), so it
      // converts to row and column ranges without rounding at the edges.
      _bundledCells = (
        rowFrom: (box.south / _cellDegrees).round(),
        rowTo: (box.north / _cellDegrees).round() - 1,
        colFrom: (box.west / _cellDegrees).round(),
        colTo: (box.east / _cellDegrees).round() - 1,
      );
      _addMosques(bundled.mosques);
    } catch (_) {
      // A broken asset leaves the map to the cache and live lookups.
    }
    _bundleLoaded = true;
    if (mounted && _mapReady) _onCameraSettled();
  }

  bool _isBundled(MosqueCell cell) {
    final b = _bundledCells;
    return b != null &&
        cell.$1 >= b.rowFrom &&
        cell.$1 <= b.rowTo &&
        cell.$2 >= b.colFrom &&
        cell.$2 <= b.colTo;
  }

  /// Merges [mosques] in by OSM id — a fresher copy of one already shown
  /// replaces it rather than doubling the pin.
  void _addMosques(Iterable<Mosque> mosques) {
    if (!mounted) return;
    var changed = false;
    for (final m in mosques) {
      _mosques[m.id] = m;
      changed = true;
    }
    if (changed) _recluster();
  }

  /// Regroups the pins off the UI thread. Additions arriving meanwhile are
  /// folded into one more pass once this one lands, not one pass each.
  Future<void> _recluster() async {
    if (_clustering) {
      _reclusterQueued = true;
      return;
    }
    _clustering = true;
    do {
      _reclusterQueued = false;
      final clusters = await MosqueClusters.build(
        _mosques.values.toList(growable: false),
      );
      if (!mounted) return;
      _clusters.value = clusters;
    } while (_reclusterQueued);
    _clustering = false;
  }

  void _onMapReady() {
    setState(() => _mapReady = true);
    final user = _userPosition;
    if (user != null && _centerOnNextFix) {
      _centerOnNextFix = false;
      _mapController.move(user, 15);
    }
    _onCameraSettled();
  }

  // A tap is a single finger going down and up again within a short time
  // and distance. Detected from raw pointer events rather than the map's
  // own onTap, which waits out the double-tap timeout before firing — a
  // pin should answer the moment it's touched.
  Future<void> _loadZoomSide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _zoomOnLeft = prefs.getString(_kZoomSide) == 'left';
    } catch (_) {
      // Unreadable: the default side it is.
    }
    if (mounted) setState(() => _zoomSideLoaded = true);
  }

  void _setZoomSide(bool onLeft) {
    setState(() => _zoomOnLeft = onLeft);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_kZoomSide, onLeft ? 'left' : 'right'))
        .catchError((Object _) => false);
  }

  void _onPointerDown(PointerDownEvent e) {
    _mapTouches.value++;
    _pointersDown++;
    if (_pointersDown == 1) {
      _tapPointer = e.pointer;
      _tapDownAt = e.localPosition;
      _tapDownTime = e.timeStamp;
    } else {
      _tapPointer = null;
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointersDown = math.max(0, _pointersDown - 1);
    final downAt = _tapDownAt;
    final downTime = _tapDownTime;
    if (e.pointer != _tapPointer || downAt == null || downTime == null) return;
    _tapPointer = null;
    if ((e.localPosition - downAt).distance > 12) return;
    if (e.timeStamp - downTime > const Duration(milliseconds: 350)) return;
    final hit = _hits.hitTest(e.localPosition);
    if (hit != null) _onClusterTap(hit);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointersDown = math.max(0, _pointersDown - 1);
    if (e.pointer == _tapPointer) _tapPointer = null;
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _centerOnNextFix = false;
      _flight.stop();
    }
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 350), _onCameraSettled);
  }

  /// Runs once the map has stopped moving: brings in whatever the view
  /// still lacks, or says to zoom in if it's too far out for that.
  void _onCameraSettled() {
    if (!mounted || !_mapReady || !_bundleLoaded) return;
    final camera = _mapController.camera;
    if (camera.zoom >= _liveMinZoom) {
      _sync();
      return;
    }
    final b = camera.visibleBounds;
    _setZoomHint(
      !_mosques.values.any(
        (m) =>
            m.latitude >= b.south &&
            m.latitude <= b.north &&
            m.longitude >= b.west &&
            m.longitude <= b.east,
      ),
    );
  }

  void _setZoomHint(bool show) {
    if (show != _showZoomHint) setState(() => _showZoomHint = show);
  }

  Future<void> _sync() async {
    if (_syncing) {
      _syncQueued = true;
      return;
    }
    _syncing = true;
    try {
      await _syncVisibleCells();
    } finally {
      _syncing = false;
    }
    if (_syncQueued && mounted) {
      _syncQueued = false;
      _onCameraSettled();
    }
  }

  Future<void> _syncVisibleCells() async {
    final bounds = _mapController.camera.visibleBounds;
    final (rowFrom, colFrom) = _cellOf(bounds.south, bounds.west);
    final (rowTo, colTo) = _cellOf(bounds.north, bounds.east);
    if ((rowTo - rowFrom + 1) * (colTo - colFrom + 1) > _maxCellsPerQuery) {
      _setZoomHint(true);
      return;
    }
    _setZoomHint(false);

    final visible = <MosqueCell>{
      for (var row = rowFrom; row <= rowTo; row++)
        for (var col = colFrom; col <= colTo; col++)
          if (!_isBundled((row, col))) (row, col),
    };
    if (visible.isEmpty) return;

    // The device first — a city looked at before shows straight away.
    final unchecked = visible.where((c) => !_cacheChecked.contains(c));
    if (unchecked.isNotEmpty) {
      final cells = unchecked.toList();
      _cacheChecked.addAll(cells);
      final cached = await _cache.read(cells);
      if (!mounted) return;
      final now = DateTime.now();
      cached.forEach((cell, entry) {
        final fresh = now.difference(entry.fetchedAt) < _cacheFreshFor;
        (fresh ? _freshCells : _staleCells).add(cell);
      });
      _addMosques(cached.values.expand((entry) => entry.mosques));
    }

    // Then the network, for whatever the device didn't have.
    final needed = visible.where((c) => !_freshCells.contains(c)).toSet();
    final inFlight = _inFlight;
    if (inFlight != null) {
      needed.removeAll(inFlight.cells);
      if (needed.isEmpty) return;
      if (inFlight.cells.any(visible.contains)) {
        // Still bringing in part of this view — let it land first.
        _syncAfterFetch = true;
        return;
      }
      // The view has moved on entirely; don't make it wait behind a lookup
      // nobody is looking at any more.
      inFlight.fetch.cancel();
      setState(() => _inFlight = null);
    }
    if (needed.isNotEmpty) _fetchCells(needed);
  }

  Future<void> _fetchCells(Set<MosqueCell> cells) async {
    // One lookup for the box around every missing cell: a little extra
    // ground on an L-shaped gap, but one round trip instead of several.
    final rows = cells.map((c) => c.$1);
    final cols = cells.map((c) => c.$2);
    final box = (
      south: rows.reduce(math.min) * _cellDegrees,
      west: cols.reduce(math.min) * _cellDegrees,
      north: (rows.reduce(math.max) + 1) * _cellDegrees,
      east: (cols.reduce(math.max) + 1) * _cellDegrees,
    );

    final entry = (cells: cells, fetch: _service.fetchArea(box));
    setState(() => _inFlight = entry);
    final found = await entry.fetch.result;
    // Cancelled, or replaced by a lookup for where the view went instead.
    if (!mounted || _inFlight != entry) return;
    setState(() => _inFlight = null);

    if (found == null) {
      // Only worth saying when something is actually missing — a failed
      // background refresh of a cached area still shows that area — and
      // only once per run of failures, not once per pan.
      if (!_errorShown && cells.any((c) => !_staleCells.contains(c))) {
        _errorShown = true;
        AppToast.show(
          context,
          AppLocalizations.of(context)!.mosqueLoadError,
          icon: Icons.wifi_off_rounded,
        );
      }
    } else {
      _errorShown = false;
      final byCell = {for (final c in cells) c: <Mosque>[]};
      for (final m in found) {
        byCell[_cellOf(m.latitude, m.longitude)]?.add(m);
      }
      _freshCells.addAll(cells);
      _staleCells.removeAll(cells);
      _addMosques(found);
      unawaited(_cache.write(byCell));
    }

    if (_syncAfterFetch) {
      _syncAfterFetch = false;
      _onCameraSettled();
    }
  }

  /// Glides the camera to [center] at [zoom] instead of jumping there.
  void _flyTo(LatLng center, double zoom) {
    if (!_mapReady) return;
    final camera = _mapController.camera;
    _flightFrom = (center: camera.center, zoom: camera.zoom);
    _flightTo = (center: center, zoom: zoom.clamp(_minZoom, _maxZoom));
    _flight.forward(from: 0);
  }

  void _onFlightTick() {
    final from = _flightFrom;
    final to = _flightTo;
    if (from == null || to == null) return;
    final t = Curves.easeInOutCubic.transform(_flight.value);
    _mapController.move(
      LatLng(
        lerpDouble(from.center.latitude, to.center.latitude, t)!,
        lerpDouble(from.center.longitude, to.center.longitude, t)!,
      ),
      lerpDouble(from.zoom, to.zoom, t)!,
    );
  }

  void _onClusterTap(MosqueCluster cluster) {
    final mosque = cluster.mosque;
    if (mosque != null) {
      _showMosque(mosque);
      return;
    }
    final camera = _mapController.camera;
    final b = cluster.bounds;
    // Members all on (nearly) one spot: there's no box to fit, just go in.
    if (b.north - b.south < 1e-5 && b.east - b.west < 1e-5) {
      _flyTo(LatLng(cluster.latitude, cluster.longitude), camera.zoom + 2);
      return;
    }
    final fitted = CameraFit.bounds(
      bounds: LatLngBounds(LatLng(b.south, b.west), LatLng(b.north, b.east)),
      padding: const EdgeInsets.all(72),
      maxZoom: MosqueClusters.unclusteredFromZoom.toDouble(),
    ).fit(camera);
    // At least one level in, so a tap always visibly opens the bubble up.
    _flyTo(fitted.center, math.max(fitted.zoom, camera.zoom + 1));
  }

  void _showMosque(Mosque mosque) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MosqueSheet(
        mosque: mosque,
        locale: widget.appState.locale,
        userPosition: _userPosition,
      ),
    );
  }

  /// Shows where the user is if they've already allowed location — without
  /// asking. The "my location" button is what asks.
  Future<void> _locateSilently() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      _centerOnNextFix = true;
      _startTracking();
    } catch (_) {
      // Location unavailable — the map just stays on the city.
    }
  }

  /// Follows the user's position for as long as the screen is open. Not
  /// getLastKnownPosition: that's whatever some app last asked for, possibly
  /// hours old and kilometers away.
  void _startTracking() {
    _positionSub?.cancel();
    final LocationSettings settings =
        defaultTargetPlatform == TargetPlatform.android
        // Android's own LocationManager rather than Google's fused client:
        // the fused one pops a "turn on Google Location Accuracy" system
        // dialog whenever that setting is off — even just for opening the
        // map — and stops altogether if it's turned down. LocationManager
        // gives the same precise GPS fix without it, and still uses Wi-Fi
        // and cell positioning when the setting is on.
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
            forceLocationManager: true,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          _onPosition,
          onError: (Object _) {
            // Location switched off mid-way — "my location" restarts it.
            _positionSub?.cancel();
            _positionSub = null;
            if (!mounted || !_locating) return;
            _locateTimeout?.cancel();
            setState(() => _locating = false);
            AppToast.show(
              context,
              AppLocalizations.of(context)!.cityLocationErrorGeneric,
              icon: Icons.location_off_rounded,
            );
          },
        );
  }

  void _onPosition(Position position) {
    if (!mounted) return;
    final point = LatLng(position.latitude, position.longitude);
    _locateTimeout?.cancel();
    setState(() {
      _userPosition = point;
      _userAccuracy = position.accuracy;
      _locating = false;
    });
    if (_centerOnNextFix && _mapReady) {
      _centerOnNextFix = false;
      _flyTo(point, math.max(_mapController.camera.zoom, 15));
    }
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    var waitingForFix = false;
    try {
      await _location.ensurePermission();
      final alreadyPrecise = await _location.isPrecise();
      if (!alreadyPrecise) await _location.requestPreciseAccuracy();
      if (!mounted) return;

      final current = _userPosition;
      if (current != null && _positionSub != null && alreadyPrecise) {
        _flyTo(current, math.max(_mapController.camera.zoom, 15));
        return;
      }
      // Either nothing tracked yet, or the grant just went from approximate
      // to precise — a subscription started under the approximate one can
      // keep delivering coarse fixes, so start over.
      _centerOnNextFix = true;
      waitingForFix = true;
      _startTracking();
      // The spinner stays until _onPosition's first fix.
      _locateTimeout?.cancel();
      _locateTimeout = Timer(const Duration(seconds: 20), () {
        if (!mounted) return;
        setState(() => _locating = false);
        AppToast.show(
          context,
          AppLocalizations.of(context)!.cityLocationErrorGeneric,
          icon: Icons.location_off_rounded,
        );
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      AppToast.show(context, switch (e.error) {
        LocationError.serviceDisabled => t.cityLocationServiceDisabled,
        LocationError.permissionDenied ||
        LocationError.permissionDeniedForever => t.cityLocationPermissionDenied,
        LocationError.unknown => t.cityLocationErrorGeneric,
      }, icon: Icons.location_off_rounded);
    } finally {
      if (mounted && !waitingForFix) setState(() => _locating = false);
    }
  }

  Widget _tiles(bool isDark) {
    final tiles = TileLayer(
      urlTemplate: _tileUrl,
      maxNativeZoom: 19,
      userAgentPackageName: 'uz.mu1zi47.prayertime',
    );
    if (!isDark) return tiles;
    // OSM has no dark style of its own, so the light one is inverted —
    // with one filter over the whole layer rather than flutter_map's
    // darkModeTileBuilder, which wraps every tile in a filter of its own.
    return ColorFiltered(colorFilter: _darkTileFilter, child: tiles);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userPosition = _userPosition;

    // The spinner only while part of the view has nothing to show yet — a
    // background refresh of an area already on screen isn't "loading".
    final inFlight = _inFlight;
    final loadingBlank =
        inFlight != null && inFlight.cells.any((c) => !_staleCells.contains(c));
    final String? status;
    if (loadingBlank) {
      status = t.mosqueLoading;
    } else if (_showZoomHint) {
      status = t.mosqueZoomInHint;
    } else {
      status = null;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            // Its own layer: the map repaints every frame while it moves,
            // and without this the shadowed controls on top would be
            // repainted along with it.
            child: RepaintBoundary(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: FlutterMap(
                  mapController: _mapController,
                  options: _mapOptions,
                  children: [
                    _tiles(isDark),
                    if (userPosition != null && (_userAccuracy ?? 0) > 0)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: userPosition,
                            radius: _userAccuracy!,
                            useRadiusInMeter: true,
                            color: _userBlue.withValues(alpha: 0.12),
                            borderColor: _userBlue.withValues(alpha: 0.4),
                            borderStrokeWidth: 1,
                          ),
                        ],
                      ),
                    _MosqueLayer(clusters: _clusters, hits: _hits),
                    if (userPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userPosition,
                            width: 22,
                            height: 22,
                            child: const _UserDot(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Floating(
                      shape: BoxShape.circle,
                      child: ScreenBackButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _Floating(
                        child: SizedBox(
                          height: 38,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            // Sized to the title rather than stretched
                            // across the bar — the map shows around it.
                            child: Align(
                              widthFactor: 1,
                              child: Text(
                                t.mosqueMapTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: status == null
                      ? const SizedBox.shrink()
                      : Padding(
                          key: ValueKey(status),
                          padding: const EdgeInsets.only(top: 10),
                          child: _StatusChip(label: status, busy: loadingBlank),
                        ),
                ),
              ],
            ),
          ),
          // Waits for the saved side, so it doesn't open on the right and
          // then jump to the left.
          if (_mapReady && _zoomSideLoaded)
            Positioned(
              left: _zoomOnLeft ? 0 : null,
              right: _zoomOnLeft ? null : 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: RepaintBoundary(
                  child: MapZoomStrip(
                    controller: _mapController,
                    minZoom: _minZoom,
                    maxZoom: _maxZoom,
                    onLeft: _zoomOnLeft,
                    onSideChanged: _setZoomSide,
                    mapTouched: _mapTouches,
                    onInteractionStart: _flight.stop,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            bottom: padding.bottom + 16,
            child: const _Attribution(),
          ),
          Positioned(
            right: 16,
            bottom: padding.bottom + 16,
            child: _Floating(
              shape: BoxShape.circle,
              child: GestureDetector(
                onTap: _locateMe,
                behavior: HitTestBehavior.opaque,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: _locating
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.accent700,
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            size: 22,
                            color: AppColors.accent700,
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

/// Where the pins went on the last frame — what a tap on the map is checked
/// against. Flat arrays reused frame to frame, so drawing allocates nothing.
class _PinHits {
  MosqueClusters clusters = MosqueClusters.empty;
  ClusterLevel? level;
  int _length = 0;
  Float32List _x = Float32List(256);
  Float32List _y = Float32List(256);
  Float32List _radius = Float32List(256);
  Int32List _index = Int32List(256);

  void reset(MosqueClusters clusters, ClusterLevel? level) {
    this.clusters = clusters;
    this.level = level;
    _length = 0;
  }

  void add(double x, double y, double radius, int index) {
    if (_length == _x.length) {
      _x = _grow(_x);
      _y = _grow(_y);
      _radius = _grow(_radius);
      _index = Int32List(_length * 2)..setRange(0, _length, _index);
    }
    _x[_length] = x;
    _y[_length] = y;
    _radius[_length] = radius;
    _index[_length] = index;
    _length++;
  }

  static Float32List _grow(Float32List list) =>
      Float32List(list.length * 2)..setRange(0, list.length, list);

  /// The pin under [point], with a little slack for a fingertip: the one
  /// whose center is nearest, among those the tap is close enough to.
  MosqueCluster? hitTest(Offset point) {
    final level = this.level;
    if (level == null) return null;
    int? best;
    var bestDistance = double.infinity;
    for (var i = 0; i < _length; i++) {
      final dx = _x[i] - point.dx;
      final dy = _y[i] - point.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance <= _radius[i] + 8 && distance < bestDistance) {
        best = _index[i];
        bestDistance = distance;
      }
    }
    return best == null ? null : clusters.clusterAt(level, best);
  }
}

/// The mosque pins and bubbles. One CustomPaint for all of them rather than
/// a widget per pin: it repaints on every camera frame, and a frame costs a
/// scan of flat arrays, one atlas draw for every single pin, and a cached
/// image plus a cached label per bubble — no layout, no widget churn, no
/// shadow blurred anew per pin per frame.
class _MosqueLayer extends StatelessWidget {
  final ValueListenable<MosqueClusters> clusters;
  final _PinHits hits;

  const _MosqueLayer({required this.clusters, required this.hits});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return MobileLayerTransformer(
      child: ValueListenableBuilder<MosqueClusters>(
        valueListenable: clusters,
        builder: (context, clusters, _) => CustomPaint(
          painter: _MosquePainter(
            camera: camera,
            clusters: clusters,
            hits: hits,
            sprites: _Sprites.of(dpr),
          ),
        ),
      ),
    );
  }
}

class _MosquePainter extends CustomPainter {
  final MapCamera camera;
  final MosqueClusters clusters;
  final _PinHits hits;
  final _Sprites sprites;

  _MosquePainter({
    required this.camera,
    required this.clusters,
    required this.hits,
    required this.sprites,
  });

  // Scratch space for the atlas draw, kept across frames.
  static Float32List _transforms = Float32List(1024);
  static Float32List _rects = Float32List(1024);

  static final _imagePaint = Paint()..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    final level = clusters.at(camera.zoom.floor());
    hits.reset(clusters, level);
    if (level == null) return;

    final bounds = camera.visibleBounds;
    // A margin so a pin straddling the edge is drawn whole.
    final latPad = (bounds.north - bounds.south) * 0.1;
    final lonPad = (bounds.east - bounds.west) * 0.1;
    final south = bounds.south - latPad;
    final north = bounds.north + latPad;
    final west = bounds.west - lonPad;
    final east = bounds.east + lonPad;
    final origin = camera.pixelOrigin;

    final pin = sprites.pin;
    final pinScale = 1 / sprites.dpr;
    final pinHalf = pin.width / 2;
    var singles = 0;

    for (var i = 0; i < level.length; i++) {
      final lat = level.latitude[i];
      final lon = level.longitude[i];
      if (lat < south || lat > north || lon < west || lon > east) continue;
      final p = camera.projectAtZoom(LatLng(lat, lon)) - origin;
      final count = level.count[i];

      if (count == 1) {
        if ((singles + 1) * 4 > _transforms.length) {
          _transforms = Float32List(_transforms.length * 2)
            ..setRange(0, singles * 4, _transforms);
          _rects = Float32List(_rects.length * 2)
            ..setRange(0, singles * 4, _rects);
        }
        final o = singles * 4;
        _transforms
          ..[o] = pinScale
          ..[o + 1] = 0
          ..[o + 2] = p.dx - pinHalf * pinScale
          ..[o + 3] = p.dy - pinHalf * pinScale;
        _rects
          ..[o] = 0
          ..[o + 1] = 0
          ..[o + 2] = pin.width.toDouble()
          ..[o + 3] = pin.height.toDouble();
        singles++;
        hits.add(p.dx, p.dy, 17, i);
      } else {
        final diameter = _clusterDiameter(count);
        final bubble = sprites.bubble(diameter);
        final half = bubble.width / sprites.dpr / 2;
        canvas.drawImageRect(
          bubble,
          Rect.fromLTWH(
            0,
            0,
            bubble.width.toDouble(),
            bubble.height.toDouble(),
          ),
          Rect.fromLTWH(p.dx - half, p.dy - half, half * 2, half * 2),
          _imagePaint,
        );
        final label = sprites.label(count, diameter);
        label.paint(canvas, p - Offset(label.width / 2, label.height / 2));
        hits.add(p.dx, p.dy, diameter / 2 + 4, i);
      }
    }

    if (singles > 0) {
      // Single pins on top of the bubbles, all in one draw call.
      canvas.drawRawAtlas(
        pin,
        Float32List.sublistView(_transforms, 0, singles * 4),
        Float32List.sublistView(_rects, 0, singles * 4),
        null,
        null,
        null,
        _imagePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MosquePainter old) => true;
}

/// The pin and bubble artwork, rasterized once per screen density and theme
/// — shadows included — so frames only copy pixels around.
class _Sprites {
  final double dpr;
  final Color fill;
  final Color edge;
  final Color ring;

  _Sprites._(this.dpr, this.fill, this.edge, this.ring);

  static _Sprites? _current;

  static _Sprites of(double dpr) {
    final fill = AppColors.accent700;
    final edge = AppColors.surface;
    final ring = AppColors.accent300.withValues(alpha: 0.9);
    final current = _current;
    if (current != null &&
        current.dpr == dpr &&
        current.fill == fill &&
        current.edge == edge &&
        current.ring == ring) {
      return current;
    }
    current?._dispose();
    return _current = _Sprites._(dpr, fill, edge, ring);
  }

  late final ui.Image pin = _render(46, (canvas) {
    const center = Offset(23, 23);
    canvas.drawCircle(
      center + const Offset(0, 2),
      17,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 17, Paint()..color = edge);
    canvas.drawCircle(center, 15, Paint()..color = fill);
    final glyph = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.mosque_rounded.codePoint),
        style: TextStyle(
          fontFamily: Icons.mosque_rounded.fontFamily,
          package: Icons.mosque_rounded.fontPackage,
          fontSize: 17,
          color: edge,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));
    glyph.dispose();
  });

  final Map<int, ui.Image> _bubbles = {};

  ui.Image bubble(double diameter) {
    final key = diameter.round();
    return _bubbles[key] ??= () {
      final radius = key / 2;
      final side = key + 24.0;
      return _render(side, (canvas) {
        final center = Offset(side / 2, side / 2);
        canvas.drawCircle(
          center + const Offset(0, 2),
          radius + 4,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(center, radius + 4, Paint()..color = ring);
        canvas.drawCircle(center, radius, Paint()..color = fill);
      });
    }();
  }

  final Map<int, TextPainter> _labels = {};

  TextPainter label(int count, double diameter) {
    if (_labels.length > 2000) _disposeLabels();
    return _labels[count] ??= () {
      TextPainter make(double fontSize) => TextPainter(
        text: TextSpan(
          text: '$count',
          style: AppTextStyles.body(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: edge,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      // Shrunk to fit, the way the old bubble's FittedBox did.
      final label = make(14);
      final room = diameter - 12;
      if (label.width <= room) return label;
      final fitted = make(14 * room / label.width);
      label.dispose();
      return fitted;
    }();
  }

  ui.Image _render(double side, void Function(Canvas) draw) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    draw(canvas);
    final picture = recorder.endRecording();
    final px = (side * dpr).ceil();
    final image = picture.toImageSync(px, px);
    picture.dispose();
    return image;
  }

  void _disposeLabels() {
    for (final label in _labels.values) {
      label.dispose();
    }
    _labels.clear();
  }

  void _dispose() {
    pin.dispose();
    for (final image in _bubbles.values) {
      image.dispose();
    }
    _bubbles.clear();
    _disposeLabels();
  }
}

/// Grows with the count, but slowly — a cluster of 2,000 shouldn't swallow
/// the screen.
double _clusterDiameter(int count) =>
    (28 + 8 * math.log(count) / math.ln10).clamp(34, 56).toDouble();

/// The surface-colored, shadowed card every control floating over the map
/// sits on, so it reads against busy map tiles in either theme.
class _Floating extends StatelessWidget {
  final Widget child;
  final BoxShape shape;

  const _Floating({required this.child, this.shape = BoxShape.rectangle});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral900.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool busy;

  const _StatusChip({required this.label, required this.busy});

  @override
  Widget build(BuildContext context) {
    return _Floating(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent700,
                ),
              )
            else
              Icon(Icons.zoom_in_rounded, size: 16, color: AppColors.accent700),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(_copyrightUrl),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          '© OpenStreetMap contributors',
          style: AppTextStyles.body(fontSize: 10, color: AppColors.neutral700),
        ),
      ),
    );
  }
}

/// The usual "you are here" blue — rather than gold, so the dot can't be
/// mistaken for a mosque pin.
const _userBlue = Color(0xFF2F80ED);

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _userBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _userBlue.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _MosqueSheet extends StatelessWidget {
  final Mosque mosque;
  final AppLocale locale;
  final LatLng? userPosition;

  const _MosqueSheet({
    required this.mosque,
    required this.locale,
    required this.userPosition,
  });

  String get _language => switch (locale) {
    AppLocale.ru => 'ru',
    AppLocale.en => 'en',
    AppLocale.uzLatin => 'uz',
    AppLocale.uzCyrillic => 'uz-Cyrl',
  };

  String? _distanceLabel(AppLocalizations t) {
    final from = userPosition;
    if (from == null) return null;
    final meters = const Distance().as(
      LengthUnit.Meter,
      from,
      LatLng(mosque.latitude, mosque.longitude),
    );
    final String distance;
    if (meters < 1000) {
      distance = t.mosqueDistanceMeters('${(meters / 10).round() * 10}');
    } else {
      final km = meters / 1000;
      distance = t.mosqueDistanceKm(
        NumberFormat(km < 10 ? '0.0' : '0', t.localeName).format(km),
      );
    }
    return t.mosqueDistanceAway(distance);
  }

  /// Hands the destination to whatever maps app the phone has: Android's
  /// `geo:` intent lets the user pick between Yandex, Google, 2GIS and the
  /// rest; iOS goes to Apple Maps. A web link to Google Maps is the
  /// fallback for when neither opens.
  Future<void> _openDirections(BuildContext context, String title) async {
    final lat = mosque.latitude;
    final lon = mosque.longitude;
    final candidates = [
      if (defaultTargetPlatform == TargetPlatform.android)
        Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(title)})'),
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)
        Uri.https('maps.apple.com', '/', {'daddr': '$lat,$lon', 'q': title}),
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '$lat,$lon',
      }),
    ];
    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {
        // Try the next one.
      }
    }
    if (!context.mounted) return;
    AppToast.show(
      context,
      AppLocalizations.of(context)!.mosqueOpenMapsError,
      icon: Icons.map_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final title = mosque.localizedName(_language) ?? t.mosqueUnnamed;
    final address = mosque.address;
    final distance = _distanceLabel(t);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.mosque_rounded, size: 44, iconSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading(fontSize: 18)),
                    if (address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: AppTextStyles.body(
                          fontSize: 14,
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                    if (distance != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        distance,
                        style: AppTextStyles.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PillButton(
            label: t.mosqueDirections,
            icon: Icons.directions_rounded,
            onTap: () => _openDirections(context, title),
          ),
        ],
      ),
    );
  }
}
