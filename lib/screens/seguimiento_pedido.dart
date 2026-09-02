import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/notifications.dart';
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
  String _prevStatus = '';
  Timer? poll;

  @override
  void initState() {
    super.initState();
    _prevStatus = widget.trip.status;
    tracking = apiClient.getTracking(widget.trip.id);
    poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final data = await apiClient.getTrip(widget.trip.id);
      if (!mounted) return;
      if (data.status != _prevStatus) {
        setState(() {
          _prevStatus = data.status;
          tracking = apiClient.getTracking(widget.trip.id);
        });
        pushNotification(
          title: 'Estado del envío ${data.id}',
          body: 'Ahora está: ${data.status}',
          id: data.id.hashCode,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0B1D4D),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: cyan, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'El envío cambió a estado: ${data.status}',
                    style: const TextStyle(fontFamily: 'Acumin Pro', fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _shareTracking() async {
    try {
      final data = await apiClient.getTracking(widget.trip.id);
      final url = data.shareUrl ??
          'https://plt-web-01-sep-sn.vercel.app/track/${Uri.encodeComponent(widget.trip.id)}';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0B1D4D),
          behavior: SnackBarBehavior.floating,
          content: SelectableText(
            'Enlace de seguimiento:\n$url',
            style: const TextStyle(fontFamily: 'Acumin Pro', fontSize: 12.5),
          ),
          action: SnackBarAction(
            label: 'Copiar',
            textColor: cyan,
            onPressed: () {},
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No se pudo generar el enlace.',
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
    final eta = math.max(4, (distance * 2.4).round());
    final active = ['Asignado', 'En camino', 'En entrega'].contains(trip.status);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: widget.closeable
                          ? () => Navigator.of(context).pop()
                          : null,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Seguimiento en Vivo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: mint.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: mint.withValues(alpha: .5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: mint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Activo',
                            style: TextStyle(
                              color: mint,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Chips superiores
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _Pill(
                        child: Text(
                          'GUÍA: ${trip.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _Pill(
                      onTap: () => _shareTracking(),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.ios_share_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 5),
                        Text('Compartir', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
                      ]),
                    ),
                    const SizedBox(width: 7),
                    _Pill(onTap: () {}, child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text('Chat', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
                      SizedBox(width: 3),
                      CircleAvatar(radius: 7, backgroundColor: Color(0xFFE5484D), child: Text('1', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                    ])),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101E4A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: glassBorder),
                  ),
                  child: _buildBody(active, distance, eta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool active, double distance, int eta) {
    final trip = widget.trip;
    return FutureBuilder<TrackingData>(
      future: tracking,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          children: [
            // Barra GPS Dinámico
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF17285C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, color: mint, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'GPS Dinámico Managua',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
                  Text(
                    '${_secondsAgo().toString().padLeft(2, '0')}s · 2a',
                    style: const TextStyle(
                      color: Color(0xFF8FA0C4),
                      fontSize: 10.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Mapa
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECF2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: _LiveMapPainter(
                        progress: (1 - 0.35).clamp(0, 1),
                        driverLat: snapshot.data?.driverLocation?.latitude,
                        driverLng: snapshot.data?.driverLocation?.longitude,
                        live: snapshot.data?.driverLocation != null,
                      ),
                      size: Size.infinite,
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: const [BoxShadow(color: Color(0x33071B53), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: const Text(
                          'Rotonda El Güegüense',
                          style: TextStyle(color: Color(0xFF17396E), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro'),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1F52),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'M 149-281 · 32 km/h',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
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
            const SizedBox(height: 12),
            // Estado de entrega
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'EN CAMINO A ENTREGA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ),
                _CardPill(text: 'Asegurado', color: mint),
                const SizedBox(width: 6),
                _CardPill(text: '32 km/h', color: cyan),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Llegada: $eta min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${distance.toStringAsFixed(1)} km)',
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 13,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Row(
              children: [
                Icon(Icons.location_on_outlined, color: Color(0xFFB9D4FF), size: 13),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Aproximándose a Rotonda El Güegüense',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 11.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: .45,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: .16),
                color: figmaBlue,
              ),
            ),
            const SizedBox(height: 14),
            // Código de seguimiento
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF17285C),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: glassBorder),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de Seguimiento', style: TextStyle(color: Color(0xFF8FA0C4), fontSize: 9.5, letterSpacing: .6, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
                        SizedBox(height: 3),
                        Text('Guía: ${'INC-13096'}', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                      ],
                    ),
                  ),
                  _MiniBtn(icon: Icons.content_copy_rounded, label: 'Copiar'),
                  const SizedBox(width: 6),
                  _MiniBtn(icon: Icons.ios_share_rounded, label: 'Compartir', filled: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Conductor
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFF17285C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF0D47D9), Color(0xFF083EC0)]),
                    ),
                    child: Text(
                      initials(trip.driver),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.driver,
                          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
                        ),
                        const Text('Yamaha FZ 150cc (Azul)', style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 10.5, fontFamily: 'Acumin Pro')),
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: glassBorder),
                          ),
                          child: const Text('M 149-281', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                        ),
                      ],
                    ),
                  ),
                  RoundBtn(icon: Icons.call_rounded, onTap: () {}),
                  const SizedBox(width: 7),
                  RoundBtn(icon: Icons.chat_bubble_rounded, onTap: () {}, badge: true),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('ESTADO DE ENVÍO', style: TextStyle(color: Color(0xFF8FA0C4), fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
            const SizedBox(height: 9),
            _StepsRow(status: trip.status),
            const SizedBox(height: 16),
            if (active)
              SizedBox(
                height: 50,
                child: Material(
                  color: const Color(0xFFB7E24C),
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FinalizarViaje(trip: trip)),
                    ),
                    child: const Center(
                      child: Text(
                        'Ver Entrega',
                        style: TextStyle(color: Color(0xFF10224A), fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  int _secondsAgo() => 5 - (DateTime.now().second % 4);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: glassBorder),
        ),
        child: child,
      ),
    );
  }
}

class _CardPill extends StatelessWidget {
  const _CardPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({required this.icon, required this.label, this.filled = false});
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? figmaBlue : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: filled ? figmaBlue : glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
          ],
        ),
      ),
    );
  }
}

class RoundBtn extends StatelessWidget {
  const RoundBtn({required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .09),
              border: Border.all(color: glassBorder),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          if (badge)
            Positioned(
              top: -1,
              right: -2,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5484D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.status});
  final String status;

  static const steps = ['Asignado', 'Recogida', 'Entrega'];

  int get _done {
    if (status == 'Pendiente') return 0;
    if (status == 'Asignado') return 1;
    if (status == 'En camino') return 1;
    if (status == 'En entrega') return 2;
    if (status == 'Completado') return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _done ? figmaBlue : Colors.white.withValues(alpha: .10),
                    border: Border.all(color: i < _done ? figmaBlue : Colors.white24),
                  ),
                  child: i < _done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'))),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    steps[i],
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro'),
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                color: i + 1 < _done
                    ? figmaBlue
                    : Colors.white.withValues(alpha: .14),
              ),
            ),
        ],
      ],
    );
  }
}

class _LiveMapPainter extends CustomPainter {
  const _LiveMapPainter({
    required this.progress,
    this.driverLat,
    this.driverLng,
    this.live = false,
  });

  final double progress;
  final double? driverLat;
  final double? driverLng;
  final bool live;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8ECF2));
    final streetThin = Paint()..color = Colors.white..strokeWidth = 13;
    final grid = [
      (Offset(0, size.height * .20), Offset(size.width, size.height * .18)),
      (Offset(0, size.height * .56), Offset(size.width, size.height * .60)),
      (Offset(size.width * .24, 0), Offset(size.width * .30, size.height)),
      (Offset(size.width * .62, 0), Offset(size.width * .56, size.height)),
      (Offset(size.width * .82, 0), Offset(size.width * .78, size.height)),
    ];
    for (final (from, to) in grid) canvas.drawLine(from, to, streetThin);
    canvas.drawLine(Offset(-20, size.height * .86), Offset(size.width * .8, size.height * .82), streetThin);

    final points = [
      Offset(size.width * .18, size.height * .78),
      Offset(size.width * .18, size.height * .55),
      Offset(size.width * .36, size.height * .48),
      Offset(size.width * .50, size.height * .40),
      Offset(size.width * .62, size.height * .30),
      Offset(size.width * .72, size.height * .26),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, Paint()..color = const Color(0xFF1D5CFF)..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

    // Conductor: posición real del GPS reportado, o animación de respaldo
    Offset pos;
    if (live && driverLat != null && driverLng != null) {
      final x = ((driverLng! + 86.30) / 0.13).clamp(0.0, 1.0);
      final y = (1 - (driverLat! - 12.06) / 0.10).clamp(0.0, 1.0);
      pos = Offset(x * size.width, y * size.height);
    } else {
      pos = points[1 + ((progress * 4).round().clamp(0, 4))];
    }
    canvas.drawCircle(pos, 26, Paint()..color = const Color(0xFF1D5CFF).withValues(alpha: .16));
    canvas.drawCircle(pos, 14, Paint()..color = const Color(0xFF1D5CFF));
    canvas.drawCircle(pos, 14, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
    final arrow = Path()
      ..moveTo(pos.dx, pos.dy - 7)
      ..lineTo(pos.dx - 5.5, pos.dy + 5)
      ..lineTo(pos.dx, pos.dy + 2)
      ..lineTo(pos.dx + 5.5, pos.dy + 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white..style = PaintingStyle.fill);
    // Destino
    final dest = points.last;
    canvas.drawCircle(dest, 15, Paint()..color = const Color(0xFFE5484D).withValues(alpha: .18));
    canvas.drawCircle(dest, 9, Paint()..color = const Color(0xFFE5484D));
    canvas.drawCircle(dest, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.driverLat != driverLat ||
      oldDelegate.driverLng != driverLng ||
      oldDelegate.live != live;
}
