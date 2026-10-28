import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/incident_sheet.dart';
import 'confirmar_entrega.dart';

List<LatLng> conductorTrackingPolylinePoints(TrackingData data) => data.route
    .map((point) => LatLng(point.latitude, point.longitude))
    .toList(growable: false);

double driverNavigationBearing(LatLng from, LatLng to) {
  final fromLat = from.latitude * math.pi / 180;
  final toLat = to.latitude * math.pi / 180;
  final deltaLongitude = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(deltaLongitude) * math.cos(toLat);
  final x = math.cos(fromLat) * math.sin(toLat) -
      math.sin(fromLat) * math.cos(toLat) * math.cos(deltaLongitude);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

LatLng driverNavigationCameraTarget(
  LatLng position,
  double bearing, {
  double distanceMeters = 120,
}) {
  const earthRadiusMeters = 6371000.0;
  final angularDistance = distanceMeters / earthRadiusMeters;
  final latitude = position.latitude * math.pi / 180;
  final longitude = position.longitude * math.pi / 180;
  final bearingRadians = bearing * math.pi / 180;
  final targetLatitude = math.asin(
    math.sin(latitude) * math.cos(angularDistance) +
        math.cos(latitude) *
            math.sin(angularDistance) *
            math.cos(bearingRadians),
  );
  final targetLongitude = longitude +
      math.atan2(
        math.sin(bearingRadians) *
            math.sin(angularDistance) *
            math.cos(latitude),
        math.cos(angularDistance) -
            math.sin(latitude) * math.sin(targetLatitude),
      );
  return LatLng(
    targetLatitude * 180 / math.pi,
    targetLongitude * 180 / math.pi,
  );
}

class ViajeEnCurso extends StatefulWidget {
  const ViajeEnCurso({super.key, required this.trip});

  final Trip trip;

  @override
  State<ViajeEnCurso> createState() => _ViajeEnCursoState();
}

class _ViajeEnCursoState extends State<ViajeEnCurso> {
  bool updating = false;
  Timer? locationTimer;
  Timer? trackingTimer;
  CurrentLocation? livePosition;
  TrackingData? trackingData;
  GoogleMapController? mapController;
  List<LatLng> routePoints = const [];
  bool mapHasCentered = false;
  bool mapReady = false;
  LatLng? previousNavigationPoint;
  double navigationBearing = 0;
  bool hasNavigationBearing = false;

  @override
  void initState() {
    super.initState();
    _startLive();
    _loadTracking();
    trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadTracking(),
    );
  }

  Future<void> _startLive() async {
    await requestAppPermissions();
    // Mientras el conductor está en esta pantalla reporta su GPS real a la API
    // y actualiza el pin según su posición real.
    if (widget.trip.status == 'En camino') {
      Future<void> report() async {
        final loc = await requestCurrentLocation();
        if (!mounted || loc == null) return;
        setState(() => livePosition = loc);
        _followDriverAt(LatLng(loc.latitude, loc.longitude));
        try {
          await apiClient.reportDriverLocation(
            driver: apiClient.currentUser?.displayName ?? widget.trip.driver,
            latitude: loc.latitude,
            longitude: loc.longitude,
          );
        } catch (_) {}
      }

      report();
      locationTimer =
          Timer.periodic(const Duration(seconds: 5), (_) => report());
    }
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTracking() async {
    try {
      final data = await apiClient.getTracking(widget.trip.id);
      if (!mounted) return;
      final points = conductorTrackingPolylinePoints(data);
      setState(() {
        trackingData = data;
        routePoints = points.length >= 2 ? points : _tripCoordinatePoints();
      });
      final remoteDriver = data.driverLocation;
      if (remoteDriver != null) {
        _followDriverAt(
          LatLng(remoteDriver.latitude, remoteDriver.longitude),
        );
      } else {
        _centerOnRouteIfNeeded();
      }
    } catch (_) {
      if (!mounted || routePoints.length >= 2) return;
      setState(() => routePoints = _tripCoordinatePoints());
      _centerOnRouteIfNeeded();
    }
  }

  void _followDriverAt(LatLng point) {
    final previous = previousNavigationPoint;
    final pointMoved = previous == null ||
        (previous.latitude - point.latitude).abs() >= .00001 ||
        (previous.longitude - point.longitude).abs() >= .00001;
    if (previous == null || !hasNavigationBearing) {
      navigationBearing = _bearingAlongRoute(point);
      hasNavigationBearing = true;
    } else if (pointMoved) {
      navigationBearing = driverNavigationBearing(previous, point);
    }
    previousNavigationPoint = point;
    if (!mounted || !mapReady || mapController == null) return;
    final cameraTarget = driverNavigationCameraTarget(point, navigationBearing);
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: cameraTarget,
          zoom: 17.2,
          tilt: 62,
          bearing: navigationBearing,
        ),
      ),
    );
  }

  double _bearingAlongRoute(LatLng driver) {
    if (routePoints.length >= 2) {
      var nearestIndex = 0;
      var nearestDistance = double.infinity;
      for (var index = 0; index < routePoints.length; index++) {
        final point = routePoints[index];
        final distance = math.pow(point.latitude - driver.latitude, 2) +
            math.pow(point.longitude - driver.longitude, 2);
        if (distance < nearestDistance) {
          nearestDistance = distance.toDouble();
          nearestIndex = index;
        }
      }
      if (nearestIndex < routePoints.length - 1) {
        return driverNavigationBearing(driver, routePoints[nearestIndex + 1]);
      }
      if (nearestIndex > 0) {
        return driverNavigationBearing(routePoints[nearestIndex - 1], driver);
      }
    }
    final tripPoints = _tripCoordinatePoints();
    if (tripPoints.isEmpty) return 0;
    return driverNavigationBearing(driver, tripPoints.last);
  }

  List<LatLng> _tripCoordinatePoints() {
    final points = <LatLng>[];
    if (widget.trip.originLat != null && widget.trip.originLng != null) {
      points.add(LatLng(widget.trip.originLat!, widget.trip.originLng!));
    }
    final stops = List<TripStop>.of(widget.trip.stops)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final stop in stops) {
      if (stop.latitude != null && stop.longitude != null) {
        points.add(LatLng(stop.latitude!, stop.longitude!));
      }
    }
    if (widget.trip.destinationLat != null &&
        widget.trip.destinationLng != null) {
      points.add(
          LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!));
    }
    return points;
  }

  LatLng get _initialMapCenter {
    final points = _tripCoordinatePoints();
    if (points.isNotEmpty) {
      final latitude =
          points.map((point) => point.latitude).reduce((a, b) => a + b) /
              points.length;
      final longitude =
          points.map((point) => point.longitude).reduce((a, b) => a + b) /
              points.length;
      return LatLng(latitude, longitude);
    }
    return const LatLng(12.115, -86.236);
  }

  void _centerOnRouteIfNeeded() {
    if (!mounted ||
        mapController == null ||
        routePoints.length < 2 ||
        mapHasCentered) {
      return;
    }
    mapHasCentered = true;
    final latitudes = routePoints.map((point) => point.latitude).toList();
    final longitudes = routePoints.map((point) => point.longitude).toList();
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            latitudes.reduce(math.min),
            longitudes.reduce(math.min),
          ),
          northeast: LatLng(
            latitudes.reduce(math.max),
            longitudes.reduce(math.max),
          ),
        ),
        64,
      ),
    );
  }

  LatLng? get _driverPoint {
    final local = livePosition;
    if (local != null) return LatLng(local.latitude, local.longitude);
    final remote = trackingData?.driverLocation;
    if (remote == null) return null;
    return LatLng(remote.latitude, remote.longitude);
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final driver = _driverPoint;
    if (driver != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: driver,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        flat: true,
        rotation: navigationBearing,
        infoWindow: InfoWindow(title: widget.trip.driver),
      ));
    }
    final tripPoints = _tripCoordinatePoints();
    if (tripPoints.isNotEmpty) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: tripPoints.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: widget.trip.origin),
      ));
    }
    if (tripPoints.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: tripPoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.trip.destination),
      ));
    } else if (routePoints.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: routePoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.trip.destination),
      ));
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    if (routePoints.length < 2) return const <Polyline>{};
    return {
      Polyline(
        polylineId: const PolylineId('driver-route'),
        points: routePoints,
        color: const Color(0xFF1457E8),
        width: 6,
        jointType: JointType.round,
      ),
    };
  }

  Widget _buildMap(BuildContext context) {
    final bottomPadding = MediaQuery.sizeOf(context).height * .38;
    return GoogleMap(
      initialCameraPosition:
          CameraPosition(target: _initialMapCenter, zoom: 13),
      padding: EdgeInsets.only(bottom: bottomPadding),
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onMapCreated: (controller) {
        mapController = controller;
        mapReady = true;
        final driver = _driverPoint;
        if (driver != null) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: driverNavigationCameraTarget(
                  driver,
                  navigationBearing,
                ),
                zoom: 17.2,
                tilt: 62,
                bearing: navigationBearing,
              ),
            ),
          );
        } else {
          _centerOnRouteIfNeeded();
        }
      },
    );
  }

  Future<void> _arrived() async {
    if (updating) return;
    if (widget.trip.status != 'En camino') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Este viaje está en estado «${widget.trip.status}»; no se puede marcar en entrega. Refresca la pantalla.',
            style: const TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      return;
    }
    setState(() => updating = true);
    try {
      final updated =
          await apiClient.updateTripStatus(widget.trip.id, 'En entrega');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConfirmarEntrega(trip: updated),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => updating = false);
      final message = error is ApiException
          ? error.message
          : 'No se pudo actualizar. Verifica tu conexión.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              message,
              style: const TextStyle(fontFamily: 'Figtree'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final distance = trackingData?.routeDistanceKm ?? trip.distanceKm ?? 4.2;
    final eta = trackingData?.routeDurationSeconds != null &&
            trackingData!.routeDurationSeconds! > 0
        ? math.max(1, (trackingData!.routeDurationSeconds! / 60).round())
        : math.max(6, (distance * 2.8).round());
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
                            fontFamily: 'Figtree',
                          ),
                        ),
                        Text(
                          trip.id,
                          style: const TextStyle(
                            color: Color(0xFF9FB2DC),
                            fontSize: 11.5,
                            fontFamily: 'Figtree',
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
                  child: _buildMap(context),
                ),
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: _NavigationBanner(
                    destination: trip.destination,
                    eta: eta,
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: .42,
                  minChildSize: .14,
                  maxChildSize: .78,
                  snap: true,
                  snapSizes: const [.14, .42, .78],
                  builder: (context, scrollController) => _DeliverySheet(
                    trip: trip,
                    onArrived: _arrived,
                    updating: updating,
                    scrollController: scrollController,
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

class _NavigationBanner extends StatelessWidget {
  const _NavigationBanner({required this.destination, required this.eta});

  final String destination;
  final int eta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xE80A2F80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xAA62B4FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF0D5BFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIGUE LA RUTA',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$eta min',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
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
                fontFamily: 'Figtree',
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
            fontFamily: 'Figtree',
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
    required this.scrollController,
  });

  final Trip trip;
  final VoidCallback onArrived;
  final bool updating;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101E4A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .3),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
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
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openIncidentSheet(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE5484D).withValues(alpha: .18),
                    border: Border.all(
                      color: const Color(0xFFE5484D).withValues(alpha: .45),
                    ),
                  ),
                  child: const Icon(
                    Icons.report_problem_rounded,
                    color: Color(0xFFFFB4B4),
                    size: 16,
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
                    fontFamily: 'Figtree',
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
                  '${trip.packages} bulto${trip.packages == 1 ? '' : 's'}',
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
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF9FB2DC), size: 17),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Entregar en recepción, piso 4',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 12.5,
                    fontFamily: 'Figtree',
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
                  'Precio del viaje: ${formatFareCs(trip.estimatedCostCs!)}',
                  style: const TextStyle(
                    color: mint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
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
                              fontFamily: 'Figtree',
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
                    color: updating
                        ? const Color(0xFF0B3DBB)
                        : const Color(0xFF0D47D9),
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
                                  fontFamily: 'Figtree',
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
                  fontFamily: 'Figtree',
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
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openIncidentSheet(BuildContext context) {
    showIncidentSheet(
      context,
      tripId: trip.id,
      driverName: apiClient.currentUser?.displayName ?? trip.driver,
      clientName: trip.client,
    );
  }
}
