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
  const SeguimientoPedido({super.key, required this.trip, this.closeable = true});

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
  LatLng? _lastCenteredDriver;
  List<LatLng> _roadRoute = const [];

  @override
  void initState() {
    super.initState();
    _prevStatus = widget.trip.status;
    tracking = apiClient.getTracking(widget.trip.id);
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
                const Icon(Icons.notifications_active_rounded, color: cyan, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'El envío cambió a estado: ${data.status}',
                    style: const TextStyle(fontFamily: 'Acumin Pro', fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() => tracking = refreshedTracking);
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
              style: TextStyle(fontFamily: 'Acumin Pro'),
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
        content: Text(confirmation, style: const TextStyle(fontFamily: 'Acumin Pro')),
      ),
    );
  }

  Future<void> _shareWhatsApp() async {
    try {
      final data = await apiClient.getTracking(widget.trip.id);
      final url = data.shareUrl ??
          'https://plt-webadmin23-testing.vercel.app/track/${Uri.encodeComponent(widget.trip.id)}';
      final phone = (widget.trip.contactPhone ?? '').replaceAll(RegExp(r'\D'), '');
      final message = 'Hola, te comparto el seguimiento de mi envío ${widget.trip.id} (${widget.trip.origin} → ${widget.trip.destination}). Ubicación en vivo: $url';
      final waTarget = phone.isEmpty ? 'https://wa.me/?text=' : 'https://wa.me/${phone.startsWith('505') ? phone : '505$phone'}?text=';
      if (!kIsWeb && (await launchUrl(Uri.parse('$waTarget${Uri.encodeComponent(message)}')))) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0B1D4D),
          behavior: SnackBarBehavior.floating,
          content: SelectableText(
            'Mensaje de WhatsApp:\n$message',
            style: const TextStyle(fontFamily: 'Acumin Pro', fontSize: 12.5),
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
                style: TextStyle(fontFamily: 'Acumin Pro')),
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
        content: Text(message, style: const TextStyle(fontFamily: 'Acumin Pro')),
      ),
    );
  }

  LatLng get _initialMapCenter {
    final trip = widget.trip;
    final latitude = trip.originLat ?? trip.destinationLat ?? 12.115;
    final longitude = trip.originLng ?? trip.destinationLng ?? -86.236;
    return LatLng(latitude, longitude);
  }

  List<LatLng> _routeCoordinates(TrackingData? data) {
    if (_roadRoute.length >= 2) return _roadRoute;
    final liveRoute = data?.route ?? const <TrackingPoint>[];
    if (liveRoute.length >= 3) {
      return liveRoute
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }
    return const [];
  }

  Future<void> _loadRoadRoute() async {
    final trip = widget.trip;
    if (trip.originLat == null ||
        trip.originLng == null ||
        trip.destinationLat == null ||
        trip.destinationLng == null) {
      return;
    }

    // Se puede reemplazar en el build con --dart-define para usar una clave restringida.
    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'AIzaSyCMwxArmM-BEJuxgbjOiON8KdH_IsNH1F4',
    );
    if (mapsKey.isEmpty) return;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${trip.originLat},${trip.originLng}',
      'destination': '${trip.destinationLat},${trip.destinationLng}',
      'mode': 'driving',
      'alternatives': 'false',
      'key': mapsKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final payload = jsonDecode(response.body);
      if (payload is! Map || payload['status'] != 'OK') return;
      final routes = payload['routes'];
      if (routes is! List || routes.isEmpty) return;
      final overview = routes.first['overview_polyline'];
      final encoded = overview is Map ? overview['points']?.toString() : null;
      if (encoded == null || encoded.isEmpty) return;
      final points = _decodePolyline(encoded);
      if (!mounted || points.length < 2) return;
      setState(() => _roadRoute = points);
    } catch (_) {
      // Si falla la consulta, se conserva la ruta enviada por el tracking.
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

  Set<Marker> _mapMarkers(TrackingData? data) {
    final markers = <Marker>{};
    final trip = widget.trip;
    final driver = data?.driverLocation;
    if (driver != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driver.latitude, driver.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: data?.driver ?? trip.driver),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapData = data);
      final driver = data.driverLocation;
      if (driver == null || _mapController == null) return;
      final position = LatLng(driver.latitude, driver.longitude);
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
    final distance = trip.distanceKm ?? 4.2;
    final eta = math.max(4, (distance * 2.4).round());
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(child: _buildGoogleMap()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
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
                              fontFamily: 'Acumin Pro',
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
            DraggableScrollableSheet(
              initialChildSize: .63,
              minChildSize: .58,
              maxChildSize: .90,
              snap: true,
              snapSizes: const [.63, .90],
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xEC1E246E),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
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
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _initialMapCenter, zoom: 12.8),
      markers: _mapMarkers(_mapData),
      polylines: _mapPolylines(_mapData),
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  Widget _buildBody(
      double distance, int eta, ScrollController scrollController) {
    final trip = widget.trip;
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
        final currentLocation = liveData?.currentLocationLabel ?? trip.destination;
        if (liveData != null) _syncMapData(liveData);
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
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
            const SizedBox(height: 18),
            // Estado de entrega
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                currentStatus == 'Asignado' ? 'En camino' : currentStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ]),
            const SizedBox(height: 11),
            Text(
              'Llegada en $eta minutos (${distance.toStringAsFixed(1)} km)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                _AssetIcon('location.png', size: 15),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Aproximándose a $currentLocation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progressFor(currentStatus),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: .16),
                color: figmaBlue,
              ),
            ),
            const SizedBox(height: 14),
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
                        Text('Código de Seguimiento', style: TextStyle(color: Color(0xFF8FA0C4), fontSize: 9.5, letterSpacing: .6, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
                        SizedBox(height: 3),
                        Text('Guía: ${trip.id}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                      ],
                    ),
                  ),
                  _MiniBtn(
                    asset: 'copiar.png',
                    label: 'Copiar',
                    onTap: () => _copyText(trip.id, 'Código de seguimiento copiado'),
                  ),
                  const SizedBox(width: 6),
                  _MiniBtn(asset: 'compartir.png', label: 'Compartir', filled: true, onTap: () => _shareTracking()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Conductor
            Container(
              padding: const EdgeInsets.all(13),
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
                          style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
                        ),
                        Text(driverVehicle, style: const TextStyle(color: Color(0xFFB9D4FF), fontSize: 10.5, fontFamily: 'Acumin Pro')),
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: glassBorder),
                          ),
                          child: Text(driverPlate, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
                        ),
                      ],
                    ),
                  ),
                  RoundBtn(asset: 'llamada.png', onTap: () => _callDriver(liveData?.driverPhone ?? trip.contactPhone)),
                  const SizedBox(width: 7),
                  RoundBtn(asset: 'mensaje.png', filled: true, onTap: () => _shareWhatsApp()),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Estado de envío', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
            const SizedBox(height: 9),
            _StepsRow(status: currentStatus),
            const SizedBox(height: 16),
            if (isActive)
              SizedBox(
                height: 38,
                child: Material(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(26),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => FinalizarViaje(trip: trip)),
                    ),
                    child: const Center(
                      child: Text(
                        'Ver Entrega',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
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
      width: 46,
      height: 46,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF0D47D9), Color(0xFF083EC0)]),
      ),
      child: photo == null || photo.isEmpty
          ? Text(
              initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            )
          : Image.network(
              photo,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
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
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro'),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({this.icon, this.asset, required this.label, this.filled = false, this.onTap});
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? figmaBlue : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: filled ? figmaBlue : glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            asset != null
                ? _AssetIcon(asset!, size: 13)
                : Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Acumin Pro')),
          ],
        ),
      ),
    );
  }
}

class RoundBtn extends StatelessWidget {
  const RoundBtn({this.icon, this.asset, required this.onTap, this.filled = false});
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? accentBlue : Colors.white.withValues(alpha: .09),
              border: Border.all(
                  color: filled ? accentBlue : glassBorder),
            ),
             child: asset != null
                 ? Center(
                     child: SizedBox(
                       width: asset == 'mensaje.png' ? 12 : 14,
                       height: asset == 'mensaje.png' ? 12 : 14,
                       child: _AssetIcon(
                         asset!,
                         size: asset == 'mensaje.png' ? 12 : 14,
                       ),
                     ),
                   )
                : Icon(icon, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _done
                      ? figmaBlue
                      : Colors.white.withValues(alpha: .10),
                  border: Border.all(
                      color: i < _done ? figmaBlue : Colors.white24),
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
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Acumin Pro'),
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
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8ECF2));
    final streetThin = Paint()..color = Colors.white..strokeWidth = 13;
    final grid = [
      (Offset(0, size.height * .20), Offset(size.width, size.height * .18)),
      (Offset(0, size.height * .56), Offset(size.width, size.height * .60)),
      (Offset(size.width * .24, 0), Offset(size.width * .30, size.height)),
      (Offset(size.width * .62, 0), Offset(size.width * .56, size.height)),
      (Offset(size.width * .82, 0), Offset(size.width * .78, size.height)),
    ];
    for (final (from, to) in grid) canvas.drawLine(from, to, streetThin);
    canvas.drawLine(Offset(-20, size.height * .86), Offset(size.width * .8, size.height * .82), streetThin);

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
    canvas.drawPath(path, Paint()..color = const Color(0xFF1D5CFF)..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);

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
    canvas.drawCircle(pos, 26, Paint()..color = const Color(0xFF1D5CFF).withValues(alpha: .16));
    canvas.drawCircle(pos, 14, Paint()..color = const Color(0xFF1D5CFF));
    canvas.drawCircle(pos, 14, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
    final arrow = Path()
      ..moveTo(pos.dx, pos.dy - 7)
      ..lineTo(pos.dx - 5.5, pos.dy + 5)
      ..lineTo(pos.dx, pos.dy + 2)
      ..lineTo(pos.dx + 5.5, pos.dy + 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white..style = PaintingStyle.fill);
    // Destino
    final dest = points.last;
    canvas.drawCircle(dest, 15, Paint()..color = const Color(0xFFE5484D).withValues(alpha: .18));
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
    return points.map((point) => _projectRoutePoint(points, point.latitude, point.longitude, size)).toList();
  }

  Offset _projectRoutePoint(List<TrackingPoint> points, double latitude, double longitude, Size size) {
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
