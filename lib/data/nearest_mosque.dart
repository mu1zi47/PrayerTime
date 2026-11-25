import 'package:latlong2/latlong.dart';

import '../models/mosque.dart';

typedef NearbyMosque = ({Mosque mosque, double meters});

NearbyMosque? nearestMosque(Iterable<Mosque> mosques, LatLng position) {
  NearbyMosque? nearest;
  for (final mosque in mosques) {
    final meters = const Distance().as(
      LengthUnit.Meter,
      position,
      LatLng(mosque.latitude, mosque.longitude),
    );
    if (nearest == null || meters < nearest.meters) {
      nearest = (mosque: mosque, meters: meters);
    }
  }
  return nearest;
}
