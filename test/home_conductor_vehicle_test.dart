import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/home_conductor.dart';

void main() {
  test('uses the conductor profile vehicle before the assigned trip vehicle', () {
    final profile = SessionUser(
      id: 'driver-1',
      email: 'driver@example.com',
      role: 'driver',
      displayName: 'Juan',
      vehicle: 'SUV',
      plate: 'M 123456',
    );
    final fallbackTrip = Trip(
      id: 'trip-1',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-28',
      packages: 1,
      status: 'Asignado',
      vehicleVariant: 'MOTO',
    );

    final result = resolveDriverVehicleInfo(profile, fallbackTrip);

    expect(result.label, 'SUV');
    expect(result.plate, 'M 123456');
    expect(result.asset, 'assets/img/HomeCliente/taxi_suv.png');
  });

  test('uses the assigned trip vehicle when the profile has no vehicle', () {
    final fallbackTrip = Trip(
      id: 'trip-2',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-28',
      packages: 1,
      status: 'Asignado',
      vehicleVariant: 'MOTO',
    );

    final result = resolveDriverVehicleInfo(null, fallbackTrip);

    expect(result.label, 'MOTO');
    expect(result.asset, 'assets/img/HomeCliente/figma_moto.png');
  });

  test('maps a saved truck vehicle to the cargo asset', () {
    final profile = SessionUser(
      id: 'driver-2',
      email: 'driver@example.com',
      role: 'driver',
      displayName: 'Juan',
      vehicle: 'Camión',
      plate: 'M 654321',
    );

    final result = resolveDriverVehicleInfo(profile, null);

    expect(result.label, 'CAMIÓN');
    expect(result.asset, 'assets/img/HomeCliente/figma_carga.png');
    expect(result.plate, 'M 654321');
  });

  test('a refreshed profile produces the refreshed vehicle presentation', () {
    SessionUser profile(String vehicle, String plate) => SessionUser(
          id: 'driver-3',
          email: 'driver@example.com',
          role: 'driver',
          displayName: 'Juan',
          vehicle: vehicle,
          plate: plate,
        );

    final first = resolveDriverVehicleInfo(profile('Moto', 'M 111111'), null);
    final second = resolveDriverVehicleInfo(profile('SUV', 'M 222222'), null);

    expect(first.asset, 'assets/img/HomeCliente/figma_moto.png');
    expect(second.asset, 'assets/img/HomeCliente/taxi_suv.png');
    expect(second.plate, 'M 222222');
  });
}
