import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/notifications.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../services/location_sync.dart';
import '../widgets/glass.dart';
import '../widgets/fuel_sheet.dart';
import 'inicio.dart';
import 'viaje_asignado.dart';
import 'viaje_en_curso.dart';

String _driverVehicleLabel(Trip trip) {
  final value = '${trip.vehicleVariant ?? ''} ${trip.truckType ?? ''} '
          '${trip.transport ?? ''} ${trip.description ?? ''}'
      .toLowerCase();
  if (value.contains('minibus') || value.contains('minibús')) return 'MINIBUS';
  if (value.contains('microbus') || value.contains('microbús')) {
    return 'MICROBUS';
  }
  if (value.contains('suv')) return 'SUV';
  if (value.contains('sedán') || value.contains('sedan')) return 'SEDÁN';
  if (value.contains('moto')) return 'MOTO';
  if (value.contains('pickup')) return 'PICKUP';
  if (value.contains('van')) return 'VAN';
  return 'AUTO';
}

class DriverVehicleInfo {
  const DriverVehicleInfo({
    required this.label,
    required this.asset,
    required this.plate,
  });

  final String label;
  final String asset;
  final String plate;
}

String _driverVehicleLabelFromValue(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('minibus') || normalized.contains('minibús')) {
    return 'MINIBUS';
  }
  if (normalized.contains('microbus') || normalized.contains('microbús')) {
    return 'MICROBUS';
  }
  if (normalized.contains('suv')) return 'SUV';
  if (normalized.contains('sedán') || normalized.contains('sedan')) {
    return 'SEDÁN';
  }
  if (normalized.contains('moto')) return 'MOTO';
  if (normalized.contains('pickup')) return 'PICKUP';
  if (normalized.contains('van')) return 'VAN';
  if (normalized.contains('camion') ||
      normalized.contains('camión') ||
      normalized.contains('carga')) {
    return 'CAMIÓN';
  }
  return 'AUTO';
}

String _driverVehicleAssetForLabel(String label) {
  switch (label) {
    case 'MINIBUS':
      return 'assets/img/HomeCliente/figma_minibus.png';
    case 'MICROBUS':
      return 'assets/img/HomeCliente/taxi_microbus.png';
    case 'SUV':
      return 'assets/img/HomeCliente/taxi_suv.png';
    case 'SEDÁN':
      return 'assets/img/HomeCliente/taxi_sedan.png';
    case 'MOTO':
      return 'assets/img/HomeCliente/figma_moto.png';
    case 'PICKUP':
      return 'assets/img/HomeCliente/figma_pickup.png';
    case 'VAN':
      return 'assets/img/HomeCliente/figma_van.png';
    case 'CAMIÓN':
      return 'assets/img/HomeCliente/figma_carga.png';
    default:
      return 'assets/img/HomeCliente/figma_auto.png';
  }
}

DriverVehicleInfo resolveDriverVehicleInfo(
  SessionUser? profile,
  Trip? fallbackTrip,
) {
  final profileVehicle = profile?.vehicle?.trim() ?? '';
  final profilePlate = profile?.plate?.trim() ?? '';
  if (profileVehicle.isNotEmpty) {
    final label = _driverVehicleLabelFromValue(profileVehicle);
    return DriverVehicleInfo(
      label: label,
      asset: _driverVehicleAssetForLabel(label),
      plate: profilePlate.isEmpty ? 'Placa pendiente' : profilePlate,
    );
  }
  if (fallbackTrip != null) {
    final label = _driverVehicleLabel(fallbackTrip);
    return DriverVehicleInfo(
      label: label,
      asset: _driverVehicleAssetForLabel(label),
      plate: 'Placa pendiente',
    );
  }
  return const DriverVehicleInfo(
    label: 'Vehículo no asignado',
    asset: 'assets/img/HomeCliente/figma_auto.png',
    plate: 'Placa pendiente',
  );
}

String _driverVehicleAsset(Trip trip) {
  return _driverVehicleAssetForLabel(_driverVehicleLabel(trip));
}

bool isDriverTripInProgress(Trip trip) =>
    trip.status == 'En camino' || trip.status == 'En entrega';

String driverHomeQuantityLabel(Trip trip) {
  final mode = (trip.serviceMode ?? '').toLowerCase();
  if (mode.contains('taxi') || mode.contains('viaje')) {
    final passengers = trip.passengerCount ?? 0;
    return '$passengers pasajero${passengers == 1 ? '' : 's'}';
  }
  return '${trip.packages} bulto${trip.packages == 1 ? '' : 's'}';
}

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
  final Set<String> knownIncidentIds = {};
  final Set<String> notifiedReturnTrips = {};
  final List<String> news = [];
  int unread = 0;
  String? incidentError;
  CurrentLocation? location;

  String get _driverName => apiClient.currentUser?.displayName ?? 'Carlos Díaz';

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

  Future<void> _forceLogout(String reason) async {
    await apiClient.clearSession();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D4D),
        title: const Text(
          'Sesión cerrada',
          style: TextStyle(
              color: Colors.white,
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w800),
        ),
        content: Text(
          reason,
          style:
              const TextStyle(color: Color(0xFFB9D4FF), fontFamily: 'Figtree'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido',
                style: TextStyle(color: cyan, fontFamily: 'Figtree')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Inicio()),
      (route) => false,
    );
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
    final loc = await requestAppPermissions();
    if (mounted && loc != null) setState(() => location = loc);
    await _refreshIncidentNotifications();
    _checkScheduledReturns(trips);
  }

  Future<void> _refresh() async {
    try {
      final sessionOk = await apiClient.checkSession();
      if (!mounted) return;
      if (!sessionOk) {
        await apiClient.clearSession();
        if (!mounted) return;
        await _forceLogout(
            'Tu sesión fue cerrada remotamente desde el panel de administración');
        return;
      }
      final data = await apiClient.getTrips(driver: _driverName);
      if (!mounted) return;
      final fresh = data.where((t) => !knownIds.contains(t.id)).toList();
      if (fresh.isNotEmpty) {
        for (final trip in fresh) {
          news.insert(0,
              'Nuevo viaje ${trip.id} asignado · ${trip.origin} → ${trip.destination}');
        }
        setState(() => unread += fresh.length);
        if (mounted && fresh.any((t) => t.status == 'Asignado')) {
          pushNotification(
            title: 'Nuevo viaje asignado ${fresh.first.id}',
            body: '${fresh.first.origin} → ${fresh.first.destination}',
            id: fresh.first.id.hashCode,
          );
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
                      style: const TextStyle(
                          fontFamily: 'Figtree', fontWeight: FontWeight.w700),
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
      _checkScheduledReturns(data);
    } catch (_) {}
    await _refreshIncidentNotifications();
  }

  Future<void> _openFuelSheet() async {
    final saved = await showFuelSheet(
      context,
      driverName: _driverName,
      initialPlate: apiClient.currentUser?.plate,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recarga enviada para validación.')),
      );
    }
  }

  void _checkScheduledReturns(List<Trip> assignedTrips) {
    final now = DateTime.now();
    final marker = RegExp(
      r'\[INCOEX_RETURN_AT=([^;\]]+);MODE=scheduled\]',
    );
    for (final trip in assignedTrips) {
      if (!trip.returnTrip ||
          trip.status == 'Cancelado' ||
          trip.status == 'Anulado') {
        continue;
      }
      final match = marker.firstMatch(trip.description ?? '');
      final returnAt =
          match == null ? null : DateTime.tryParse(match.group(1)!);
      if (returnAt == null || returnAt.isAfter(now)) continue;
      if (now.difference(returnAt) > const Duration(hours: 1)) continue;
      final notificationKey = '${trip.id}:${returnAt.toIso8601String()}';
      if (!notifiedReturnTrips.add(notificationKey)) continue;

      const title = 'Compromiso de regreso';
      final body = 'Es hora de recoger a los pasajeros del viaje ${trip.id} '
          'y llevarlos de regreso a ${trip.origin}.';
      unawaited(pushNotification(
        title: title,
        body: body,
        id: notificationKey.hashCode,
      ));
      news.insert(0, '$title · $body');
      if (mounted) {
        setState(() => unread++);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0B1D4D),
            behavior: SnackBarBehavior.floating,
            content: Text(
              '$title · $body',
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshIncidentNotifications() async {
    try {
      final incidents = await apiClient.getIncidentNotifications();
      if (!mounted) return;
      final fresh = incidents
          .where((incident) =>
              incident.id.isNotEmpty && !knownIncidentIds.contains(incident.id))
          .toList(growable: false);
      if (fresh.isEmpty) return;
      for (final incident in fresh) {
        knownIncidentIds.add(incident.id);
        final target =
            incident.isGeneral ? 'General' : 'Viaje ${incident.trip}';
        final details =
            '${incident.type} · prioridad ${incident.priority} · $target'
            '${incident.description.trim().isEmpty ? '' : ' · ${incident.description.trim()}'}';
        news.insert(0, '${incident.id} · $details');
      }
      setState(() => unread += fresh.length);
      final latest = fresh.first;
      final title = latest.isGeneral
          ? 'Incidencia general: ${latest.type}'
          : 'Incidencia en viaje ${latest.trip}';
      final body = latest.description.trim().isEmpty
          ? 'Prioridad ${latest.priority}'
          : latest.description.trim();
      pushNotification(title: title, body: body, id: latest.id.hashCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0B1D4D),
          behavior: SnackBarBehavior.floating,
          content: Text('$title · $body',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Figtree', fontWeight: FontWeight.w700)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      if (message.isNotEmpty && message != incidentError) {
        setState(() => incidentError = message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron consultar incidencias: $message'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
                  fontFamily: 'Figtree',
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
                        fontFamily: 'Figtree',
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
                              fontFamily: 'Figtree',
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
    final list =
        trips.where((t) => t.isActive && t.status != 'Asignado').toList();
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
    final vehicleInfo = resolveDriverVehicleInfo(
      apiClient.currentUser,
      assigned.isNotEmpty
          ? assigned.first
          : upcoming.isNotEmpty
              ? upcoming.first
              : null,
    );
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
                                fontFamily: 'Figtree',
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
                              fontFamily: 'Figtree',
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
                    fontFamily: 'Figtree',
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
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 22),
                _DriverStatusCard(
                  location: location,
                  hasActiveWork: assigned.isNotEmpty || upcoming.isNotEmpty,
                  onRefresh: _load,
                ),
                const SizedBox(height: 14),
                _AssignedVehicleCard(info: vehicleInfo),
                const SizedBox(height: 14),
                _OperationalSummary(
                  assigned: assigned.length,
                  active: upcoming.length,
                  completed: history.length,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.local_gas_station_rounded,
                        label: 'Combustible',
                        onTap: _openFuelSheet,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.notifications_none_rounded,
                        label: 'Actividad',
                        onTap: _openNotifications,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.refresh_rounded,
                        label: 'Actualizar',
                        onTap: _load,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mis envíos asignados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
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
                            fontFamily: 'Figtree',
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
                    _ClientStyleNextTripCard(
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
                          fontFamily: 'Figtree',
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final trip in assigned.skip(1)) ...[
                        _UpcomingTile(
                            trip: trip, onView: () => _openTrip(trip)),
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
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      const _NoTripsCard()
                    else ...[
                      _ClientStyleNextTripCard(
                        trip: upcoming.first,
                        onView: () => _openTrip(upcoming.first),
                      ),
                      for (final trip in upcoming.skip(1)) ...[
                        const SizedBox(height: 10),
                        _UpcomingTile(
                            trip: trip, onView: () => _openTrip(trip)),
                      ],
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
                        fontFamily: 'Figtree',
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
    if (isDriverTripInProgress(trip)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ViajeEnCurso(trip: trip)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViajeAsignado(tripId: trip.id)),
    );
  }
}

class _AssignedVehicleCard extends StatelessWidget {
  const _AssignedVehicleCard({required this.info});

  final DriverVehicleInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 146,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              info.asset,
              height: 126,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car_filled_rounded,
                color: Color(0xFFB9D4FF),
                size: 72,
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 132,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vehículo asignado',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Text(
                    info.plate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverStatusCard extends StatelessWidget {
  const _DriverStatusCard({
    required this.location,
    required this.hasActiveWork,
    required this.onRefresh,
  });

  final CurrentLocation? location;
  final bool hasActiveWork;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final gpsActive = location != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xCC1454D8), Color(0x991A3D99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: cyan.withValues(alpha: .72)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47D9).withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: Icon(
              gpsActive ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: gpsActive ? const Color(0xFF7DFFCE) : Colors.white70,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActiveWork
                      ? 'Jornada en curso'
                      : 'Listo para recibir viajes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  gpsActive
                      ? 'Tu ubicación se está compartiendo'
                      : 'Activa el GPS para actualizar tu ubicación',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD6E5FF),
                    fontSize: 11.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color:
                          gpsActive ? const Color(0xFF7DFFCE) : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Actualizar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary({
    required this.assigned,
    required this.active,
    required this.completed,
  });

  final int assigned;
  final int active;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              value: assigned,
              label: 'Asignados',
              color: const Color(0xFF9EC2FF),
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryMetric(
              value: active,
              label: 'En curso',
              color: const Color(0xFF7DFFCE),
            ),
          ),
          _summaryDivider(),
          Expanded(
            child: _SummaryMetric(
              value: completed,
              label: 'Completados',
              color: const Color(0xFFFFD27D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: .16),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB9D4FF),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'Figtree',
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cyan, size: 21),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
      ),
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

class _ClientStyleNextTripCard extends StatelessWidget {
  const _ClientStyleNextTripCard({required this.trip, required this.onView});

  final Trip trip;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final isTrip = (trip.serviceMode ?? '').toLowerCase().contains('taxi');
    final vehicle = _driverVehicleLabel(trip);
    final quantity = driverHomeQuantityLabel(trip);
    final payment = conductorPaymentLabel(trip);
    final price = trip.estimatedCostCs == null
        ? null
        : 'Precio: ${formatFareCs(trip.estimatedCostCs!)}';

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xA8143474),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0x6687B7FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTrip ? 'PRÓXIMO VIAJE' : 'PRÓXIMO ENVÍO',
              style: TextStyle(
                color: Color(0xFFB9D4FF),
                fontSize: 9,
                letterSpacing: 1.05,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                _DriverChip(
                  label: isTrip ? 'Viaje' : 'Envío',
                  color: const Color(0xFF0D5BFF),
                ),
                const SizedBox(width: 6),
                _DriverChip(
                  label: vehicle,
                  color: Colors.white.withValues(alpha: .18),
                  borderColor: Colors.white.withValues(alpha: .34),
                ),
                const SizedBox(width: 6),
                _DriverChip(
                  label: trip.statusLabel,
                  color: Colors.white.withValues(alpha: .10),
                  borderColor: Colors.white.withValues(alpha: .28),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 48,
                  child: Image.asset(
                    _driverVehicleAsset(trip),
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
                  child: _DriverRouteSummary(
                    origin: trip.origin,
                    destination: trip.destination,
                    tripId: trip.id,
                    quantity: quantity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16C784),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  payment,
                  style: const TextStyle(
                    color: Color(0xFF61E5B5),
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
                _DriverMetaItem(
                  icon: Icons.calendar_today_rounded,
                  text: trip.scheduledDate ?? trip.date,
                ),
                const SizedBox(width: 14),
                _DriverMetaItem(
                  icon: Icons.schedule_rounded,
                  text: trip.scheduledTime ?? trip.pickupTime ?? '—',
                ),
                const Spacer(),
                _DriverMetaItem(
                  icon: isTrip
                      ? Icons.people_alt_rounded
                      : Icons.inventory_2_rounded,
                  text: quantity,
                  alignRight: true,
                ),
              ],
            ),
            if (price != null) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, color: cyan, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    price,
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
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: Material(
                color: const Color(0xFF0D5BFF),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: onView,
                  borderRadius: BorderRadius.circular(24),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver viaje',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 17),
                      ],
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

class _DriverMetaItem extends StatelessWidget {
  const _DriverMetaItem({
    required this.icon,
    required this.text,
    this.alignRight = false,
  });

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
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFD7E7FF),
                  fontSize: 10,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverChip extends StatelessWidget {
  const _DriverChip({
    required this.label,
    required this.color,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? color),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }
}

// ignore: unused_element
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
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trip.id,
                      style: const TextStyle(
                        color: Color(0xFF10224A),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
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
                    fontFamily: 'Figtree',
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
              _MiniIcon(
                  Icons.inventory_2_rounded, driverHomeQuantityLabel(trip)),
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
                  'Precio: ${formatFareCs(trip.estimatedCostCs!)}',
                  style: const TextStyle(
                    color: Color(0xFF0D47D9),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
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
                          fontFamily: 'Figtree',
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

class _DriverRouteSummary extends StatelessWidget {
  const _DriverRouteSummary({
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 3,
          top: 6,
          child: Container(
            width: 1,
            height: 34,
            color: Colors.white.withValues(alpha: .52),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DriverRouteStop(
              label: 'RECOGIDA',
              value: origin,
              color: const Color(0xFFD7E7FF),
            ),
            const SizedBox(height: 7),
            _DriverRouteStop(
              label: 'DESTINO',
              value: destination,
              color: const Color(0xFFE5484D),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 3),
              child: Text(
                '#${tripId.replaceFirst('#', '')} · $quantity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 9.5,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverRouteStop extends StatelessWidget {
  const _DriverRouteStop({
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
          padding: const EdgeInsets.only(top: 2),
          child: _RouteMarker(color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 8,
                  letterSpacing: 1.05,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
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

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF10224A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
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
            fontFamily: 'Figtree',
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
                  fontFamily: 'Figtree',
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
                          fontFamily: 'Figtree',
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
                    fontFamily: 'Figtree',
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
                    fontFamily: 'Figtree',
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
                  fontFamily: 'Figtree',
                ),
              ),
              const Spacer(),
              const Icon(Icons.payments_outlined, color: cyan, size: 13),
              const SizedBox(width: 4),
              Text(
                trip.estimatedCostCs == null
                    ? driverHomeQuantityLabel(trip)
                    : formatFareCs(trip.estimatedCostCs!),
                style: const TextStyle(
                  color: Color(0xFFCBD9F5),
                  fontSize: 11.5,
                  fontFamily: 'Figtree',
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
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Text(
                formatFareCs(earned),
                style: const TextStyle(
                  color: mint,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
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
                  const Icon(Icons.check_circle, color: mint, size: 16),
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
                            fontFamily: 'Figtree',
                          ),
                        ),
                        Text(
                          '${trip.date} · ${driverHomeQuantityLabel(trip)}',
                          style: const TextStyle(
                            color: Color(0xFF8FA0C4),
                            fontSize: 10.5,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    trip.estimatedCostCs == null
                        ? '—'
                        : formatFareCs(trip.estimatedCostCs!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
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
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Te avisaremos en cuanto recibas uno nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 12,
              fontFamily: 'Figtree',
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
          fontFamily: 'Figtree',
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
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFFFB4B4), size: 38),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontFamily: 'Figtree',
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
