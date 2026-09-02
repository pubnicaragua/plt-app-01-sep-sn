import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

Future<CurrentLocation?> requestCurrentLocation() async {
  if (kIsWeb) return null;
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    return CurrentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (_) {
    return null;
  }
}

class CurrentLocation {
  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    this.label = 'Mi ubicación actual (Los Robles)',
  });

  final double latitude;
  final double longitude;
  final String label;
}
