import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import 'confirmar_entrega.dart';

class ViajeEnCurso extends StatefulWidget {
  const ViajeEnCurso({super.key, required this.trip});

  final Trip trip;

  @override
  State<ViajeEnCurso> createState() => _ViajeEnCursoState();
}

class _ViajeEnCursoState extends State<ViajeEnCurso> {
  bool updating = false;

  Future<void> _arrived() async {
    if (updating) return;
    setState(() => updating = true);
    try {
      final updated = await apiClient.updateTripStatus(widget.trip.id, 'En entrega');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmarEntrega(trip: updated),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No se pudo actualizar. Verifica tu conexión.',
              style: TextStyle(fontFamily: 'Acumin Pro'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final distance = trip.distanceKm ?? 4.2;
    final eta = math.max(6, (distance * 2.8).round());
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F52),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1D4D),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Viaje en curso',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        Text(
                          trip.id,
                          style: const TextStyle(
                            color: Color(0xFF9FB2DC),
                            fontSize: 11.5,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TinyStat(
                    icon: Icons.alt_route_rounded,
                    value: '${distance.toStringAsFixed(1)} km',
                    label: 'Restantes',
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withValues(alpha: .16),
                  ),
                  _TinyStat(
                    icon: Icons.access_time_filled,
                    value: '$eta min',
                    label: 'ETA Llegada',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RouteMapPainter(),
                  ),
                ),
                Positioned(
                  top: 26,
                  right: 30,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: const Color(0xFFE5484D),
                    size: 46,
                    shadows: const [
                      Shadow(
                        color: Color(0x55E5484D),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 235,
                  left: 42,
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D47D9),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _DeliverySheet(trip: trip, onArrived: _arrived, updating: updating),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9FB2DC),
            fontSize: 9.5,
            fontFamily: 'Acumin Pro',
          ),
        ),
      ],
    );
  }
}

class _DeliverySheet extends StatelessWidget {
  const _DeliverySheet({
    required this.trip,
    required this.onArrived,
    required this.updating,
  });

  final Trip trip;
  final VoidCallback onArrived;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF101E4A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: .12)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Color(0xFFE5484D), size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINO DE ENTREGA',
                      style: TextStyle(
                        color: Color(0xFF9FB2DC),
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showHelp(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .10),
                    border: Border.all(color: glassBorder),
                  ),
                  child: const Text(
                    '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  color: Color(0xFF0D47D9), size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trip.recipientName ?? trip.contactName ?? 'Cliente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: glassBorder),
                ),
                child: Text(
                  '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF9FB2DC), size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Entregar en recepción, piso 4',
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 12.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
          if (trip.estimatedCostCs != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: mint, size: 17),
                const SizedBox(width: 10),
                Text(
                  'Precio del viaje: C\$${trip.estimatedCostCs!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: mint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: const BorderSide(
                        color: Color(0xFF0D47D9),
                        width: 1.4,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => _contact(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call_rounded,
                              color: Color(0xFF0D47D9), size: 19),
                          SizedBox(width: 8),
                          Text(
                            'Contactar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: Material(
                    color: updating ? const Color(0xFF0B3DBB) : const Color(0xFF0D47D9),
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: onArrived,
                      child: Center(
                        child: updating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Llegué al destino',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Acumin Pro',
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _contact(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1D4D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contactar cliente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${trip.recipientName ?? trip.contactName ?? 'Cliente'}\n'
                '${trip.contactPhone ?? trip.recipientPhone ?? 'Sin teléfono registrado'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0B1D4D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ayuda del viaje',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sigue la ruta marcada en el mapa hasta el destino.\n'
                'Si tienes inconvenientes con la entrega, contacta al cliente\n'
                'o reporta la incidencia desde el botón «?».',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 13,
                  height: 1.55,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      color: cyan,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fondo del mapa (gris claro tipo Google Maps)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8ECF2),
    );

    // Calles: cuadrícula de bloques
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 26;
    final streetThin = Paint()
      ..color = Colors.white
      ..strokeWidth = 14;

    final grid = [
      (Offset(0, size.height * .22), Offset(size.width, size.height * .20)),
      (Offset(0, size.height * .56), Offset(size.width, size.height * .62)),
      (Offset(0, size.height * .84), Offset(size.width, size.height * .80)),
      (Offset(size.width * .30, 0), Offset(size.width * .36, size.height)),
      (Offset(size.width * .72, 0), Offset(size.width * .64, size.height)),
    ];
    for (final (from, to) in grid) {
      canvas.drawLine(from, to, streetThin);
    }
    canvas.drawLine(
      Offset(-30, size.height * .06),
      Offset(size.width * .58, size.height * .04),
      street,
    );
    canvas.drawLine(
      Offset(size.width * .24, size.height + 30),
      Offset(size.width * .92, size.height * .70),
      street,
    );

    // Ruta polilínea en azul con esquinas redondeadas
    final route = Path()
      ..moveTo(size.width * .115, size.height * .76)
      ..lineTo(size.width * .115, size.height * .60)
      ..quadraticBezierTo(
          size.width * .115, size.height * .545,
          size.width * .185, size.height * .52)
      ..lineTo(size.width * .40, size.height * .465)
      ..quadraticBezierTo(
          size.width * .455, size.height * .455,
          size.width * .455, size.height * .40)
      ..lineTo(size.width * .455, size.height * .235)
      ..quadraticBezierTo(
          size.width * .455, size.height * .185,
          size.width * .51, size.height * .175)
      ..lineTo(size.width * .70, size.height * .135);

    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF0D47D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
