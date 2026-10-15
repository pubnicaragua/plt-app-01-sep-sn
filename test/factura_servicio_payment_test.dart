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
          'Estado factura producto: Pagado · Método factura producto: Transferencia · Estado pago envío: Crédito · Método pago envío: Tarjeta',
    );

    expect(invoiceServicePaymentStatusForTrip(trip), 'Crédito');
    expect(invoiceServicePaymentMethodForTrip(trip), 'Tarjeta');
  });
}
