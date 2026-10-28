import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/home_conductor.dart';
import 'package:incoex_logistics_app/screens/viaje_en_curso.dart';

void main() {
  test('convierte la ruta de tracking en puntos para la polilínea del mapa',
      () {
    const tracking = TrackingData(
      tripId: '4790',
      status: 'En camino',
      driver: 'Juan',
      lastUpdate: '2026-10-27T12:00:00Z',
      route: [
        TrackingPoint(latitude: 12.10, longitude: -86.25, label: 'Conductor'),
        TrackingPoint(latitude: 12.11, longitude: -86.24, label: 'Ruta'),
        TrackingPoint(latitude: 12.12, longitude: -86.23, label: 'Destino'),
      ],
    );

    final points = conductorTrackingPolylinePoints(tracking);

    expect(points, const [
      LatLng(12.10, -86.25),
      LatLng(12.11, -86.24),
      LatLng(12.12, -86.23),
    ]);
  });

  test('reconoce un viaje ya iniciado sin volver a solicitar iniciarlo', () {
    const trip = Trip(
      id: '4790',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'Villa Fontana',
      destination: 'Las Colinas',
      date: '2026-10-27',
      packages: 2,
      status: 'En camino',
    );

    expect(isDriverTripInProgress(trip), isTrue);
  });

  test('presenta la cantidad de envíos como bultos', () {
    const trip = Trip(
      id: '4795',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'A',
      destination: 'B',
      date: '2026-10-27',
      packages: 2,
      status: 'Asignado',
    );

    expect(driverHomeQuantityLabel(trip), '2 bultos');
  });

  test('calcula el rumbo de avance para orientar el mapa', () {
    const from = LatLng(12.10, -86.25);
    const east = LatLng(12.10, -86.24);

    expect(driverNavigationBearing(from, east), closeTo(90, 1));
  });

  test('coloca el centro de la cámara delante del conductor', () {
    const driver = LatLng(12.10, -86.25);

    final target = driverNavigationCameraTarget(driver, 90);

    expect(target.latitude, closeTo(driver.latitude, .0001));
    expect(target.longitude, greaterThan(driver.longitude));
  });
}
