import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/envios.dart';

Trip _trip({
  String status = 'Asignado',
  bool isScheduled = false,
  String? serviceType,
  String? scheduledTime = '09:00 - 10:00',
}) {
  return Trip(
    id: '#4812',
    client: 'Cliente',
    driver: 'Conductor',
    origin: 'Origen',
    destination: 'Destino',
    date: '2026-10-06',
    packages: 1,
    status: status,
    isScheduled: isScheduled,
    serviceType: serviceType,
    scheduledTime: scheduledTime,
  );
}

void main() {
  test('solo muestra el horario en programados e historial', () {
    expect(shouldShowTripSchedule(_trip()), isFalse);
    expect(shouldShowTripSchedule(_trip(isScheduled: true)), isTrue);
    expect(shouldShowTripSchedule(_trip(status: 'Completado')), isTrue);
  });

  test('une la hora y el ID en una sola línea', () {
    expect(
      tripScheduleReference(_trip(isScheduled: true)),
      '09:00 - 10:00  •  #4812',
    );
  });
}
