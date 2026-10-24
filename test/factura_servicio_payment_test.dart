import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/finalizar_viaje.dart';

void main() {
  test('la factura usa el pago del envío y no el del producto', () {
    final trip = Trip(
      id: 'envio-1',
      client: 'Cliente',
      driver: 'Conductor',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-13',
      packages: 1,
      status: 'Completado',
      invoiceStatus: 'Pagado',
      invoicePaymentMethod: 'Transferencia',
      servicePaymentStatus: 'Pagado',
      servicePaymentMethod: 'Efectivo',
      description:
          'Estado factura producto: Pagado · Método factura producto: Transferencia · Estado pago envío: Crédito · Método pago envío: Tarjeta · Quién paga envío: Destinatario',
    );

    expect(invoiceServicePaymentStatusForTrip(trip), 'Crédito');
    expect(invoiceServicePaymentMethodForTrip(trip), 'Tarjeta');
    expect(invoiceServicePayerForTrip(trip), 'Destinatario');
  });

  test('la factura de un viaje contado permite efectivo y tarjeta', () {
    final trip = Trip(
      id: 'viaje-1',
      client: 'Cliente',
      driver: 'Conductor',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-13',
      packages: 1,
      status: 'Completado',
      serviceMode: 'Viaje',
      servicePaymentStatus: 'Contado',
      servicePaymentMethod: 'Efectivo',
    );

    expect(invoiceServicePaymentMethodsForTrip(trip), ['Efectivo', 'Tarjeta']);
    expect(invoiceServicePaymentMethodForTrip(trip), 'Efectivo');
  });
}
