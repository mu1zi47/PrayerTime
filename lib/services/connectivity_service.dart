import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around connectivity_plus — a device-level check ("is there
/// an active network interface") rather than a real reachability probe.
/// That's enough to gate settings changes that require a fresh fetch
/// ([AppState.selectCity]/[selectMethod]/[selectMadhab]): actual fetch
/// failures despite an active interface are already handled separately via
/// [PrayerApiException].
class ConnectivityService {
  const ConnectivityService();

  Future<bool> hasConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
