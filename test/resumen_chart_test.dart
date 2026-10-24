import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/resumen_cliente.dart';

void main() {
  test('el tooltip formatea el total de envíos', () {
    expect(weeklyChartValueLabel(1250, 'Envíos'), 'Envíos: 1,250');
  });

  test('el tooltip formatea el total de viajes', () {
    expect(weeklyChartValueLabel(3, 'Viajes'), 'Viajes: 3');
  });

  test('reconoce como programado un viaje marcado por serviceMode', () {
    final trip = Trip(
      id: 'EN-1',
      client: 'Cliente',
      driver: 'Sin asignar',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-22',
      packages: 1,
      status: 'Pendiente',
      serviceMode: 'Programado',
      scheduledDate: '2026-10-24',
    );

    expect(isScheduledTrip(trip), isTrue);
    expect(isScheduledPendingForChart(trip), isTrue);
  });

  test('un programado pasa a realizado cuando está activo', () {
    final trip = Trip(
      id: 'EN-2',
      client: 'Cliente',
      driver: 'Conductor',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-22',
      packages: 1,
      status: 'En camino',
      serviceMode: 'Programado',
      scheduledDate: '2026-10-24',
    );

    expect(isScheduledPendingForChart(trip), isFalse);
  });

  test('un programado con camión asignado sigue siendo programado', () {
    final trip = Trip(
      id: 'EN-3',
      client: 'Cliente',
      driver: 'Conductor',
      origin: 'Origen',
      destination: 'Destino',
      date: '2026-10-22',
      packages: 1,
      status: 'Asignado',
      isScheduled: true,
      scheduledDate: '2026-10-24',
    );

    expect(isScheduledPendingForChart(trip), isTrue);
  });
}
