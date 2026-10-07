import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/envios.dart';

Trip _trip({
  String? vehicleVariant,
  String? truckType,
  String? transport,
  String? description,
}) {
  return Trip(
    id: 'test',
    client: 'Cliente',
    driver: 'Conductor',
    origin: 'Origen',
    destination: 'Destino',
    date: '2026-10-06',
    packages: 1,
    status: 'En camino',
    vehicleVariant: vehicleVariant,
    truckType: truckType,
    transport: transport,
    description: description,
  );
}

void main() {
  test('usa el vehículo taxi guardado en un viaje nuevo', () {
    final trip = _trip(vehicleVariant: 'SUV', transport: 'Vehículo');

    expect(vehicleLabelForTrip(trip), 'SUV');
    expect(vehicleAssetForTrip(trip), 'assets/img/HomeCliente/taxi_suv.png');
  });

  test('recupera el vehículo desde la descripción de un viaje antiguo', () {
    final trip = _trip(
      transport: 'Vehículo',
      description: 'Tipo de vehículo: Microbus',
    );

    expect(vehicleLabelForTrip(trip), 'MICROBUS');
    expect(
      vehicleAssetForTrip(trip),
      'assets/img/HomeCliente/taxi_microbus.png',
    );
  });

  test('usa el asset de auto como fallback si no hay variante guardada', () {
    final trip = _trip(transport: 'Vehículo');

    expect(vehicleLabelForTrip(trip), 'AUTO');
    expect(vehicleAssetForTrip(trip), 'assets/img/HomeCliente/figma_auto.png');
  });
}
