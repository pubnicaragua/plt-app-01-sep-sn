import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/shipment_payment_logic.dart';

void main() {
  test('Contado permite efectivo, transferencia y tarjeta', () {
    expect(
      shipmentPaymentMethodsFor('Contado'),
      ['Efectivo', 'Transferencia', 'Tarjeta'],
    );
  });

  test('Crédito solo permite transferencia y tarjeta', () {
    expect(
      shipmentPaymentMethodsFor('Crédito'),
      ['Transferencia', 'Tarjeta'],
    );
  });
}
