import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'finalizar_viaje.dart';

class SeguimientoPedido extends StatefulWidget {
  const SeguimientoPedido({super.key, required this.trip, this.closeable = true});

  final Trip trip;
  final bool closeable;

  @override
  State<SeguimientoPedido> createState() => _SeguimientoPedidoState();
}

class _SeguimientoPedidoState extends State<SeguimientoPedido> {
  late Future<TrackingData> tracking;

  @override
  void initState() {
    super.initState();
    tracking = apiClient.getTracking(widget.trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.closeable,
        title: const Row(
          children: [
            Icon(Icons.radar_rounded, color: cyan, size: 20),
            SizedBox(width: 9),
            Text(
              'Seguimiento en Vivo',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 26),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusPill(text: trip.status, color: cyan),
                        Text(
                          'GUÍA: ${trip.id}',
                          style: const TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${trip.origin} → ${trip.destination}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPS Dinámico Managua · ${trip.date}',
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 11.5,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<TrackingData>(
                future: tracking,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const GlassCard(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 11),
                          Text(
                            'Coordinando señal GPS…',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final route = snapshot.data?.route ?? const <TrackingPoint>[];
                  if (route.isEmpty) {
                    return const GlassCard(
                      child: Text(
                        'Ruta aún sin puntos de GPS.\nEl conductor la compartirá al iniciar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IncoexMap(route: route),
                      const SizedBox(height: 14),
                      GlassCard(
                        color: figmaBlue.withValues(alpha: .30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < route.length; i++) ...[
                              _RouteRow(
                                index: i,
                                label: route[i].label,
                                last: i == route.length - 1,
                              ),
                              if (i != route.length - 1)
                                Container(
                                  margin: const EdgeInsets.only(left: 11),
                                  height: 22,
                                  width: 2,
                                  color: Colors.white.withValues(alpha: .25),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        shape: BoxShape.circle,
                        border: Border.all(color: glassBorder),
                      ),
                      child: Center(
                        child: Text(
                          initials(trip.driver),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.driver,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const Text(
                            'Conductor asignado por INCOEX',
                            style: TextStyle(
                              color: Color(0xFFB9D4FF),
                              fontSize: 10.5,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DriverActions(radius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GlassButton(
                label: 'Finalizar viaje',
                filled: true,
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FinalizarViaje(trip: trip),
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

class _DriverActions extends StatelessWidget {
  const _DriverActions({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: .12),
          shape: const CircleBorder(),
          child: const InkWell(
            customBorder: CircleBorder(),
            onTap: _nothing,
            child: SizedBox(
              height: 34,
              width: 34,
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white.withValues(alpha: .12),
          shape: const CircleBorder(),
          child: const InkWell(
            customBorder: CircleBorder(),
            onTap: _nothing,
            child: SizedBox(
              height: 34,
              width: 34,
              child: Icon(Icons.share_outlined, color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
    );
  }

  static void _nothing() {}
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.index,
    required this.label,
    required this.last,
  });

  final int index;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = last ? mint : cyan;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .18),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
          ),
          child: Icon(
            last ? Icons.flag_rounded : Icons.circle,
            color: color,
            size: last ? 12 : 8,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ),
        ),
        if (last)
          const StatusPill(text: 'Activo', color: mint),
      ],
    );
  }
}

class _IncoexMap extends StatefulWidget {
  const _IncoexMap({required this.route});

  final List<TrackingPoint> route;

  @override
  State<_IncoexMap> createState() => _IncoexMapState();
}

class _IncoexMapState extends State<_IncoexMap> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECF2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: _RouteMapPainter(route: widget.route),
              size: Size.infinite,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33071B53),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/brand/incoex-logo.png',
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter({required this.route});

  final List<TrackingPoint> route;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8ECF2),
    );

    // Calles: cuadrícula de bloques como mapa de ciudad
    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 24;
    final streetThin = Paint()
      ..color = Colors.white
      ..strokeWidth = 13;
    final grid = [
      (Offset(0, size.height * .20), Offset(size.width, size.height * .16)),
      (Offset(0, size.height * .52), Offset(size.width, size.height * .60)),
      (Offset(0, size.height * .84), Offset(size.width, size.height * .78)),
      (Offset(size.width * .28, 0), Offset(size.width * .34, size.height)),
      (Offset(size.width * .70, 0), Offset(size.width * .62, size.height)),
    ];
    for (final (from, to) in grid) {
      canvas.drawLine(from, to, streetThin);
    }
    canvas.drawLine(
      Offset(-30, size.height * .05),
      Offset(size.width * .6, size.height * .03),
      street,
    );
    canvas.drawLine(
      Offset(size.width * .22, size.height + 30),
      Offset(size.width * .95, size.height * .66),
      street,
    );
    canvas.drawLine(
      Offset(-20, size.height * .95),
      Offset(size.width * .75, size.height * .92),
      street,
    );

    if (route.isEmpty) return;

    // Normalizar la ruta a coordenadas de pantalla con padding
    final pts = route.map((p) => Offset(p.longitude, p.latitude)).toList();
    var minX = pts.first.dx, maxX = pts.first.dx;
    var minY = pts.first.dy, maxY = pts.first.dy;
    for (final p in pts) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final pad = 46.0;
    final spanX = math.max(maxX - minX, 0.0009);
    final spanY = math.max(maxY - minY, 0.0009);
    final scale = math.min(
      (size.width - pad * 2) / spanX,
      (size.height - pad * 2) / spanY,
    );
    final offsetX = (size.width - spanX * scale) / 2 - minX * scale;
    final offsetY = (size.height - spanY * scale) / 2 - minY * scale;
    final mapped = pts.map((p) => Offset(p.dx * scale + offsetX, p.dy * scale + offsetY)).toList();

    // Ruta polilínea azul
    if (mapped.length > 1) {
      final path = Path()..moveTo(mapped.first.dx, mapped.first.dy);
      for (final p in mapped.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF1D5CFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Pin de origen (cian) y destino (rojo)
    final origin = mapped.first;
    _drawPin(canvas, origin, const Color(0xFF0C7DFF));
    if (mapped.length > 1) {
      _drawPin(canvas, mapped.last, const Color(0xFFE5484D), open: false);
    }
  }

  void _drawPin(Canvas canvas, Offset center, Color color, {bool open = true}) {
    Paint _light(Color c, double alpha) =>
        Paint()..color = c.withValues(alpha: alpha);
    canvas.drawCircle(center, 15, _light(color, .20));
    canvas.drawCircle(center, 26, _light(color, .10));
    if (open) {
      canvas.drawCircle(center, 9.5, Paint()..color = color);
      canvas.drawCircle(center, 3.2, Paint()..color = Colors.white);
    } else {
      canvas.drawCircle(
        center,
        12,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        center,
        5.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(center, 1.8, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.route != route;
}
