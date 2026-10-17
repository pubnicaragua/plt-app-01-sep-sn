import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/shipment_payment_logic.dart';

void main() {
  test('Contado solo permite tarjeta', () {
    expect(
      shipmentPaymentMethodsFor('Contado'),
      ['Tarjeta'],
    );
  });

  test('Crédito solo permite efectivo y transferencia', () {
    expect(
      shipmentPaymentMethodsFor('Crédito'),
      ['Efectivo', 'Transferencia'],
    );
  });
}
