import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
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
  String filter = 'Activos';

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
                  'Envíos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Todos los envíos en un solo lugar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final option in ['Activos', 'Enviados']) ...[
                  Expanded(
                    child: _OrderFilter(
                      label: option,
                      selected: filter == option,
                      onTap: () => setState(() => filter = option),
                    ),
                  ),
                  if (option != 'Enviados') const SizedBox(width: 8),
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
                            fontFamily: 'Figtree',
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
                            fontFamily: 'Figtree',
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
                  'Enviados' => items.where((trip) => !trip.isActive).toList(),
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
                          fontFamily: 'Figtree',
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
    final transport = trip.transport?.trim().toLowerCase() ?? '';
    final description = trip.description?.trim().toLowerCase() ?? '';
    final vehicleAsset = switch (transport) {
      'moto' || 'motocicleta' || 'motorcycle' =>
        'assets/img/HomeCliente/crear_moto.png',
      'vehículo' || 'vehiculo' || 'auto' || 'automóvil' || 'automovil' ||
      'carro' || 'car' || 'vehicle' =>
        'assets/img/HomeCliente/crear_auto.png',
      'camión' || 'camion' || 'carga' || 'camioneta' || 'truck' =>
        'assets/img/HomeCliente/crear_carga.png',
      _ when description.contains('tipo de camión') ||
          description.contains('tipo de camion') ||
          description.contains('carga') =>
        'assets/img/HomeCliente/crear_carga.png',
      _ when description.contains('moto') =>
        'assets/img/HomeCliente/crear_moto.png',
      _ => 'assets/img/HomeCliente/crear_auto.png',
    };
    final destination = trip.destination.trim().isEmpty
        ? 'Destino pendiente'
        : trip.destination.trim();
    final tripId = trip.id.startsWith('#') ? trip.id : '#${trip.id}';
    final arrival = trip.pickupTime?.trim().isNotEmpty == true
        ? trip.pickupTime!.trim()
        : (trip.scheduledTime?.trim().isNotEmpty == true
            ? trip.scheduledTime!.trim()
            : 'Pendiente');
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeguimientoPedido(trip: trip),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
      color: Colors.white.withValues(alpha: .08),
      blur: 18,
      borderRadius: 14,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 36,
            child: Image.asset(
              vehicleAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_shipping_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envío a $destination',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  tripId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                Text(
                  'Llegada estimada: $arrival',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xC7FFFFFF),
                    fontSize: 9,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 27),
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
                  fontFamily: 'Figtree',
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
                  fontFamily: 'Figtree',
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
              fontFamily: 'Figtree',
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
              fontFamily: 'Figtree',
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
