import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/screens/resumen_cliente.dart';

void main() {
  test('el tooltip formatea el total de envíos', () {
    expect(weeklyChartValueLabel(1250, 'Envíos'), 'Envíos: 1,250');
  });

  test('el tooltip formatea el total de viajes', () {
    expect(weeklyChartValueLabel(3, 'Viajes'), 'Viajes: 3');
  });
}
