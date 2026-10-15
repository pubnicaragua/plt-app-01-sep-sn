import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/resumen_cliente.dart';

Trip _trip({
  required String status,
  String date = '',
  String? completedAt,
  bool isScheduled = false,
  String? scheduledDate,
  double? invoiceAmountCs,
}) {
  return Trip(
    id: 'test',
    client: 'Cliente',
    driver: 'Conductor',
    origin: 'Origen',
    destination: 'Destino',
    date: date,
    packages: 1,
    status: status,
    completedAt: completedAt,
    isScheduled: isScheduled,
    scheduledDate: scheduledDate,
    invoiceAmountCs: invoiceAmountCs,
  );
}

void main() {
  final now = DateTime(2026, 10, 6, 15, 30);

  test('un viaje activo sin fecha cuenta como actividad de hoy', () {
    final date = summaryDateForTrip(_trip(status: 'En camino'), now);

    expect(date, DateTime(2026, 10, 6));
  });

  test('un viaje programado conserva su fecha programada', () {
    final date = summaryDateForTrip(
      _trip(
        status: 'Pendiente',
        isScheduled: true,
        scheduledDate: '2026-10-09',
      ),
      now,
    );

    expect(date, DateTime(2026, 10, 9));
  });

  test('un viaje finalizado conserva su fecha real', () {
    final date = summaryDateForTrip(
      _trip(status: 'Completado', date: '2026-10-02'),
      now,
    );

    expect(date, DateTime(2026, 10, 2));
  });

  test('el historial de facturas usa completedAt cuando date está vacío', () {
    final trip = _trip(
      status: 'Completado',
      completedAt: '2026-10-08T14:30:00Z',
    );

    expect(invoiceHistoryDateForTrip(trip), DateTime(2026, 10, 8));
  });

  test('los filtros de pago aceptan sus etiquetas en plural', () {
    final trip = _trip(status: 'Completado');

    expect(invoicePaymentMatchesFilter(trip, 'Pendientes'), isTrue);
    expect(invoicePaymentMatchesFilter(trip, 'Pagadas'), isFalse);
    expect(invoicePaymentMatchesFilter(trip, 'Todas'), isTrue);
  });

  test('el historial usa el estado de pago del servicio igual que la factura', () {
    expect(
      invoicePaymentStatusForTrip(
        Trip(
          id: 'test',
          client: 'Cliente',
          driver: 'Conductor',
          origin: 'Origen',
          destination: 'Destino',
          date: '',
          packages: 1,
          status: 'Completado',
          servicePaymentStatus: 'Pagado',
        ),
      ),
      'Pagada',
    );
  });

  test('el historial reconoce auto y no lo muestra como camión pequeño', () {
    final trip = Trip(
      id: 'test',
      client: 'Cliente',
      driver: 'Conductor',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-13',
      packages: 1,
      status: 'Completado',
      transport: 'Auto',
    );

    expect(invoiceHistoryVehicleLabel(trip, isTrip: false), 'AUTO');
  });

  test('el total general cuenta registros y no montos', () {
    expect(
      summaryTripCount([
        _trip(status: 'Completado'),
        _trip(status: 'En camino'),
      ]),
      2,
    );
  });

  test('el total de facturas incluye envíos aún activos', () {
    expect(
      summaryInvoiceTotal([
        _trip(status: 'Pendiente', invoiceAmountCs: 150),
      ]),
      150,
    );
  });

  test('los periodos de facturas suman montos por fecha', () {
    final trip = _trip(
      status: 'Completado',
      date: '2026-10-06',
      invoiceAmountCs: 150,
    );
    final today = DateTime(2026, 10, 6, 15, 30);

    expect(
      summaryInvoiceTotalInRange(
        [trip],
        DateTimeRange(
          start: DateTime(2026, 10, 6),
          end: DateTime(2026, 10, 7),
        ),
        today,
      ),
      150,
    );
    expect(
      summaryInvoiceTotalInRange(
        [trip],
        DateTimeRange(
          start: DateTime(2026, 10, 7),
          end: DateTime(2026, 10, 8),
        ),
        today,
      ),
      0,
    );
  });
}
