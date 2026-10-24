import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/place_history.dart';
import 'package:incoex_logistics_app/screens/crear_envio1.dart';

void main() {
  test('la moto de viajes permite un pasajero', () {
    expect(maxPassengersForTripVehicle('Moto'), 1);
    expect(maxPassengersForTripVehicle('Sedán'), 4);
    expect(maxPassengersForTripVehicle('SUV'), 6);
    expect(maxPassengersForTripVehicle('Microbus'), 12);
  });

  test('moto aparece como primera opción de viajes', () {
    expect(tripVehicleOptions.first, 'Moto');
  });

  test('un lugar guardado llena el campo con su dirección exacta', () {
    const place = SavedPlace(
      placeId: 'sabana-grande',
      address: 'Sabana Grande, Managua, Nicaragua',
      main: 'Sabana Grande',
      secondary: 'Managua, Nicaragua',
    );

    expect(
      destinationEditingValueForSavedPlace(place).text,
      'Sabana Grande, Managua, Nicaragua',
    );
  });
}
