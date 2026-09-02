import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../services/location_sync.dart';
import '../widgets/glass.dart';
import 'viaje_asignado.dart';

class HomeConductor extends StatefulWidget {
  const HomeConductor({super.key});

  @override
  State<HomeConductor> createState() => _HomeConductorState();
}

class _HomeConductorState extends State<HomeConductor> {
  List<Trip> trips = [];
  bool loading = true;
  String? error;
  Timer? poll;
  final Set<String> knownIds = {};
  final List<String> news = [];
  int unread = 0;
  CurrentLocation? location;

  String get _driverName =>
      apiClient.currentUser?.displayName ?? 'Carlos Díaz';

  @override
  void initState() {
    super.initState();
    _load();
    poll = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    LocationSync.instance.start();
  }

  @override
  void dispose() {
    poll?.cancel();
    LocationSync.instance.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await apiClient.getTrips(driver: _driverName);
      if (!mounted) return;
      knownIds.addAll(data.map((t) => t.id));
      setState(() => trips = data);
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudieron cargar tus viajes.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
    final loc = await requestCurrentLocation();
    if (mounted && loc != null) setState(() => location = loc);
    await requestAppPermissions();
  }

  Future<void> _refresh() async {
    try {
      final data = await apiClient.getTrips(driver: _driverName);
      if (!mounted) return;
      final fresh = data.where((t) => !knownIds.contains(t.id)).toList();
      if (fresh.isNotEmpty) {
        for (final trip in fresh) {
          news.insert(0, 'Nuevo viaje ${trip.id} asignado · ${trip.origin} → ${trip.destination}');
        }
        setState(() => unread = news.length);
        if (mounted && fresh.any((t) => t.status == 'Asignado')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0B1D4D),
              behavior: SnackBarBehavior.floating,
              content: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: cyan, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nuevo viaje asignado ${fresh.first.id}',
                      style: const TextStyle(fontFamily: 'Acumin Pro', fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        knownIds.addAll(data.map((t) => t.id));
      }
      setState(() => trips = data);
    } catch (_) {}
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1D4D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notificaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 14),
              if (news.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No tienes notificaciones nuevas.',
                      style: TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
                )
              else
                for (final item in news)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            color: cyan, size: 10),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => unread = 0);
    });
  }

  List<Trip> get _assigned {
    final list = trips.where((t) => t.status == 'Asignado').toList();
    list.sort((a, b) => (a.pickupTime ?? '99').compareTo(b.pickupTime ?? '99'));
    return list;
  }

  List<Trip> get _upcoming {
    final list = trips
        .where((t) => t.isActive && t.status != 'Asignado')
        .toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  List<Trip> get _history =>
      trips.where((t) => t.status == 'Completado').toList();

  @override
  Widget build(BuildContext context) {
    final assigned = _assigned;
    final upcoming = _upcoming;
    final history = _history;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F52),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: cyan,
            backgroundColor: const Color(0xFF0B1D4D),
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: glassBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0B47D9), Color(0xFF083ED1)],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .55),
                              ),
                            ),
                            child: Text(
                              initials(_driverName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _driverName.split(' ').first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _BellButton(badge: unread, onTap: _openNotifications),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Buenos días, ${_driverName.split(' ').first}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  location == null
                      ? 'Hoy es un gran día para entregar.'
                      : '${location!.label} · GPS activo',
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 13.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mis viajes asignados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                    if (assigned.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: glassBorder),
                        ),
                        child: Text(
                          '${assigned.length} viaje${assigned.length == 1 ? '' : 's'} hoy',
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
                const SizedBox(height: 14),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: cyan),
                    ),
                  )
                else if (error != null)
                  _ErrorState(message: error!, onRetry: _load)
                else if (assigned.isEmpty && upcoming.isEmpty)
                  _EmptyState(onRetry: _load)
                else ...[
                  if (assigned.isNotEmpty) ...[
                    _NextTripCard(
                      trip: assigned.first,
                      onView: () => _openTrip(assigned.first),
                    ),
                    if (assigned.length > 1) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Próximos viajes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final trip in assigned.skip(1)) ...[
                        _UpcomingTile(trip: trip, onView: () => _openTrip(trip)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ] else ...[
                    const Text(
                      'Próximos viajes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      const _NoTripsCard()
                    else
                      for (final trip in upcoming) ...[
                        _UpcomingTile(trip: trip, onView: () => _openTrip(trip)),
                        const SizedBox(height: 10),
                      ],
                  ],
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Mi historial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HistoryCard(trips: history),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTrip(Trip trip) {
    if (!trip.isActive) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViajeAsignado(tripId: trip.id)),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.badge, required this.onTap});

  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .14),
          border: Border.all(color: glassBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 21),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A5A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NextTripCard extends StatelessWidget {
  const _NextTripCard({required this.trip, required this.onView});

  final Trip trip;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRÓXIMO VIAJE',
                      style: TextStyle(
                        color: Color(0xFF7A87A8),
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trip.id,
                      style: const TextStyle(
                        color: Color(0xFF10224A),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF0D47D9),
                    width: 1.1,
                  ),
                ),
                child: const Text(
                  'Asignado',
                  style: TextStyle(
                    color: Color(0xFF0D47D9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _RoutePair(origin: trip.origin, destination: trip.destination),
          const SizedBox(height: 13),
          Divider(color: Color(0x2210224A), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniIcon(Icons.calendar_today_rounded, trip.date),
              const SizedBox(width: 16),
              _MiniIcon(Icons.schedule_rounded, trip.pickupTime ?? '—'),
              const Spacer(),
              _MiniIcon(Icons.inventory_2_rounded, '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}'),
            ],
          ),
          if (trip.estimatedCostCs != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: Color(0xFF0D47D9), size: 15),
                const SizedBox(width: 7),
                Text(
                  'Precio: C\$${trip.estimatedCostCs!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF0D47D9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              color: const Color(0xFF0D47D9),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: onView,
                borderRadius: BorderRadius.circular(30),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver viaje',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePair extends StatelessWidget {
  const _RoutePair({required this.origin, required this.destination});

  final String origin;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RouteDotLine(
          dot: Icons.radio_button_checked,
          color: const Color(0xFF0D47D9),
          label: 'ORIGEN',
          value: origin,
        ),
        const SizedBox(height: 11),
        _RouteDotLine(
          dot: Icons.place_rounded,
          color: const Color(0xFFE5484D),
          label: 'DESTINO',
          value: destination,
        ),
      ],
    );
  }
}

class _RouteDotLine extends StatelessWidget {
  const _RouteDotLine({
    required this.dot,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData dot;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(dot, color: color, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A87A8),
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF10224A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
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

class _MiniIcon extends StatelessWidget {
  const _MiniIcon(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF3E4C6E), size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF3E4C6E),
            fontSize: 11,
            fontFamily: 'Acumin Pro',
          ),
        ),
      ],
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.trip, required this.onView});

  final Trip trip;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17285C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                trip.id,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onView,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Ver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D47D9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.origin,
                  style: const TextStyle(
                    color: Color(0xFFCBD9F5),
                    fontSize: 12.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.place_rounded,
                  color: Color(0xFFE5484D), size: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.destination,
                  style: const TextStyle(
                    color: Color(0xFFCBD9F5),
                    fontSize: 12.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Divider(color: glassBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Hoy, ${trip.pickupTime ?? '—'}',
                style: const TextStyle(
                  color: Color(0xFFCBD9F5),
                  fontSize: 11.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const Spacer(),
              const Icon(Icons.payments_outlined,
                  color: cyan, size: 13),
              const SizedBox(width: 4),
              Text(
                trip.estimatedCostCs == null
                    ? '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}'
                    : 'C\$${trip.estimatedCostCs!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFCBD9F5),
                  fontSize: 11.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final earned = trips.fold<double>(
      0,
      (sum, t) => sum + (t.estimatedCostCs ?? 0),
    );
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF17285C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total ganado',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 12,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              Text(
                'C\$${earned.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: mint,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          for (final trip in trips.take(4)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: mint, size: 16),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.id} · ${trip.destination}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        Text(
                          '${trip.date} · ${trip.packages} paquete${trip.packages == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF8FA0C4),
                            fontSize: 10.5,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    trip.estimatedCostCs == null
                        ? '—'
                        : 'C\$${trip.estimatedCostCs!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF17285C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_shipping_outlined,
              color: Color(0xFF8FA0C4), size: 40),
          const SizedBox(height: 12),
          const Text(
            'No tienes viajes asignados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Te avisaremos en cuanto recibas uno nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 12,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 170,
            child: GlassButton(
              label: 'Actualizar',
              onPressed: onRetry,
              height: 44,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoTripsCard extends StatelessWidget {
  const _NoTripsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF17285C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: const Text(
        'Sin viajes de momento',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFB9D4FF),
          fontSize: 12.5,
          fontFamily: 'Acumin Pro',
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF17285C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Color(0xFFFFB4B4), size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 170,
            child: GlassButton(
              label: 'Reintentar',
              onPressed: onRetry,
              height: 44,
            ),
          ),
        ],
      ),
    );
  }
}
