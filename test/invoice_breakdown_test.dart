import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/invoice_breakdown.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

void main() {
  test('la factura de carga muestra peso, factura y cada adicional', () {
    final breakdown = buildInvoiceBreakdown(
      serviceMode: 'Envíos',
      transport: 'Camión',
      shippingCs: 150,
      baseCs: 60,
      serviceCs: 15,
      additionalCs: 75,
      weight: 2,
      weightUnit: 'kg',
      invoiceAmountCs: 300,
      invoiceAlreadyPaid: false,
      options: const [
        TripOptionSelection(
          code: 'cargo-helper',
          title: 'Ayudante',
          priceCs: 40,
          currency: 'NIO',
        ),
      ],
    );

    expect(breakdown.baseLabel, 'Tarifa base de carga');
    expect(
      breakdown.lines.map((line) => line.label).toList(),
      ['Factura', 'Tarifa base de carga', 'Servicio y gestión logística',
        'Carga adicional (2 kg)', 'Ayudante'],
    );
    expect(breakdown.shippingSubtotalCs, 190);
    expect(breakdown.totalCs, 490);
  });

  test('la factura de viaje no agrega conceptos de producto', () {
    final breakdown = buildInvoiceBreakdown(
      serviceMode: 'Taxi Privado',
      transport: 'Vehículo',
      shippingCs: 200,
      baseCs: 160,
      serviceCs: 15,
      additionalCs: 25,
      weight: 2,
      weightUnit: 'kg',
      invoiceAmountCs: 300,
      invoiceAlreadyPaid: false,
      options: const [
        TripOptionSelection(
          code: 'delivery-round-trip',
          title: 'Ida y vuelta',
          priceCs: 20,
          currency: 'NIO',
        ),
      ],
    );

    expect(breakdown.baseLabel, 'Tarifa base de viaje');
    expect(
      breakdown.lines.map((line) => line.label).toList(),
      ['Tarifa base de viaje', 'Servicio y gestión logística', 'Ida y vuelta'],
    );
    expect(breakdown.shippingSubtotalCs, 220);
    expect(breakdown.totalCs, 220);
  });
}
