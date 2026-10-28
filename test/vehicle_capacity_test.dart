import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/vehicle_capacity.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

void main() {
  test('mantiene los límites internos solicitados por vehículo', () {
    expect(maxWeightKgForVehicle('Moto'), 10);
    expect(maxWeightKgForVehicle('Vehículo'), 400);
    expect(maxWeightKgForVehicle('Pickup'), 900);
    expect(maxWeightKgForVehicle('VAN'), 650);
  });

  test('recomienda el vehículo más pequeño que soporte el peso', () {
    expect(recommendedVehicleForWeight(10), 'Moto');
    expect(recommendedVehicleForWeight(11), 'Vehículo');
    expect(recommendedVehicleForWeight(401), 'VAN');
    expect(recommendedVehicleForWeight(651), 'Pickup');
    expect(recommendedVehicleForWeight(901), isNull);
  });

  test('convierte libras a kilogramos antes de validar', () {
    expect(weightToKg(22.0462, 'lb'), closeTo(10, .001));
  });

  test('lista todos los vehículos compatibles ordenados por capacidad', () {
    expect(
      compatibleVehiclesForWeight(500),
      ['VAN', 'Pickup'],
    );
  });

  test('calcula la tarifa alternativa usando los kilómetros del viaje', () {
    expect(
      estimatedShippingForVehicle(vehicle: 'VAN', distanceKm: 20),
      385,
    );
    expect(
      estimatedShippingForVehicle(
        vehicle: 'Pickup',
        distanceKm: 20,
        configuredRates: {
          'Pickup': VehicleRate(
            baseFeeCs: 100,
            farePerKmCs: 10,
            includedKm: 5,
          ),
        },
      ),
      250,
    );
  });
}
