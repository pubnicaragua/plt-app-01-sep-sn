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
    final clientName = user?.companyName?.trim();
    final client = user != null && (user.role == 'corporate' || user.role == 'company')
        ? (clientName?.isNotEmpty == true ? clientName : user.displayName.trim())
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
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: .38)),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Viaje ${trip.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.date,
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 11,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(text: note, color: color),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _RoutePoint(
                  label: 'DESDE',
                  value: trip.origin,
                  color: cyan,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14, left: 5, right: 5),
                child: Icon(Icons.arrow_forward_rounded,
                    color: Colors.white54, size: 18),
              ),
              Expanded(
                child: _RoutePoint(
                  label: 'HACIA',
                  value: trip.destination,
                  color: const Color(0xFF8FA0C4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x2FFFFFFF), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _TripMeta(icon: Icons.inventory_2_outlined, text: '${trip.packages} bultos'),
              if (trip.serviceType != null) ...[
                const SizedBox(width: 7),
                _TripMeta(icon: Icons.bolt_rounded, text: trip.serviceType!),
              ],
              const Spacer(),
              Text(
                formatFareCs(trip.estimatedCostCs ?? 0),
                style: const TextStyle(
                  color: cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Ver detalle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded,
                  color: color, size: 19),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(Icons.location_on_outlined, color: color, size: 17),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8FA0C4),
                  fontSize: 8.5,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripMeta extends StatelessWidget {
  const _TripMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
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
