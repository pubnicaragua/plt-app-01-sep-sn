import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'crear_envio1.dart';
import 'seguimiento_pedido.dart';
import 'resumen_cliente.dart';

class Pedido extends StatefulWidget {
  const Pedido({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  State<Pedido> createState() => _PedidoState();
}

class _PedidoState extends State<Pedido> {
  late Future<List<Trip>> trips;

  @override
  void initState() {
    super.initState();
    trips = apiClient.getTrips();
  }

  void _reload() {
    setState(() => trips = apiClient.getTrips());
    widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Pedidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CrearEnvio1(),
                    ),
                  ),
                  child: GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<Trip>>(
              future: trips,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const GlassCard(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Consultando tus pedidos…',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return GlassCard(
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined,
                            color: Color(0xFFFFB4B4)),
                        const SizedBox(height: 8),
                        Text(
                          'No pudimos cargar tus pedidos:\n${t(snapshot.error.toString())}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _reload,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snapshot.data ?? const <Trip>[];
                if (items.isEmpty) {
                  return const GlassCard(
                    child: Center(
                      child: Text(
                        'Aún no tienes pedidos.\nSolicita tu primer envío.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final trip in items) ...[
                      _TripCard(trip: trip),
                      const SizedBox(height: 12),
                    ],
                    GlassButton(
                      label: 'Ver resumen del periodo',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ResumenCliente(),
                        ),
                      ),
                      height: 50,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final (color, icon, note) = switch (trip.status) {
      'Completado' => (mint, Icons.check_rounded, 'Entregado'),
      'En entrega' => (cyan, Icons.local_shipping_rounded, 'Con camino'),
      'En camino' => (cyan, Icons.near_me_rounded, 'En movimiento'),
      'Asignado' => (const Color(0xFFFFC64D), Icons.person_pin_rounded, 'Conductor asignado'),
      'Cancelado' => (const Color(0xFFB4BCC9), Icons.close_rounded, 'Cancelado'),
      _ => (const Color(0xFFFFC64D), Icons.timelapse_rounded, 'Pendiente'),
    };
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeguimientoPedido(trip: trip),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.origin} → ${trip.destination}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'GUÍA ${trip.id} · ${trip.packages} paq. · ${trip.date}',
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 10.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(text: note, color: color),
        ],
      ),
    );
  }
}
