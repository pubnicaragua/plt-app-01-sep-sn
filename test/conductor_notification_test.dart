import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/home_conductor.dart';

void main() {
  final trip = Trip(
    id: '4812',
    client: 'Cliente',
    driver: 'Juan',
    origin: 'Sabana Grande',
    destination: 'Metrocentro',
    date: '2026-10-29',
    packages: 3,
    status: 'Asignado',
    vehicleVariant: 'PICKUP',
    serviceMode: 'Envío',
    estimatedCostCs: 250,
  );

  test('builds the conductor notification route from the trip', () {
    expect(driverNewTripRouteLabel(trip), 'Sabana Grande → Metrocentro');
  });

  test('keeps the notification title concise', () {
    expect(driverNewTripNotificationTitle(trip), 'Nuevo viaje #4812');
  });

  test('uses the same quantity language shown in the conductor home', () {
    expect(driverNewTripQuantityLabel(trip), '3 bultos');
  });

  test('exposes the assigned service label for the notification card', () {
    expect(driverNewTripServiceLabel(trip), 'PICKUP');
  });
}
