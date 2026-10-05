import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationException implements Exception {
  final LocationError error;

  const LocationException(this.error);

  @override
  String toString() => error.name;
}

class LocationService {
  Future<Position> determinePosition() async {
    await ensurePermission();

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw const LocationException(LocationError.unknown);
    }
  }

  /// Makes sure location is on and allowed, asking for it if it hasn't been
  /// answered yet; throws a [LocationException] saying what's missing.
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(LocationError.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationError.permissionDenied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationError.permissionDeniedForever);
    }
  }

  /// False while location is allowed only as "approximate".
  Future<bool> isPrecise() async {
    try {
      return await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.precise;
    } catch (_) {
      return false;
    }
  }

  /// Asks to upgrade an "approximate only" grant (Android 12+'s choice in
  /// the permission dialog, iOS's "Precise: Off") to the precise location.
  /// Approximate is a couple of km off — fine for a city, not for finding
  /// the nearest mosque. True if the location is precise afterwards; the
  /// user can still decline.
  Future<bool> requestPreciseAccuracy() async {
    try {
      if (await isPrecise()) return true;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // The key names an entry in Info.plist's
        // NSLocationTemporaryUsageDescriptionDictionary.
        return await Geolocator.requestTemporaryFullAccuracy(
              purposeKey: 'MosqueMap',
            ) ==
            LocationAccuracyStatus.precise;
      }
      // With ACCESS_FINE_LOCATION in the manifest this re-asks for it, which
      // Android shows as the "change to precise location" dialog.
      await Geolocator.requestPermission();
      return await isPrecise();
    } catch (_) {
      return false;
    }
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
