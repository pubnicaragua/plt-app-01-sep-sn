import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/driver_payment_summary.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

Trip _trip({
  String description = '',
  String? paymentStatus,
  String? paymentMethod,
  double? paymentAmount,
  String? paymentRef,
}) {
  return Trip(
    id: '#4812',
    client: 'Cliente',
    driver: 'Juan',
    origin: 'Origen',
    destination: 'Destino',
    date: '2026-10-29',
    packages: 1,
    status: 'En entrega',
    description: description,
    invoiceAmountCs: 500,
    estimatedCostCs: 240,
    paymentStatus: paymentStatus,
    paymentMethod: paymentMethod,
    paymentAmount: paymentAmount,
    paymentRef: paymentRef,
  );
}

void main() {
  test('lee el producto pendiente y que el destinatario paga en efectivo', () {
    final summary = driverPaymentSummaryFor(_trip(
      description: 'Valor de factura C\$500 · Estado factura producto: Pendiente · '
          'Método factura producto: Efectivo · Estado pago envío: Sin pagar · '
          'Quién paga envío: Destinatario',
      paymentStatus: 'Sin pagar',
    ));

    expect(summary.productAmount, 500);
    expect(summary.productPaid, isFalse);
    expect(summary.productMethod, 'Efectivo');
    expect(summary.recipientPays, isTrue);
    expect(summary.totalToCollect, 740);
    expect(summary.complete, isFalse);
  });

  test('reconoce producto pagado y servicio pagado por tarjeta', () {
    final summary = driverPaymentSummaryFor(_trip(
      description: 'Valor de factura C\$500 · Estado factura producto: Pagado · '
          'Método factura producto: Tarjeta · Quién paga envío: Remitente / Comercio',
      paymentStatus: 'Pagado',
      paymentMethod: 'Tarjeta',
    ));

    expect(summary.productPaid, isTrue);
    expect(summary.productMethod, 'Tarjeta / link de pago');
    expect(summary.servicePaid, isTrue);
    expect(summary.complete, isTrue);
    expect(summary.totalToCollect, 0);
  });

  test('considera crédito del remitente como liquidado para continuar', () {
    final summary = driverPaymentSummaryFor(_trip(
      description: 'Estado pago envío: Crédito · Método pago envío: Efectivo · '
          'Quién paga envío: Remitente / Comercio',
      paymentStatus: 'Sin pagar',
      paymentMethod: 'Efectivo',
    ));

    expect(summary.serviceCredit, isTrue);
    expect(summary.serviceSettled, isTrue);
    expect(summary.complete, isTrue);
    expect(driverServicePaymentStatusLabel(summary), 'Crédito');
  });

  test('mantiene pendiente el efectivo del destinatario hasta que el conductor cobre', () {
    final summary = driverPaymentSummaryFor(_trip(
      description: 'Estado pago envío: Contado · Método pago envío: Efectivo · '
          'Quién paga envío: Destinatario',
      paymentStatus: 'Pagado',
      paymentMethod: 'Efectivo',
      paymentAmount: 240,
    ));

    expect(summary.recipientPays, isTrue);
    expect(summary.servicePaid, isFalse);
    expect(summary.serviceNeedsCollection, isTrue);
    expect(driverServicePaymentStatusLabel(summary), 'Pendiente');
  });

  test('reconoce el cobro del conductor para un pago del destinatario', () {
    final summary = driverPaymentSummaryFor(_trip(
      description: 'Estado pago envío: Contado · Método pago envío: Efectivo · '
          'Quién paga envío: Destinatario',
      paymentStatus: 'Pagado',
      paymentMethod: 'Efectivo',
      paymentAmount: 240,
      paymentRef: 'DRIVER_CONFIRMED-123',
    ));

    expect(summary.servicePaid, isTrue);
    expect(summary.serviceNeedsCollection, isFalse);
  });
}
