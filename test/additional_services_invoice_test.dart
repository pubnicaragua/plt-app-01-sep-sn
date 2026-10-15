import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/invoice_breakdown.dart';
import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/crear_envio2.dart';

void main() {
  test('un adicional sin catálogo llega a la factura con su cantidad', () {
    final option = fallbackAdditionalServiceOption(
      'delivery-more-vehicles',
      title: '¿Más motos?',
    );

    expect(option, isNotNull);
    for (final code in [
      'delivery-round-trip',
      'delivery-multiple-stops',
      'delivery-waiting',
      'cargo-helper',
      'cargo-more-trucks',
      'cargo-round-trip',
      'cargo-multiple-stops',
    ]) {
      expect(fallbackAdditionalServiceOption(code), isNotNull, reason: code);
    }
    final breakdown = buildInvoiceBreakdown(
      serviceMode: 'Envíos',
      transport: 'Moto',
      shippingCs: 60,
      baseCs: 60,
      serviceCs: 0,
      additionalCs: 0,
      weight: 1,
      weightUnit: 'kg',
      invoiceAmountCs: 0,
      invoiceAlreadyPaid: false,
      options: [
        TripOptionSelection(
          code: option!.code,
          title: option.title,
          priceCs: option.priceCs,
          currency: option.currency,
          quantity: 2,
        ),
      ],
      dollarRate: 36.5,
    );

    expect(breakdown.lines.last.label, '¿Más motos? (x2)');
    expect(breakdown.lines.last.amountCs, 2920);
  });
}
