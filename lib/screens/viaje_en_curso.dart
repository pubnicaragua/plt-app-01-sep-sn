import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/dialog_lifecycle.dart';
import '../core/location_service.dart';
import '../core/map_camera_follow.dart';
import '../core/theme.dart';
import '../core/trip_routing.dart';
import '../models/api_models.dart';
import '../widgets/incident_sheet.dart';
import 'pago_viaje.dart';

String conductorDeliveryReference(Trip trip) {
  final direct = trip.destinationRefs?.trim();
  if (direct?.isNotEmpty == true) return direct!;
  final match = RegExp(
    r'Referencia de envío:\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(trip.description ?? '');
  final parsed = match?.group(1)?.trim();
  return parsed?.isNotEmpty == true ? parsed! : 'Sin referencia de entrega';
}

String conductorPickupReference(Trip trip) {
  final direct = trip.originRefs?.trim();
  if (direct?.isNotEmpty == true) return direct!;
  final match = RegExp(
    r'Referencia de recogida:\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(trip.description ?? '');
  final parsed = match?.group(1)?.trim();
  return parsed?.isNotEmpty == true ? parsed! : 'Sin referencia de retiro';
}

String conductorPickupPersonLabel(Trip trip) {
  if (!isTripServiceMode(trip.serviceMode)) {
    final contact = trip.contactName?.trim();
    if (contact?.isNotEmpty == true) return contact!;
    // Compatibilidad con viajes creados antes de guardar el contacto de recojo
    // como campo propio: esos viajes ya contienen el nombre en la descripción.
    final pickupMatch = RegExp(
      r'Recojo:\s*([^·]+)',
      caseSensitive: false,
    ).firstMatch(trip.description ?? '');
    final pickupName = pickupMatch?.group(1)?.trim();
    return pickupName?.isNotEmpty == true ? pickupName! : 'Remitente';
  }

  for (final value in [trip.recipientName, trip.contactName, trip.client]) {
    final name = value?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return 'Pasajero';
}

String conductorPickupActionLabel(Trip trip) {
  if (trip.status == 'Asignado') {
    return isTripServiceMode(trip.serviceMode)
        ? 'Pasajero recogido'
        : 'Paquete recogido';
  }
  return 'Llegué al destino';
}

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
  late Trip activeTrip;
  bool updating = false;
  Timer? locationTimer;
  Timer? trackingTimer;
  CurrentLocation? livePosition;
  TrackingData? trackingData;
  GoogleMapController? mapController;
  List<LatLng> routePoints = const [];
  bool mapHasCentered = false;
  bool mapReady = false;
  final CameraFollowController cameraFollow = CameraFollowController();
  bool cameraAnimationRunning = false;
  LatLng? previousNavigationPoint;
  double navigationBearing = 0;
  bool hasNavigationBearing = false;
  BitmapDescriptor? driverMarkerIcon;
  BitmapDescriptor? pickupMarkerIcon;

  @override
  void initState() {
    super.initState();
    activeTrip = widget.trip;
    unawaited(_loadMapMarkerIcons());
    _startLive();
    _loadTracking();
    trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadTracking(),
    );
  }

  Future<void> _loadMapMarkerIcons() async {
    try {
      final driverIcon = await _buildDriverMarkerIcon();
      final pickupIcon = await _buildRouteLabelMarker('A', cyan);
      if (!mounted) return;
      setState(() {
        driverMarkerIcon = driverIcon;
        pickupMarkerIcon = pickupIcon;
      });
    } catch (_) {
      // Los marcadores estándar quedan como respaldo si no se puede crear el
      // bitmap en la plataforma actual.
    }
  }

  Future<BitmapDescriptor> _buildRouteLabelMarker(
    String label,
    Color color,
  ) async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = ui.Offset(size / 2, size / 2);
    canvas.drawCircle(center, 28, Paint()..color = color);
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          fontFamily: 'Figtree',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      ui.Offset(
        center.dx - painter.width / 2,
        center.dy - painter.height / 2,
      ),
    );
    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildDriverMarkerIcon() async {
    final normalized = (activeTrip.transport ?? '').toLowerCase();
    final vehicleIcon = normalized.contains('moto')
        ? Icons.two_wheeler_rounded
        : normalized.contains('camion') ||
                normalized.contains('camión') ||
                normalized.contains('pickup') ||
                normalized.contains('van')
            ? Icons.local_shipping_rounded
            : Icons.directions_car_filled_rounded;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = ui.Offset(64, 64);
    final outer = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: center, radius: 57));
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
    painter.paint(
      canvas,
      ui.Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
    canvas.drawCircle(
      const ui.Offset(103, 22),
      11,
      Paint()..color = const Color(0xFF21C88A),
    );
    canvas.drawCircle(
        const ui.Offset(103, 22), 7, Paint()..color = Colors.white);
    final image = await recorder.endRecording().toImage(128, 128);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.fromBytes(
      bytes.buffer.asUint8List(),
      size: const Size(56, 56),
    );
  }

  Future<void> _startLive() async {
    await requestAppPermissions();
    // Mientras el conductor está en esta pantalla reporta su GPS real a la API
    // y actualiza el pin según su posición real.
    if (activeTrip.status == 'Asignado' || activeTrip.status == 'En camino') {
      Future<void> report() async {
        final loc = await requestCurrentLocation();
        if (!mounted || loc == null) return;
        setState(() => livePosition = loc);
        _followDriverAt(LatLng(loc.latitude, loc.longitude));
        try {
          await apiClient.reportDriverLocation(
            driver: apiClient.currentUser?.displayName ?? activeTrip.driver,
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
      final data = await apiClient.getTracking(activeTrip.id);
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
    if (!cameraFollow.shouldAnimate || cameraAnimationRunning) return;
    final cameraTarget = driverNavigationCameraTarget(point, navigationBearing);
    _animateCamera(
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

  void _animateCamera(CameraUpdate update) {
    final controller = mapController;
    if (!mounted || controller == null || !cameraFollow.shouldAnimate) return;

    cameraAnimationRunning = true;
    cameraFollow.beginProgrammaticMove();
    controller.animateCamera(update).whenComplete(() {
      cameraAnimationRunning = false;
      cameraFollow.endProgrammaticMove();
    });
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
    if (activeTrip.originLat != null && activeTrip.originLng != null) {
      points.add(LatLng(activeTrip.originLat!, activeTrip.originLng!));
    }
    final stops = List<TripStop>.of(activeTrip.stops)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final stop in stops) {
      if (stop.latitude != null && stop.longitude != null) {
        points.add(LatLng(stop.latitude!, stop.longitude!));
      }
    }
    if (activeTrip.destinationLat != null &&
        activeTrip.destinationLng != null) {
      points
          .add(LatLng(activeTrip.destinationLat!, activeTrip.destinationLng!));
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
        !cameraFollow.shouldAnimate ||
        mapHasCentered) {
      return;
    }
    mapHasCentered = true;
    final latitudes = routePoints.map((point) => point.latitude).toList();
    final longitudes = routePoints.map((point) => point.longitude).toList();
    _animateCamera(
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
        icon: driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        flat: true,
        rotation: navigationBearing,
        infoWindow: InfoWindow(title: activeTrip.driver),
      ));
    }
    final tripPoints = _tripCoordinatePoints();
    if (tripPoints.isNotEmpty) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: tripPoints.first,
        icon: pickupMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(title: activeTrip.origin),
      ));
    }
    if (tripPoints.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: tripPoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: activeTrip.destination),
      ));
    } else if (routePoints.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: routePoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: activeTrip.destination),
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
          _followDriverAt(driver);
        } else {
          _centerOnRouteIfNeeded();
        }
      },
      onCameraMoveStarted: cameraFollow.handleCameraMoveStarted,
    );
  }

  Future<void> _arrived() async {
    if (updating) return;
    if (activeTrip.status != 'Asignado' && activeTrip.status != 'En camino') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Este viaje está en estado «${activeTrip.status}»; no se puede actualizar. Refresca la pantalla.',
            style: const TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      return;
    }
    setState(() => updating = true);
    try {
      final goingToPickup = activeTrip.status == 'Asignado';
      final Trip updated;
      if (goingToPickup) {
        final deliveryCode = await _askForPickupCode();
        if (deliveryCode == null) {
          if (mounted) setState(() => updating = false);
          return;
        }
        final openCamera = await _askForPickupPhoto();
        if (!openCamera) {
          if (mounted) setState(() => updating = false);
          return;
        }
        final image = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (image == null) {
          if (mounted) setState(() => updating = false);
          return;
        }
        final bytes = await image.readAsBytes();
        updated = await apiClient.confirmPickupWithEvidence(
          tripId: activeTrip.id,
          deliveryCode: deliveryCode,
          bytes: bytes,
          filename: image.name.trim().isEmpty ? 'recogida.jpg' : image.name,
        );
      } else {
        updated = await apiClient.updateTripStatus(activeTrip.id, 'En entrega');
      }
      if (!mounted) return;
      if (goingToPickup) {
        setState(() {
          activeTrip = updated;
          updating = false;
          routePoints = const [];
          trackingData = null;
          mapHasCentered = false;
          previousNavigationPoint = null;
          hasNavigationBearing = false;
        });
        await _loadTracking();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PagoViaje(trip: updated)),
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

  Future<String?> _askForPickupCode() async {
    final controllers = List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());
    final code = await showDialogAndWaitForDismissal<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF172F70),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'Código de entrega',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Solicita al cliente el código de 4 dígitos para confirmar la recogida.',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 12,
                  height: 1.35,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Código de entrega',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var index = 0; index < controllers.length; index++) ...[
                    Expanded(
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        autofocus: index == 0,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        onChanged: (value) {
                          setDialogState(() {});
                          if (value.isNotEmpty && index < controllers.length - 1) {
                            focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            focusNodes[index - 1].requestFocus();
                          }
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .06),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF168DFF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF168DFF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF52C7FF), width: 2),
                          ),
                        ),
                      ),
                    ),
                    if (index < controllers.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB9D4FF), fontFamily: 'Figtree')),
            ),
            FilledButton(
              onPressed: controllers.every((controller) => controller.text.isNotEmpty)
                  ? () => Navigator.pop(dialogContext, controllers.map((controller) => controller.text).join())
                  : null,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D47D9), foregroundColor: Colors.white),
              child: const Text('Validar', style: TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    for (final controller in controllers) {
      controller.dispose();
    }
    return code;
  }

  Future<bool> _askForPickupPhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF172F70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(Icons.photo_camera_rounded, color: Color(0xFF52C7FF), size: 42),
        title: const Text('Foto de la recogida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Figtree')),
        content: const Text(
          'Toma una foto del paquete en el momento de recogerlo. Solo se permite usar la cámara.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 12, height: 1.35, fontFamily: 'Figtree'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFB9D4FF), fontFamily: 'Figtree')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D47D9), foregroundColor: Colors.white),
            child: const Text('Abrir cámara', style: TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final trip = activeTrip;
    final headingToPickup = trip.status == 'Asignado';
    final target = headingToPickup ? trip.origin : trip.destination;
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
                    destination: target,
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

  bool get headingToPickup => trip.status == 'Asignado';
  String get targetAddress => headingToPickup ? trip.origin : trip.destination;

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
                    Text(
                      headingToPickup
                          ? 'PUNTO DE RETIRO'
                          : 'DESTINO DE ENTREGA',
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
                      targetAddress,
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
                  headingToPickup
                      ? conductorPickupPersonLabel(trip)
                      : (trip.recipientName ?? trip.contactName ?? 'Cliente'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              if (!isTripServiceMode(trip.serviceMode))
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF9FB2DC), size: 17),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  headingToPickup
                      ? conductorPickupReference(trip)
                      : conductorDeliveryReference(trip),
                  style: const TextStyle(
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: Colors.white.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => _openWaze(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation_rounded, color: cyan, size: 19),
                    SizedBox(width: 8),
                    Text(
                      'Abrir en Waze',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
                            : Text(
                                conductorPickupActionLabel(trip),
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

  Future<void> _openWaze(BuildContext context) async {
    final latitude = headingToPickup ? trip.originLat : trip.destinationLat;
    final longitude = headingToPickup ? trip.originLng : trip.destinationLng;
    final address = targetAddress;
    final waze = latitude != null && longitude != null
        ? Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes')
        : Uri.parse(
            'waze://?q=${Uri.encodeComponent(address)}&navigate=yes',
          );
    final fallback = latitude != null && longitude != null
        ? Uri.parse(
            'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
          )
        : Uri.parse(
            'https://waze.com/ul?q=${Uri.encodeComponent(address)}&navigate=yes',
          );
    if (await launchUrl(waze, mode: LaunchMode.externalApplication)) return;
    if (await launchUrl(fallback, mode: LaunchMode.externalApplication)) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Waze.')),
      );
    }
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
