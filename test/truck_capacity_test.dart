import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/truck_capacity.dart';

void main() {
  test('expone las cinco capacidades nominales de camiones', () {
    expect(truckMaxWeightKgForLabel('Camión de 2 toneladas'), 2000);
    expect(truckMaxWeightKgForLabel('Camión de 4 toneladas'), 4000);
    expect(truckMaxWeightKgForLabel('Camión de 5.5 toneladas'), 5500);
    expect(truckMaxWeightKgForLabel('Camión de 7 toneladas'), 7000);
    expect(truckMaxWeightKgForLabel('Camión de 8 toneladas'), 8000);
  });

  test('recomienda el camión más pequeño que soporte la carga', () {
    expect(recommendedTruckForWeight(2001), 'Camión de 4 toneladas');
    expect(recommendedTruckForWeight(5500), 'Camión de 5.5 toneladas');
    expect(recommendedTruckForWeight(8000), 'Camión de 8 toneladas');
    expect(recommendedTruckForWeight(8001), isNull);
  });

  test('devuelve los camiones compatibles en orden de capacidad', () {
    expect(
      compatibleTrucksForWeight(5600),
      ['Camión de 7 toneladas', 'Camión de 8 toneladas'],
    );
  });

  test('reutiliza los iconos existentes por rango de camión', () {
    expect(
      truckAssetForLabel('Camión de 2 toneladas'),
      'assets/img/HomeCliente/carga_extra_pequeno.png',
    );
    expect(
      truckAssetForLabel('Camión de 5.5 toneladas'),
      'assets/img/HomeCliente/carga_mediano.png',
    );
    expect(
      truckAssetForLabel('Camión de 8 toneladas'),
      'assets/img/HomeCliente/carga_grande.png',
    );
  });
}
