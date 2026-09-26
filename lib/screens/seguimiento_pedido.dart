import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/notifications.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'finalizar_viaje.dart';
import 'inicio.dart';

class SeguimientoPedido extends StatefulWidget {
  const SeguimientoPedido(
      {super.key, required this.trip, this.closeable = true});

  final Trip trip;
  final bool closeable;

  @override
  State<SeguimientoPedido> createState() => _SeguimientoPedidoState();
}

class _SeguimientoPedidoState extends State<SeguimientoPedido> {
  late Future<TrackingData> tracking;
  String _prevStatus = '';
  Timer? poll;
  GoogleMapController? _mapController;
  TrackingData? _mapData;
  Trip? _latestTrip;
  LatLng? _lastCenteredDriver;
  List<LatLng> _roadRoute = const [];
  double? _routeDistanceKm;
  int? _routeDurationSeconds;
  BitmapDescriptor? _driverMarkerIcon;
  String? _markerTransport;

  @override
  void initState() {
    super.initState();
    _prevStatus = widget.trip.status;
    tracking = apiClient.getTracking(widget.trip.id);
    unawaited(_loadDriverMarkerIcon(widget.trip.transport));
    _loadRoadRoute();
    poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final sessionOk = await apiClient.checkSession();
      if (!mounted) return;
      if (!sessionOk) {
        poll?.cancel();
        await apiClient.clearSession();
        if (!mounted) return;
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Inicio()),
            (route) => false,
          );
        }
        return;
      }
      final data = await apiClient.getTrip(widget.trip.id);
      if (!mounted) return;
      final refreshedTracking = apiClient.getTracking(widget.trip.id);
      if (data.status != _prevStatus) {
        setState(() {
          _prevStatus = data.status;
          _latestTrip = data;
          tracking = refreshedTracking;
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
                const Icon(Icons.notifications_active_rounded,
                    color: cyan, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'El envío cambió a estado: ${data.status}',
                    style: const TextStyle(
                        fontFamily: 'Figtree', fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _latestTrip = data;
          tracking = refreshedTracking;
        });
      }
    } catch (_) {}
  }

  Future<void> _shareTracking() async {
    try {
      final data = await apiClient.getTracking(widget.trip.id);
      final url = data.shareUrl ??
          'https://plt-webadmin23-testing.vercel.app/track/${Uri.encodeComponent(widget.trip.id)}';
      await _copyText(url, 'Enlace de seguimiento copiado');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No se pudo generar el enlace.',
              style: TextStyle(fontFamily: 'Figtree'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _copyText(String value, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0B1D4D),
        behavior: SnackBarBehavior.floating,
        content:
            Text(confirmation, style: const TextStyle(fontFamily: 'Figtree')),
      ),
    );
  }

  Future<void> _shareWhatsApp() async {
    try {
      final data = await apiClient.getTracking(widget.trip.id);
      final url = data.shareUrl ??
          'https://plt-webadmin23-testing.vercel.app/track/${Uri.encodeComponent(widget.trip.id)}';
      final phone =
          (widget.trip.contactPhone ?? '').replaceAll(RegExp(r'\D'), '');
      final message =
          'Hola, te comparto el seguimiento de mi envío ${widget.trip.id} (${widget.trip.origin} → ${widget.trip.destination}). Ubicación en vivo: $url';
      final waTarget = phone.isEmpty
          ? 'https://wa.me/?text='
          : 'https://wa.me/${phone.startsWith('505') ? phone : '505$phone'}?text=';
      if (!kIsWeb &&
          (await launchUrl(
              Uri.parse('$waTarget${Uri.encodeComponent(message)}')))) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0B1D4D),
          behavior: SnackBarBehavior.floating,
          content: SelectableText(
            'Mensaje de WhatsApp:\n$message',
            style: const TextStyle(fontFamily: 'Figtree', fontSize: 12.5),
          ),
          action: SnackBarAction(
            label: 'Copiar',
            textColor: cyan,
            onPressed: () => _copyText(message, 'Mensaje copiado'),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('No se pudo preparar el mensaje.',
                style: TextStyle(fontFamily: 'Figtree')),
          ),
        );
      }
    }
  }

  Future<void> _callDriver(String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _showActionMessage('El conductor todavía no tiene teléfono registrado.');
      return;
    }
    final target = Uri(scheme: 'tel', path: digits);
    if (await launchUrl(target)) return;
    _showActionMessage('No se pudo abrir la llamada en este dispositivo.');
  }

  void _showActionMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontFamily: 'Figtree')),
      ),
    );
  }

  LatLng get _initialMapCenter {
    final trip = widget.trip;
    final latitude = trip.originLat != null && trip.destinationLat != null
        ? (trip.originLat! + trip.destinationLat!) / 2
        : trip.originLat ?? trip.destinationLat ?? 12.115;
    final longitude = trip.originLng != null && trip.destinationLng != null
        ? (trip.originLng! + trip.destinationLng!) / 2
        : trip.originLng ?? trip.destinationLng ?? -86.236;
    return LatLng(latitude, longitude);
  }

  List<LatLng> _tripBoundsPoints() {
    final points = <LatLng>[];
    if (widget.trip.originLat != null && widget.trip.originLng != null) {
      points.add(LatLng(widget.trip.originLat!, widget.trip.originLng!));
    }
    if (widget.trip.destinationLat != null &&
        widget.trip.destinationLng != null) {
      points.add(
        LatLng(widget.trip.destinationLat!, widget.trip.destinationLng!),
      );
    }
    return points;
  }

  List<LatLng> _routeCoordinates(TrackingData? data) {
    if (_roadRoute.length >= 2) return _roadRoute;
    return const [];
  }

  Future<void> _loadDriverMarkerIcon(String? value) async {
    final transport = (value ?? 'Vehículo').trim().toLowerCase();
    if (_driverMarkerIcon != null && _markerTransport == transport) return;
    _markerTransport = transport;
    try {
      final icon = await _buildDriverMarkerIcon(value);
      if (!mounted || _markerTransport != transport) return;
      setState(() => _driverMarkerIcon = icon);
    } catch (_) {
      // El marcador estándar queda como respaldo si el bitmap no está disponible.
    }
  }

  Future<BitmapDescriptor> _buildDriverMarkerIcon(String? value) async {
    final normalized = (value ?? '').toLowerCase();
    final vehicleIcon =
        normalized.contains('moto') || normalized.contains('scooter')
            ? Icons.two_wheeler_rounded
            : normalized.contains('camion') ||
                    normalized.contains('camión') ||
                    normalized.contains('truck')
                ? Icons.local_shipping_rounded
                : Icons.directions_car_filled_rounded;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(64, 64);
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: 57));
    canvas.drawShadow(outer, Colors.black.withValues(alpha: .45), 9, true);
    canvas.drawCircle(center, 57, Paint()..color = const Color(0xF2082B79));
    canvas.drawCircle(center, 48, Paint()..color = accentBlue);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(vehicleIcon.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: 39,
          fontFamily: vehicleIcon.fontFamily,
          package: vehicleIcon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2));
    canvas.drawCircle(
        const Offset(103, 22), 11, Paint()..color = const Color(0xFF21C88A));
    canvas.drawCircle(const Offset(103, 22), 7, Paint()..color = Colors.white);
    final image = await recorder.endRecording().toImage(128, 128);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    if (bytes == null)
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List(),
        size: const Size(56, 56));
  }

  Future<void> _loadRoadRoute() async {
    final trip = widget.trip;
    if (trip.originLat == null ||
        trip.originLng == null ||
        trip.destinationLat == null ||
        trip.destinationLng == null) {
      return;
    }

    // El API entrega la geometría vial calculada en servidor cuando la clave
    // de Google está configurada en Render. Así app y web comparten la misma
    // ruta y el ETA se actualiza desde la posición viva del conductor.
    var routingOriginLat = trip.originLat!;
    var routingOriginLng = trip.originLng!;
    try {
      final serverTracking = await tracking;
      routingOriginLat =
          serverTracking.driverLocation?.latitude ?? routingOriginLat;
      routingOriginLng =
          serverTracking.driverLocation?.longitude ?? routingOriginLng;
      if (serverTracking.routeProvider == 'google' &&
          serverTracking.route.length >= 2) {
        final points = serverTracking.route
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        if (mounted) {
          setState(() {
            _roadRoute = points;
            _routeDistanceKm = serverTracking.routeDistanceKm != null &&
                    serverTracking.routeDistanceKm! > 0
                ? serverTracking.routeDistanceKm
                : trip.distanceKm;
            _routeDurationSeconds = serverTracking.routeDurationSeconds;
          });
          _fitRoute(points);
        }
        return;
      }
    } catch (_) {
      // Google directo queda como respaldo si el proxy todavía no está desplegado.
    }

    // Google entrega la geometría de conducción más precisa. OSRM queda como
    // respaldo para que la ruta siga calles aun cuando la clave esté limitada.
    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'AIzaSyCMwxArmM-BEJuxgbjOiON8KdH_IsNH1F4',
    );
    final requests = <Uri>[];
    if (mapsKey.isNotEmpty) {
      requests
          .add(Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '$routingOriginLat,$routingOriginLng',
        'destination': '${trip.destinationLat},${trip.destinationLng}',
        'mode': 'driving',
        'alternatives': 'false',
        'departure_time': 'now',
        'key': mapsKey,
      }));
    }
    requests.add(Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$routingOriginLng,$routingOriginLat;${trip.destinationLng},${trip.destinationLat}',
      {'overview': 'full', 'geometries': 'geojson'},
    ));

    for (final uri in requests) {
      try {
        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final payload = jsonDecode(response.body);
        List<LatLng> points = const [];
        if (uri.host == 'maps.googleapis.com') {
          if (payload is! Map || payload['status'] != 'OK') continue;
          final routes = payload['routes'];
          if (routes is! List || routes.isEmpty) continue;
          points = _decodeGoogleRoute(routes.first);
          final route = routes.first;
          final legs = route is Map ? route['legs'] : null;
          if (legs is List) {
            var meters = 0.0;
            var seconds = 0;
            for (final leg in legs.whereType<Map>()) {
              final distance = leg['distance'];
              final duration = leg['duration_in_traffic'] ?? leg['duration'];
              meters += (distance is Map
                      ? (distance['value'] as num?)?.toDouble()
                      : null) ??
                  0;
              seconds += (duration is Map
                      ? (duration['value'] as num?)?.toInt()
                      : null) ??
                  0;
            }
            if (meters > 0) _routeDistanceKm = meters / 1000;
            if (seconds > 0) _routeDurationSeconds = seconds;
          }
        } else {
          if (payload is! Map || payload['code'] != 'Ok') continue;
          final routes = payload['routes'];
          final geometry = routes is List && routes.isNotEmpty
              ? routes.first['geometry']
              : null;
          final coordinates = geometry is Map ? geometry['coordinates'] : null;
          if (coordinates is! List) continue;
          points = coordinates
              .whereType<List>()
              .where((pair) => pair.length >= 2)
              .map((pair) => LatLng(
                    (pair[1] as num).toDouble(),
                    (pair[0] as num).toDouble(),
                  ))
              .toList();
          final route =
              routes is List && routes.isNotEmpty ? routes.first : null;
          if (route is Map) {
            _routeDistanceKm = (route['distance'] as num?)?.toDouble() == null
                ? null
                : (route['distance'] as num).toDouble() / 1000;
            _routeDurationSeconds = (route['duration'] as num?)?.toInt();
          }
        }
        if (!mounted || points.length < 2) continue;
        setState(() => _roadRoute = points);
        _fitRoute(points);
        return;
      } catch (_) {
        // Prueba el siguiente proveedor antes de usar el tracking original.
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }
    return points;
  }

  List<LatLng> _decodeGoogleRoute(Map<String, dynamic> route) {
    final points = <LatLng>[];
    final legs = route['legs'];
    if (legs is List) {
      for (final leg in legs.whereType<Map>()) {
        final steps = leg['steps'];
        if (steps is! List) continue;
        for (final step in steps.whereType<Map>()) {
          final polyline = step['polyline'];
          final encoded =
              polyline is Map ? polyline['points']?.toString() : null;
          if (encoded == null || encoded.isEmpty) continue;
          final decoded = _decodePolyline(encoded);
          if (points.isNotEmpty &&
              decoded.isNotEmpty &&
              points.last == decoded.first) {
            points.addAll(decoded.skip(1));
          } else {
            points.addAll(decoded);
          }
        }
      }
    }
    if (points.length >= 2) return points;
    final overview = route['overview_polyline'];
    final encoded = overview is Map ? overview['points']?.toString() : null;
    return encoded == null || encoded.isEmpty
        ? const []
        : _decodePolyline(encoded);
  }

  void _fitRoute(List<LatLng> points) {
    if (_mapController == null || points.length < 2) return;
    final latitudes = points.map((point) => point.latitude).toList();
    final longitudes = points.map((point) => point.longitude).toList();
    final bounds = LatLngBounds(
      southwest: LatLng(
        latitudes.reduce((a, b) => a < b ? a : b),
        longitudes.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        latitudes.reduce((a, b) => a > b ? a : b),
        longitudes.reduce((a, b) => a > b ? a : b),
      ),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
  }

  Set<Marker> _mapMarkers(TrackingData? data) {
    final markers = <Marker>{};
    final trip = widget.trip;
    final driver = data?.driverLocation;
    if (driver != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driver.latitude, driver.longitude),
        icon: _driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: data?.driver ?? trip.driver),
      ));
    }
    if (trip.originLat != null && trip.originLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(trip.originLat!, trip.originLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: trip.origin),
      ));
    }
    if (trip.destinationLat != null && trip.destinationLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(trip.destinationLat!, trip.destinationLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: trip.destination),
      ));
    }
    return markers;
  }

  Set<Polyline> _mapPolylines(TrackingData? data) {
    final coordinates = _routeCoordinates(data);
    if (coordinates.length < 2) return const <Polyline>{};
    return {
      Polyline(
        polylineId: const PolylineId('tracking-route'),
        points: coordinates,
        color: const Color(0xFF1677FF),
        width: 5,
        jointType: JointType.round,
      ),
    };
  }

  void _syncMapData(TrackingData data) {
    if (identical(data, _mapData)) return;
    unawaited(_loadDriverMarkerIcon(data.transport ?? widget.trip.transport));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapData = data);
      final driver = data.driverLocation;
      if (driver == null || _mapController == null) return;
      final position = LatLng(driver.latitude, driver.longitude);
      if (_lastCenteredDriver == null) {
        _lastCenteredDriver = position;
        _fitRoute(_roadRoute.length >= 2 ? _roadRoute : _tripBoundsPoints());
        return;
      }
      final previous = _lastCenteredDriver;
      if (previous != null &&
          (previous.latitude - position.latitude).abs() < .00001 &&
          (previous.longitude - position.longitude).abs() < .00001) {
        return;
      }
      _lastCenteredDriver = position;
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final distance = _routeDistanceKm ?? trip.distanceKm ?? 4.2;
    final eta = _routeDurationSeconds != null && _routeDurationSeconds! > 0
        ? math.max(1, (_routeDurationSeconds! / 60).round())
        : math.max(4, (distance * 2.4).round());
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(child: _buildGoogleMap()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 116,
                color: const Color(0xF20C1C53),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Row(
                      children: [
                        _HeaderButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: widget.closeable
                              ? () => Navigator.of(context).pop()
                              : null,
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Seguimiento en vivo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 42),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: .59,
              minChildSize: .56,
              maxChildSize: .90,
              snap: true,
              snapSizes: const [.59, .90],
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xD91F477F), Color(0xC2173264)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .28),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x45000000),
                            blurRadius: 26,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      child: _buildBody(distance, eta, scrollController),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    final height = MediaQuery.sizeOf(context).height;
    return GoogleMap(
      initialCameraPosition:
          CameraPosition(target: _initialMapCenter, zoom: 12.8),
      // La hoja inferior ocupa la parte baja del mapa. Este padding hace que
      // la ruta quede centrada en el área visible y no detrás del glass.
      padding: EdgeInsets.only(top: 116, bottom: height * .59),
      markers: _mapMarkers(_mapData),
      polylines: _mapPolylines(_mapData),
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        _fitRoute(_roadRoute.length >= 2 ? _roadRoute : _tripBoundsPoints());
      },
    );
  }

  Widget _buildBody(
      double distance, int eta, ScrollController scrollController) {
    final trip = _latestTrip ?? widget.trip;
    return FutureBuilder<TrackingData>(
      future: tracking,
      builder: (context, snapshot) {
        final liveData = snapshot.data;
        final currentStatus = liveData?.status ?? trip.status;
        final isActive =
            !['Completado', 'Cancelado', 'Anulado'].contains(currentStatus);
        final driverName = liveData?.driver ?? trip.driver;
        final driverVehicle = liveData?.driverVehicle ?? 'Vehículo asignado';
        final driverPlate = liveData?.driverPlate ?? 'Placa pendiente';
        final driverPhoto = liveData?.driverPhoto ?? trip.driverPhoto;
        final currentLocation =
            liveData?.currentLocationLabel ?? trip.destination;
        if (liveData != null) _syncMapData(liveData);
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Estado de entrega
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                currentStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Llegada en $eta minutos (${distance.toStringAsFixed(1)} km)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                _AssetIcon('location.png', size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Aproximándose a $currentLocation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressFor(currentStatus),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: .16),
                color: figmaBlue,
              ),
            ),
            const SizedBox(height: 10),
            // Código de seguimiento
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de Seguimiento',
                            style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 10.5,
                                letterSpacing: .6,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Figtree')),
                        SizedBox(height: 3),
                        Text('Guía: ${trip.id}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree')),
                      ],
                    ),
                  ),
                  _MiniBtn(
                    asset: 'copiar.png',
                    label: 'Copiar',
                    onTap: () =>
                        _copyText(trip.id, 'Código de seguimiento copiado'),
                  ),
                  const SizedBox(width: 6),
                  _MiniBtn(
                      asset: 'compartir.png',
                      label: 'Compartir',
                      filled: true,
                      onTap: () => _shareTracking()),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Conductor
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                children: [
                  _DriverAvatar(name: driverName, photoUrl: driverPhoto),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree'),
                        ),
                        Text(driverVehicle,
                            style: const TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 12,
                                fontFamily: 'Figtree')),
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: glassBorder),
                          ),
                          child: Text(driverPlate,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Figtree')),
                        ),
                      ],
                    ),
                  ),
                  RoundBtn(
                      asset: 'llamada.png',
                      onTap: () => _callDriver(
                          liveData?.driverPhone ?? trip.contactPhone)),
                  const SizedBox(width: 7),
                  RoundBtn(
                      asset: 'mensaje.png',
                      filled: true,
                      onTap: () => _shareWhatsApp()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Estado de envío',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree')),
            const SizedBox(height: 8),
            _StepsRow(status: currentStatus),
            const SizedBox(height: 12),
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: cyan, size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        currentStatus == 'Pendiente'
                            ? 'La solicitud está pendiente de asignación.'
                            : 'Viaje en curso. Finalizará cuando el conductor confirme la entrega.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // --- CAMBIO PARA PRUEBAS: 'true' hace que el botón siempre sea visible ---
            if (true) const SizedBox(height: 12),
            if (true)
              SizedBox(
                height: 48,
                child: Material(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => FinalizarViaje(trip: trip)),
                    ),
                    child: const Center(
                      child: Text(
                        'Ver detalle de entrega',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree'),
                      ),
                    ),
                  ),
                ),
              ),

            if (currentStatus == 'Completado') const SizedBox(height: 12),
            if (currentStatus == 'Completado')
              SizedBox(
                height: 48,
                child: Material(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => FinalizarViaje(trip: trip)),
                    ),
                    child: const Center(
                      child: Text(
                        'Ver detalle de entrega',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree'),
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

  double _progressFor(String status) {
    switch (status) {
      case 'Asignado':
        return .18;
      case 'En camino':
        return .45;
      case 'En entrega':
        return .78;
      case 'Completado':
        return 1;
      default:
        return 0;
    }
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          shape: BoxShape.circle,
          border: Border.all(color: glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
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

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final photo = photoUrl?.trim();
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            LinearGradient(colors: [Color(0xFF0D47D9), Color(0xFF083EC0)]),
      ),
      child: photo == null || photo.isEmpty
          ? Text(
              initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            )
          : Image.network(
              photo,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  const _AssetIcon(this.name, {required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/img/PantallaSeguimiento/$name',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white,
        size: size,
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
        style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree'),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn(
      {this.icon,
      this.asset,
      required this.label,
      this.filled = false,
      this.onTap});
  final IconData? icon;
  final String? asset;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(9),
      child: CustomPaint(
        foregroundPainter: _TrackingGlassBorderPainter(selected: filled),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: filled ? figmaBlue : Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              asset != null
                  ? _AssetIcon(asset!, size: 15)
                  : Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree')),
            ],
          ),
        ),
      ),
    );
  }
}

class RoundBtn extends StatelessWidget {
  const RoundBtn(
      {this.icon, this.asset, required this.onTap, this.filled = false});
  final IconData? icon;
  final String? asset;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? accentBlue : Colors.white.withValues(alpha: .09),
            ),
            child: CustomPaint(
              foregroundPainter:
                  const _TrackingGlassBorderPainter(circular: true),
              child: asset != null
                  ? Center(
                      child: SizedBox(
                        width: asset == 'mensaje.png' ? 17 : 18,
                        height: asset == 'mensaje.png' ? 17 : 18,
                        child: _AssetIcon(
                          asset!,
                          size: asset == 'mensaje.png' ? 17 : 18,
                        ),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingGlassBorderPainter extends CustomPainter {
  const _TrackingGlassBorderPainter(
      {this.selected = false, this.circular = false});

  final bool selected;
  final bool circular;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: selected
            ? [
                Colors.white.withValues(alpha: .68),
                cyan.withValues(alpha: .86),
                Colors.white.withValues(alpha: .42),
              ]
            : [
                Colors.white.withValues(alpha: .52),
                Colors.white.withValues(alpha: .18),
                const Color(0x667EA5D8),
              ],
      ).createShader(rect);
    final radius = circular ? size.shortestSide / 2 : 9.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.55), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrackingGlassBorderPainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.circular != circular;
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
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _done
                      ? figmaBlue
                      : Colors.white.withValues(alpha: .10),
                  border:
                      Border.all(color: i < _done ? figmaBlue : Colors.white24),
                ),
                child: const Icon(Icons.circle, color: Colors.white, size: 7),
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
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final step in steps)
              Expanded(
                child: Text(
                  step,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LiveMapPainter extends CustomPainter {
  const _LiveMapPainter({
    required this.progress,
    this.route = const [],
    this.driverLat,
    this.driverLng,
    this.live = false,
  });

  final double progress;
  final List<TrackingPoint> route;
  final double? driverLat;
  final double? driverLng;
  final bool live;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFE8ECF2));
    final streetThin = Paint()
      ..color = Colors.white
      ..strokeWidth = 13;
    final grid = [
      (Offset(0, size.height * .20), Offset(size.width, size.height * .18)),
      (Offset(0, size.height * .56), Offset(size.width, size.height * .60)),
      (Offset(size.width * .24, 0), Offset(size.width * .30, size.height)),
      (Offset(size.width * .62, 0), Offset(size.width * .56, size.height)),
      (Offset(size.width * .82, 0), Offset(size.width * .78, size.height)),
    ];
    for (final (from, to) in grid) canvas.drawLine(from, to, streetThin);
    canvas.drawLine(Offset(-20, size.height * .86),
        Offset(size.width * .8, size.height * .82), streetThin);

    final points = route.length >= 2
        ? _projectRoute(route, size)
        : [
            Offset(size.width * .18, size.height * .78),
            Offset(size.width * .18, size.height * .55),
            Offset(size.width * .36, size.height * .48),
            Offset(size.width * .50, size.height * .40),
            Offset(size.width * .62, size.height * .30),
            Offset(size.width * .72, size.height * .26),
          ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) path.lineTo(p.dx, p.dy);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF1D5CFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);

    // Conductor: posición real del GPS reportado, o animación de respaldo
    Offset pos;
    if (live && driverLat != null && driverLng != null) {
      if (route.length >= 2) {
        pos = _projectRoutePoint(route, driverLat!, driverLng!, size);
      } else {
        final x = ((driverLng! + 86.30) / 0.13).clamp(0.0, 1.0);
        final y = (1 - (driverLat! - 12.06) / 0.10).clamp(0.0, 1.0);
        pos = Offset(x * size.width, y * size.height);
      }
    } else {
      pos = points[1 + ((progress * 4).round().clamp(0, 4))];
    }
    canvas.drawCircle(pos, 26,
        Paint()..color = const Color(0xFF1D5CFF).withValues(alpha: .16));
    canvas.drawCircle(pos, 14, Paint()..color = const Color(0xFF1D5CFF));
    canvas.drawCircle(
        pos,
        14,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final arrow = Path()
      ..moveTo(pos.dx, pos.dy - 7)
      ..lineTo(pos.dx - 5.5, pos.dy + 5)
      ..lineTo(pos.dx, pos.dy + 2)
      ..lineTo(pos.dx + 5.5, pos.dy + 5)
      ..close();
    canvas.drawPath(
        arrow,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
    // Destino
    final dest = points.last;
    canvas.drawCircle(dest, 15,
        Paint()..color = const Color(0xFFE5484D).withValues(alpha: .18));
    canvas.drawCircle(dest, 9, Paint()..color = const Color(0xFFE5484D));
    canvas.drawCircle(dest, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LiveMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.route != route ||
      oldDelegate.driverLat != driverLat ||
      oldDelegate.driverLng != driverLng ||
      oldDelegate.live != live;

  List<Offset> _projectRoute(List<TrackingPoint> points, Size size) {
    return points
        .map((point) =>
            _projectRoutePoint(points, point.latitude, point.longitude, size))
        .toList();
  }

  Offset _projectRoutePoint(List<TrackingPoint> points, double latitude,
      double longitude, Size size) {
    final latitudes = points.map((point) => point.latitude).toList();
    final longitudes = points.map((point) => point.longitude).toList();
    final minLat = latitudes.reduce(math.min);
    final maxLat = latitudes.reduce(math.max);
    final minLng = longitudes.reduce(math.min);
    final maxLng = longitudes.reduce(math.max);
    final latSpan = math.max(maxLat - minLat, .01).toDouble();
    final lngSpan = math.max(maxLng - minLng, .01).toDouble();
    final x = ((longitude - minLng) / lngSpan).clamp(.12, .88).toDouble();
    final y = (1 - (latitude - minLat) / latSpan).clamp(.15, .85).toDouble();
    return Offset(x * size.width, y * size.height);
  }
}
