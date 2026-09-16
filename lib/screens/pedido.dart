import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'crear_envio1.dart';
import 'crear_envio2.dart';
import 'seguimiento_pedido.dart';
import 'resumen_cliente.dart';

class MisEnvios extends StatefulWidget {
  const MisEnvios({super.key, this.onRefresh, this.embedded = false});

  final VoidCallback? onRefresh;
  final bool embedded;

  @override
  State<MisEnvios> createState() => _MisEnviosState();
}

class _MisEnviosState extends State<MisEnvios> {
  late Future<List<Trip>> trips;
  String filter = 'Todos';

  @override
  void initState() {
    super.initState();
    trips = _loadTrips();
  }

  void _reload() {
    setState(() => trips = _loadTrips());
    widget.onRefresh?.call();
  }

  Future<List<Trip>> _loadTrips() {
    final user = apiClient.currentUser;
    final client = user != null && (user.role == 'corporate' || user.role == 'company')
        ? user.displayName.trim()
        : null;
    return apiClient.getTrips(client: client);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis envíos',
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
            Row(
              children: [
                for (final option in ['Todos', 'Activos', 'Completados']) ...[
                  Expanded(
                    child: _OrderFilter(
                      label: option,
                      selected: filter == option,
                      onTap: () => setState(() => filter = option),
                    ),
                  ),
                  if (option != 'Completados') const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 14),
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
                final visibleItems = switch (filter) {
                  'Activos' => items.where((trip) => trip.isActive).toList(),
                  'Completados' => items.where((trip) => trip.isCompleted).toList(),
                  _ => items,
                };
                if (visibleItems.isEmpty) {
                  return GlassCard(
                    child: Center(
                      child: Text(
                        items.isEmpty
                            ? 'Aún no tienes envíos.\nSolicita tu primer envío.'
                            : 'No hay envíos en este filtro.',
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
                    for (final trip in visibleItems) ...[
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
      );
    return widget.embedded ? content : AppBackground(child: content);
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

class _OrderFilter extends StatelessWidget {
  const _OrderFilter({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? figmaBlue : Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? cyan.withValues(alpha: .75) : glassBorder),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
      ),
    );
  }
}

/// Paso 2 del flujo de creación. Se mantiene con este nombre porque es la
/// vista que consume la navegación del cliente; el listado vive en MisEnvios.
class Pedido extends StatelessWidget {
  const Pedido({
    super.key,
    required this.origin,
    required this.destination,
    this.originPlace,
    this.destinationPlace,
    this.transport = 'Moto',
    this.estimatedShipping,
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.startScheduled = false,
    this.startDate,
    this.startTime,
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final double? estimatedShipping;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;
  final bool startScheduled;
  final String? startDate;
  final String? startTime;

  @override
  Widget build(BuildContext context) {
    return CrearEnvio2(
      origin: origin,
      destination: destination,
      originPlace: originPlace,
      destinationPlace: destinationPlace,
      transport: transport,
      estimatedShipping: estimatedShipping,
      originRefs: originRefs,
      destinationRefs: destinationRefs,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      startScheduled: startScheduled,
      startDate: startDate,
      startTime: startTime,
    );
  }
}
