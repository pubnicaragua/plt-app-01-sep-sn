import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/core/theme.dart';
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
  test('usa etiqueta amarilla y texto negro para viajes en clientes', () {
    expect(clientServiceTagColor(isTrip: true), const Color(0xFFFFC928));
    expect(clientServiceTagTextColor(isTrip: true), Colors.black);
    expect(clientServiceTagFontSize(isTrip: true), greaterThan(11));
  });

  test('mantiene etiqueta azul para envíos en clientes', () {
    expect(clientServiceTagColor(isTrip: false), accentBlue);
    expect(clientServiceTagTextColor(isTrip: false), Colors.white);
    expect(clientServiceTagFontSize(isTrip: false), 12);
  });

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
