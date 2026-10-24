import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/map_tap_place.dart';

void main() {
  test('construye un lugar seleccionable desde la respuesta de geocodificación', () {
    final place = placeFromGeocode(
      latitude: 12.1364,
      longitude: -86.2514,
      result: const {
        'formatted_address': 'Managua, Nicaragua',
        'address_components': [
          {'long_name': 'Managua', 'types': ['locality']},
          {'long_name': 'Nicaragua', 'types': ['country']},
        ],
      },
    );

    expect(place.description, 'Managua, Nicaragua');
    expect(place.main, 'Managua');
    expect(place.secondary, 'Nicaragua');
    expect(place.latitude, 12.1364);
    expect(place.longitude, -86.2514);
  });
}
