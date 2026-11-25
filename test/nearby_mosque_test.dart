import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:fiveglow/data/nearest_mosque.dart';
import 'package:fiveglow/l10n/app_localizations.dart';
import 'package:fiveglow/models/mosque.dart';
import 'package:fiveglow/services/location_service.dart';
import 'package:fiveglow/services/mosque_service.dart';
import 'package:fiveglow/services/nearby_mosque_service.dart';
import 'package:fiveglow/services/notification_service.dart';
import 'package:fiveglow/state/app_state.dart';
import 'package:fiveglow/theme/app_design_system.dart';
import 'package:fiveglow/widgets/nearby_mosque_card.dart';

const _near = Mosque(id: 'n1', latitude: 41.3, longitude: 69.21, name: 'Near');
const _far = Mosque(id: 'n2', latitude: 41.5, longitude: 69.2, name: 'Far');

class _Bundled extends MosqueService {
  Future<BundledMosques>? pending;
  int networkRequests = 0;

  @override
  Future<BundledMosques> loadBundled() =>
      pending ??
      Future.value((
        box: (south: 37.0, west: 55.0, north: 46.0, east: 74.0),
        mosques: [_far, _near],
      ));

  @override
  MosqueFetch fetchArea(GeoBox box) {
    networkRequests++;
    return MosqueFetch(Future.value([]), () {});
  }
}

class _DeniedLocation extends LocationService {
  final permissionRequests = <bool>[];

  @override
  Future<Position?> mapPosition({bool requestPermission = false}) async {
    permissionRequests.add(requestPermission);
    if (requestPermission) {
      throw const LocationException(LocationError.permissionDenied);
    }
    return null;
  }
}

class _PendingLocation extends LocationService {
  final result = Completer<Position?>();

  @override
  Future<Position?> mapPosition({bool requestPermission = false}) =>
      result.future;
}

class _SettingsLocation extends LocationService {
  _SettingsLocation(this.error);
  final LocationError error;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<Position?> mapPosition({bool requestPermission = false}) async =>
      throw LocationException(error);
  @override
  Future<void> openAppSettings() async {
    appSettingsOpened++;
  }

  @override
  Future<void> openLocationSettings() async {
    locationSettingsOpened++;
  }
}

void main() {
  test('nearest mosque uses geographical distance, not source order', () {
    final result = nearestMosque([_far, _near], const LatLng(41.3, 69.2));
    expect(result?.mosque.id, 'n1');
    expect(result!.meters, inInclusiveRange(800, 900));
    expect(nearestMosque([], const LatLng(41.3, 69.2)), isNull);
    final acrossDateLine = nearestMosque([
      const Mosque(id: 'close', latitude: 0, longitude: -179.99),
      const Mosque(id: 'distant', latitude: 0, longitude: 179),
    ], const LatLng(0, 179.99));
    expect(acrossDateLine?.mosque.id, 'close');
  });

  test('bundled region finds a mosque offline without live requests', () async {
    final source = _Bundled();
    final service = NearbyMosqueService(mosques: source);
    final result = await service.find(const LatLng(41.3, 69.2));
    expect(result?.mosque, _near);
    expect(source.networkRequests, 0);
    service.cancel();
  });

  test('disposed lookup stops after its pending bundled read', () async {
    final bundled = Completer<BundledMosques>();
    final source = _Bundled()..pending = bundled.future;
    final service = NearbyMosqueService(mosques: source);
    final finding = service.find(const LatLng(50, 10));
    service.cancel();
    bundled.complete((
      box: (south: 37.0, west: 55.0, north: 46.0, east: 74.0),
      mosques: [_near],
    ));
    expect(await finding, isNull);
    expect(source.networkRequests, 0);
  });

  testWidgets('home requests location only after the user chooses it', (
    tester,
  ) async {
    final location = _DeniedLocation();
    final state = AppState(notifications: NoopNotificationService());
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: Scaffold(
          body: NearbyMosqueCard(
            appState: state,
            location: location,
            mosques: NearbyMosqueService(mosques: _Bundled()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(location.permissionRequests, [false]);
    expect(find.text('Карта мечетей'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('nearby-mosque-enable-location')),
    );
    await tester.pumpAndSettle();
    expect(location.permissionRequests, [false, true]);
    expect(
      find.text('Разрешите доступ к геопозиции, чтобы найти ближайшую мечеть.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('location loading and denied states keep a stable layout', (
    tester,
  ) async {
    final location = _PendingLocation();
    final state = AppState(notifications: NoopNotificationService());
    addTearDown(state.dispose);
    final card = find.byType(NearbyMosqueCard);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: NearbyMosqueCard(appState: state, location: location),
          ),
        ),
      ),
    );
    await tester.pump();
    final loadingHeight = tester.getSize(card).height;
    expect(loadingHeight, greaterThan(AppSize.mapPreview));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    location.result.complete(null);
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, loadingHeight);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('nearby-mosque-enable-location')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  for (final error in [
    LocationError.permissionDeniedForever,
    LocationError.serviceDisabled,
  ]) {
    testWidgets(
      'location settings action handles $error without asking again',
      (tester) async {
        final state = AppState(notifications: NoopNotificationService());
        addTearDown(state.dispose);
        final location = _SettingsLocation(error);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: NearbyMosqueCard(appState: state, location: location),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Открыть настройки'), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('nearby-mosque-enable-location')),
        );
        await tester.pumpAndSettle();
        expect(
          location.appSettingsOpened,
          error == LocationError.permissionDeniedForever ? 1 : 0,
        );
        expect(
          location.locationSettingsOpened,
          error == LocationError.serviceDisabled ? 1 : 0,
        );
      },
    );
  }

  for (final width in [360.0, 400.0]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'mosque states fit $width dp with text scale $scale in every locale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.reset);
          final state = AppState(notifications: NoopNotificationService());
          addTearDown(state.dispose);
          addTearDown(() => AppColors.setDark(false));
          for (final theme in [AppTheme.dark, AppTheme.light]) {
            AppColors.setDark(theme.brightness == Brightness.dark);
            for (final locale in AppLocalizations.supportedLocales) {
              final location = _PendingLocation();
              await tester.pumpWidget(
                MaterialApp(
                  key: UniqueKey(),
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: theme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 844),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: NearbyMosqueCard(
                            appState: state,
                            location: location,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
              expect(tester.takeException(), isNull, reason: 'loading $locale');
              location.result.completeError(
                const LocationException(LocationError.permissionDeniedForever),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: 'permission $locale',
              );
              expect(
                find
                    .byKey(const ValueKey('nearby-mosque-enable-location'))
                    .hitTestable(),
                findsOneWidget,
              );
            }
          }
        },
      );
    }
  }
}
