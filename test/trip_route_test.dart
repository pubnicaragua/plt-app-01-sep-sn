import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/trip_routing.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

Trip _scheduledTrip({
  String scheduledDate = '2026-10-10',
  String scheduledTime = '09:30',
}) {
  return Trip(
    id: 'test',
    client: 'Cliente',
    driver: 'Sin asignar',
    origin: 'Origen',
    destination: 'Destino',
    date: '2026-10-06',
    packages: 1,
    status: 'Pendiente',
    serviceType: 'Programado',
    isScheduled: true,
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
  );
}

void main() {
  test('un auto con modo Envíos no se clasifica como viaje', () {
    expect(isTripServiceMode('Envíos'), isFalse);
  });

  test('Taxi Privado sí se clasifica como viaje', () {
    expect(isTripServiceMode('Taxi Privado'), isTrue);
  });

  test('Viajes deben pasar por facturación antes de crear el viaje', () {
    expect(shouldShowBillingBeforeCreation('Taxi Privado'), isTrue);
    expect(shouldShowBillingBeforeCreation('Envíos'), isFalse);
  });

  test('antes de recoger, la ruta incluye el punto de recogida', () {
    expect(shouldRouteThroughPickup('Asignado'), isTrue);
    expect(shouldRouteThroughPickup('En camino'), isTrue);
  });

  test('después de recoger, la ruta continúa hacia la entrega', () {
    expect(shouldRouteThroughPickup('Recogió'), isFalse);
    expect(shouldRouteThroughPickup('En viaje'), isFalse);
  });

  test('un programado bloquea el mapa antes de su fecha y hora', () {
    final trip = _scheduledTrip();

    expect(
      isScheduledBeforeStart(trip, DateTime(2026, 10, 10, 9, 29)),
      isTrue,
    );
    expect(
      isScheduledBeforeStart(trip, DateTime(2026, 10, 10, 9, 30)),
      isFalse,
    );
  });
}
