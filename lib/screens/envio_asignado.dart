import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/sprite_truck_animation.dart';
import 'pedido.dart';

class EnvioAsignadoScreen extends StatelessWidget {
  const EnvioAsignadoScreen({super.key, required this.trip});

  final Trip trip;

  String _dateLabel() {
    final date = trip.scheduledDate;
    if (date == null || date.trim().isEmpty) return 'Lo antes posible';
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.day.toString().padLeft(2, '0')} '
        '${_month(parsed.month)} ${parsed.year} · ${trip.scheduledTime ?? ''}';
  }

  String _month(int value) => const [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ][value.clamp(1, 12).toInt()];

  String _serviceLabel() {
    final scheduled = trip.serviceType == 'Programado' || trip.isScheduled;
    if (trip.serviceMode == 'Taxi Privado') {
      return scheduled ? 'Viaje programado' : 'Viaje';
    }
    if (scheduled) {
      return trip.transport == 'Camión'
          ? 'Retiro y entrega programado'
          : 'Envío programado';
    }
    return trip.transport == 'Camión' ? 'Retiro y entrega' : 'Envío';
  }

  @override
  Widget build(BuildContext context) {
    final isTruck = trip.transport == 'Camión';
    final isTaxi = trip.serviceMode == 'Taxi Privado';
    final isScheduled = trip.isScheduled || trip.serviceType == 'Programado';
    final isAssigned = trip.status.trim().toLowerCase() == 'asignado';
    final scheduledWaiting = isScheduled && !isAssigned;
    final title = scheduledWaiting
        ? isTruck
            ? '¡Camión programado!'
            : trip.serviceMode == 'Taxi Privado'
                ? '¡Viaje programado!'
                : '¡Envío programado!'
        : isTruck
            ? '¡Camión asignado!'
            : trip.serviceMode == 'Taxi Privado'
                ? '¡Viaje asignado!'
                : '¡Envío asignado!';
    final description = scheduledWaiting
        ? 'Tu solicitud fue guardada para la fecha y hora elegidas. La asignación del conductor se realizará cuando inicie el servicio.'
        : isScheduled
            ? 'Hemos asignado un conductor para tu fecha programada y tu solicitud ha sido creada con éxito.'
            : 'Hemos asignado un conductor y tu solicitud ha sido creada con éxito.';
    return Scaffold(
      backgroundColor: navy,
      body: EstadoBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(isTruck ? 'Camiones' : isTaxi ? 'Viajes' : 'Envíos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree')),
                    ),
                    SizedBox(
                      width: 32,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 19),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  children: [
                    SizedBox(
                      height: 220,
                      child: isTruck
                          ? const SpriteTruckAnimation(
                              asset:
                                  'assets/img/EstadosCrearEnvio/camion_asignacion_sprite.png',
                            )
                          : Image.asset(
                              'assets/img/HomeCliente/vehiculo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Colors.white,
                                  size: 120),
                            ),
                    ),
                    const SizedBox(height: 8),
                    AppGlassSurface(
                      borderRadius: 18,
                      fillColor: const Color(0x8A082665),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 19),
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFF19C979),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF19C979)
                                          .withValues(alpha: .42),
                                      blurRadius: 18),
                                ],
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 37),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Figtree'),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  height: 1.25,
                                  fontFamily: 'Figtree'),
                            ),
                            const SizedBox(height: 14),
                            Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: .22)),
                            const SizedBox(height: 12),
                            _AssignmentLine(
                                label: 'Fecha programada', value: _dateLabel()),
                            _AssignmentLine(
                                label: 'N.º de ticket',
                                value: '#${trip.id.isEmpty ? 'PENDIENTE' : trip.id}'),
                            _AssignmentLine(
                                label: 'Servicio', value: _serviceLabel()),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: .18)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.notifications_none_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                        'Te notificaremos cuando el conductor esté en ruta',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontFamily: 'Figtree')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: .22)),
                            const SizedBox(height: 9),
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MisEnvios()),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Text(
                                  trip.isScheduled ||
                                          trip.serviceType == 'Programado'
                                      ? 'Puedes ver más detalles en envíos programados'
                                      : 'Puedes ver más detalles en envíos',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Figtree'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
                child: GlassButton(
                  label: 'Regresar al inicio',
                  filled: true,
                  height: 45,
                  fontSize: 12,
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentLine extends StatelessWidget {
  const _AssignmentLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontFamily: 'Figtree')),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree')),
            ),
          ],
        ),
      );
}
