import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api_client.dart';

/// Envía la posición GPS del conductor a la API cada [intervalSeconds].
/// Mientras la app esté abierta, el panel web muestra el punto en el mapa
/// (Tracking → Live Operations). Si la app se cierra, el punto pasa a
/// "desconectado" cuando la posición envejece (2 min).
class LocationSync {
  LocationSync._();

  static final LocationSync instance = LocationSync._();

  static const int intervalSeconds = 20;

  Timer? _timer;
  bool _enabled = false;
  String _lastError = '';

  bool get enabled => _enabled;
  String get lastError => _lastError;

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _lastError = 'El GPS del teléfono está apagado';
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _lastError = 'Sin permiso de ubicación para el tracking';
      return false;
    }
    return true;
  }

  Future<void> _reportOnce() async {
    final driver = apiClient.currentUser?.displayName;
    if (driver == null || driver.isEmpty) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      await apiClient.sendDriverLocation(
        driver: driver,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speedKmh: position.speed > 0
            ? (position.speed * 3.6)
            : null,
      );
      _lastError = '';
    } catch (error) {
      _lastError = error.toString();
      debugPrint('LocationSync: $error');
    }
  }

  /// Inicia el ciclo; seguro de llamar varias veces (no duplica timers).
  Future<void> start() async {
    if (_enabled) return;
    if (!await _ensurePermission()) return;
    _enabled = true;
    await _reportOnce();
    _timer = Timer.periodic(
      const Duration(seconds: intervalSeconds),
      (_) => _reportOnce(),
    );
  }

  void stop() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }
}