import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/viaje_asignado.dart';

void main() {
  test('describe el servicio y vehículo que recibirá el conductor', () {
    const trip = Trip(
      id: '4790',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'Villa Fontana',
      destination: 'Las Colinas',
      date: '2026-08-27',
      packages: 2,
      status: 'Asignado',
      serviceMode: 'Envíos',
      vehicleVariant: 'Pickup',
      transport: 'Vehículo',
    );

    expect(conductorServiceLabel(trip), 'Envíos · Pickup');
    expect(conductorVehicleLabel(trip), 'Pickup');
    expect(conductorQuantityLabel(trip), '2 paquetes');
  });

  test('describe un viaje con pasajeros y servicio Minibus', () {
    const trip = Trip(
      id: '4791',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'Managua',
      destination: 'Masaya',
      date: '2026-08-27',
      packages: 0,
      status: 'Asignado',
      serviceMode: 'Taxi Privado',
      vehicleVariant: 'Minibus',
      passengerCount: 36,
    );

    expect(conductorServiceLabel(trip), 'Viajes · Minibus');
    expect(conductorVehicleLabel(trip), 'Minibus');
    expect(conductorQuantityLabel(trip), '36 pasajeros');
  });

  test('muestra pago, método e instrucciones sin metadatos internos', () {
    const trip = Trip(
      id: '4792',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'A',
      destination: 'B',
      date: '2026-08-27',
      packages: 1,
      status: 'Asignado',
      description:
          'Entregar en recepción · Estado pago envío: Pendiente · Método pago envío: Efectivo [INCOEX_RETURN_AT=10:30;MODE=scheduled]',
      servicePaymentStatus: 'Sin pagar',
      servicePaymentMethod: 'Efectivo',
    );

    expect(conductorPaymentLabel(trip), 'Pendiente · Efectivo');
    expect(conductorInstructionText(trip), 'Entregar en recepción');
  });

  test('usa el pago general cuando el campo de servicio llega vacío', () {
    const trip = Trip(
      id: '4794',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'A',
      destination: 'B',
      date: '2026-08-27',
      packages: 1,
      status: 'Asignado',
      servicePaymentStatus: '',
      servicePaymentMethod: '',
      paymentStatus: 'Pagado',
      paymentMethod: 'Transferencia',
    );

    expect(conductorPaymentLabel(trip), 'Pagado · Transferencia');
  });

  test('usa la fecha programada y la hora recibidas por la API', () {
    const trip = Trip(
      id: '4793',
      client: 'Cliente',
      driver: 'Juan',
      origin: 'A',
      destination: 'B',
      date: '2026-08-27',
      packages: 1,
      status: 'Asignado',
      scheduledDate: '2026-10-26',
      scheduledTime: '07:15 AM',
    );

    expect(conductorScheduleLabel(trip), 'Lunes, 26 octubre 2026 · 07:15 AM');
  });
}
