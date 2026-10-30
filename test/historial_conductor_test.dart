import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/historial_conductor.dart';

Trip makeTrip(String id, String status, double? amount) => Trip(
      id: id,
      client: 'Cliente',
      driver: 'Juan Pérez',
      origin: 'Origen',
      destination: 'Destino',
      date: '29-oct',
      packages: 1,
      status: status,
      estimatedCostCs: amount,
    );

void main() {
  test('suma solo los viajes completados con tarifa para total recaudado', () {
    final total = totalRecaudado([
      makeTrip('#1', 'Completado', 130),
      makeTrip('#2', 'Finalizado', 75),
      makeTrip('#3', 'Completado', null),
      makeTrip('#4', 'Cancelado', 400),
    ]);

    expect(total, 205);
  });
}
