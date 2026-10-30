import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/trip_routing.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

double totalRecaudado(Iterable<Trip> trips) {
  return trips
      .where((trip) => trip.isCompleted)
      .fold<double>(0, (total, trip) => total + (trip.estimatedCostCs ?? 0));
}

String _historyQuantityLabel(Trip trip) {
  final mode = (trip.serviceMode ?? '').toLowerCase();
  if (mode.contains('taxi') || mode.contains('viaje')) {
    final passengers = trip.passengerCount ?? 0;
    return '$passengers pasajero${passengers == 1 ? '' : 's'}';
  }
  return '${trip.packages} bulto${trip.packages == 1 ? '' : 's'}';
}

class HistorialConductorScreen extends StatefulWidget {
  const HistorialConductorScreen({super.key});

  @override
  State<HistorialConductorScreen> createState() =>
      _HistorialConductorScreenState();
}

class _HistorialConductorScreenState extends State<HistorialConductorScreen> {
  late Future<List<Trip>> _future;
  String selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _loadHistory();
  }

  Future<List<Trip>> _loadHistory() async {
    final name = apiClient.currentUser?.displayName ?? '';
    final trips = await apiClient.getTrips(driver: name);
    return trips.where((trip) => !trip.isActive).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0D1F52),
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('Historial de viajes',
                style: TextStyle(
                    fontFamily: 'Figtree', fontWeight: FontWeight.w800)),
          ),
          body: SafeArea(
            top: false,
            child: FutureBuilder<List<Trip>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: cyan));
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudo cargar el historial.',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Figtree')),
                  );
                }
                final trips = snapshot.data ?? const <Trip>[];
                if (trips.isEmpty) {
                  return const Center(
                    child: Text('Aún no tienes viajes finalizados.',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Figtree')),
                  );
                }
                final filteredTrips = trips.where((trip) {
                  switch (selectedFilter) {
                    case 'Completados':
                      return trip.isCompleted;
                    case 'Cancelados':
                      return trip.status == 'Cancelado' ||
                          trip.status == 'Anulado';
                    default:
                      return true;
                  }
                }).toList();
                final total = totalRecaudado(filteredTrips);
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HistoryFilters(
                      selected: selectedFilter,
                      onChanged: (value) =>
                          setState(() => selectedFilter = value),
                    ),
                    const SizedBox(height: 12),
                    ShowcaseGlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      borderRadius: 17,
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total recaudado',
                              style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontFamily: 'Figtree',
                              ),
                            ),
                          ),
                          Text(
                            formatFareCs(total),
                            style: const TextStyle(
                              color: Color(0xFF61E5B5),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filteredTrips.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Text(
                          selectedFilter == 'Cancelados'
                              ? 'No tienes viajes cancelados.'
                              : 'No tienes viajes completados.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      )
                    else
                      ...filteredTrips.map((trip) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HistoryTripCard(trip: trip),
                          )),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const filters = ['Todos', 'Completados', 'Cancelados'];

  @override
  Widget build(BuildContext context) {
    return ShowcaseGlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 17,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            for (final filter in filters)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected == filter
                          ? const Color(0xFF0D5BFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      filter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTripCard extends StatelessWidget {
  const _HistoryTripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final isTrip = isTripServiceMode(trip.serviceMode);
    final isCanceled = trip.status == 'Cancelado' || trip.status == 'Anulado';
    final vehicle = _historyVehicleLabel(trip);
    return ShowcaseGlassCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      borderRadius: 17,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCanceled ? 'VIAJE CANCELADO' : 'VIAJE FINALIZADO',
            style: TextStyle(
              color: isCanceled
                  ? const Color(0xFFFFA5B5)
                  : const Color(0xFFB9D4FF),
              fontSize: 9,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _HistoryChip(
                label: isTrip ? 'Viaje' : 'Envío',
                color: isTrip
                    ? const Color(0xFFFFC928)
                    : const Color(0xFF0D5BFF),
                textColor: isTrip ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 6),
              _HistoryChip(
                label: vehicle,
                color: Colors.white.withValues(alpha: .18),
                borderColor: Colors.white.withValues(alpha: .34),
              ),
              const SizedBox(width: 6),
              _HistoryChip(
                label: isCanceled ? 'Cancelado' : 'Completado',
                color: isCanceled
                    ? const Color(0x33E84D68)
                    : const Color(0x3316C784),
                borderColor: isCanceled
                    ? const Color(0x99E84D68)
                    : const Color(0x9916C784),
                textColor: isCanceled
                    ? const Color(0xFFFF8FA3)
                    : const Color(0xFF61E5B5),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 52,
                child: Image.asset(
                  _historyVehicleAsset(vehicle),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white70,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryRouteSummary(
                  origin: trip.origin,
                  destination: trip.destination,
                  tripId: trip.id,
                  quantity: _historyQuantityLabel(trip),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isCanceled ? Icons.cancel_rounded : Icons.check_circle,
                color: isCanceled
                    ? const Color(0xFFE84D68)
                    : const Color(0xFF16C784),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                isCanceled ? 'Cancelado' : 'Finalizado',
                style: TextStyle(
                  color: isCanceled
                      ? const Color(0xFFFF8FA3)
                      : const Color(0xFF61E5B5),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: .18), height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              _HistoryMeta(icon: Icons.calendar_today_rounded, text: trip.date),
              const SizedBox(width: 14),
              _HistoryMeta(
                icon: Icons.schedule_rounded,
                text: trip.pickupTime ?? '—',
              ),
              const Spacer(),
              _HistoryMeta(
                icon: isTrip
                    ? Icons.people_alt_rounded
                    : Icons.inventory_2_rounded,
                text: _historyQuantityLabel(trip),
                alignRight: true,
              ),
            ],
          ),
          if (trip.estimatedCostCs != null && !isCanceled) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: cyan, size: 15),
                const SizedBox(width: 6),
                Text(
                  'Recaudado: ${formatFareCs(trip.estimatedCostCs!)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _historyVehicleLabel(Trip trip) {
  final value = '${trip.vehicleVariant ?? ''} ${trip.transport ?? ''} '
          '${trip.description ?? ''}'
      .toLowerCase();
  if (value.contains('suv')) return 'SUV';
  if (value.contains('sedán') || value.contains('sedan')) return 'SEDÁN';
  if (value.contains('moto')) return 'MOTO';
  if (value.contains('van') || value.contains('transit') || value.contains('caddy')) {
    return 'VAN';
  }
  if (value.contains('camion') || value.contains('camión') || value.contains('carga')) {
    return 'CAMIÓN';
  }
  return 'AUTO';
}

String _historyVehicleAsset(String label) {
  switch (label) {
    case 'SUV':
      return 'assets/img/HomeCliente/taxi_suv.png';
    case 'SEDÁN':
      return 'assets/img/HomeCliente/taxi_sedan.png';
    case 'MOTO':
      return 'assets/img/HomeCliente/figma_moto.png';
    case 'VAN':
      return 'assets/img/HomeCliente/figma_van.png';
    case 'CAMIÓN':
      return 'assets/img/HomeCliente/figma_carga.png';
    default:
      return 'assets/img/HomeCliente/figma_auto.png';
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.color,
    this.borderColor,
    this.textColor = Colors.white,
  });

  final String label;
  final Color color;
  final Color? borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }
}

class _HistoryRouteSummary extends StatelessWidget {
  const _HistoryRouteSummary({
    required this.origin,
    required this.destination,
    required this.tripId,
    required this.quantity,
  });

  final String origin;
  final String destination;
  final String tripId;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryStop(label: 'RECOGIDA', value: origin, color: const Color(0xFFD7E7FF)),
        const SizedBox(height: 6),
        _HistoryStop(label: 'DESTINO', value: destination, color: const Color(0xFFE5484D)),
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 3),
          child: Text(
            '$tripId · $quantity',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9FB2DC),
              fontSize: 10,
              fontFamily: 'Figtree',
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryStop extends StatelessWidget {
  const _HistoryStop({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF9FB2DC), fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w800, fontFamily: 'Figtree')),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800, fontFamily: 'Figtree')),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryMeta extends StatelessWidget {
  const _HistoryMeta({required this.icon, required this.text, this.alignRight = false});

  final IconData icon;
  final String text;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFD7E7FF), size: 13),
            const SizedBox(width: 5),
            Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD7E7FF), fontSize: 10, fontFamily: 'Figtree'))),
          ],
        ),
      ),
    );
  }
}
