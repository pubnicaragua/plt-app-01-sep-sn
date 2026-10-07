import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/shipment_flow.dart';

void main() {
  test('un flujo normal termina en seguimiento en vivo', () {
    expect(
      completionRouteForShipment(isScheduled: false),
      ShipmentCompletionRoute.tracking,
    );
  });

  test('un flujo iniciado con Programar termina en asignación', () {
    expect(
      completionRouteForShipment(isScheduled: true),
      ShipmentCompletionRoute.assignment,
    );
  });
}
