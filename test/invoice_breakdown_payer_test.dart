import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/invoice_breakdown.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

void main() {
  const options = [
    TripOptionSelection(
      code: 'shipment-insurance-a',
      title: 'Seguro',
      priceCs: 40,
    ),
  ];

  test('el destinatario no paga el seguro dentro del total del envío', () {
    final breakdown = buildInvoiceBreakdown(
      serviceMode: 'Envíos',
      transport: 'Auto',
      shippingCs: 160,
      baseCs: 160,
      serviceCs: 0,
      additionalCs: 0,
      weight: 2,
      weightUnit: 'kg',
      invoiceAmountCs: 150,
      invoiceAlreadyPaid: false,
      options: options,
      shipmentPayer: 'Destinatario',
    );

    expect(breakdown.shippingSubtotalCs, 160);
    expect(breakdown.totalCs, 310);
  });

  test('el remitente conserva el seguro dentro del total', () {
    final breakdown = buildInvoiceBreakdown(
      serviceMode: 'Envíos',
      transport: 'Auto',
      shippingCs: 160,
      baseCs: 160,
      serviceCs: 0,
      additionalCs: 0,
      weight: 2,
      weightUnit: 'kg',
      invoiceAmountCs: 150,
      invoiceAlreadyPaid: false,
      options: options,
      shipmentPayer: 'Remitente / Comercio',
    );

    expect(breakdown.shippingSubtotalCs, 200);
    expect(breakdown.totalCs, 350);
  });
}
