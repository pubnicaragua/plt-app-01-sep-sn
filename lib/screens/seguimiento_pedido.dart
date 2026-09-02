import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'finalizar_viaje.dart';

class SeguimientoPedido extends StatefulWidget {
  const SeguimientoPedido({super.key, required this.trip, this.closeable = true});

  final Trip trip;
  final bool closeable;

  @override
  State<SeguimientoPedido> createState() => _SeguimientoPedidoState();
}

class _SeguimientoPedidoState extends State<SeguimientoPedido> {
  late Future<TrackingData> tracking;

  @override
  void initState() {
    super.initState();
    tracking = apiClient.getTracking(widget.trip.id);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.closeable,
        title: const Row(
          children: [
            Icon(Icons.radar_rounded, color: cyan, size: 20),
            SizedBox(width: 9),
            Text(
              'Seguimiento en Vivo',
              style: TextStyle(
                fontFamily: 'Acumin Pro',
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 26),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusPill(text: trip.status, color: cyan),
                        Text(
                          'GUÍA: ${trip.id}',
                          style: const TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${trip.origin} → ${trip.destination}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GPS Dinámico Managua · ${trip.date}',
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 11.5,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<TrackingData>(
                future: tracking,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const GlassCard(
                      child: Row(
                        children: [
                          SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 11),
                          Text(
                            'Coordinando señal GPS…',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final route = snapshot.data?.route ?? const <TrackingPoint>[];
                  if (route.isEmpty) {
                    return const GlassCard(
                      child: Text(
                        'Ruta aún sin puntos de GPS.\nEl conductor la compartirá al iniciar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IncoexMap(route: route),
                      const SizedBox(height: 14),
                      GlassCard(
                        color: figmaBlue.withValues(alpha: .30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < route.length; i++) ...[
                              _RouteRow(
                                index: i,
                                label: route[i].label,
                                last: i == route.length - 1,
                              ),
                              if (i != route.length - 1)
                                Container(
                                  margin: const EdgeInsets.only(left: 11),
                                  height: 22,
                                  width: 2,
                                  color: Colors.white.withValues(alpha: .25),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        shape: BoxShape.circle,
                        border: Border.all(color: glassBorder),
                      ),
                      child: Center(
                        child: Text(
                          initials(trip.driver),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.driver,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const Text(
                            'Conductor asignado por INCOEX',
                            style: TextStyle(
                              color: Color(0xFFB9D4FF),
                              fontSize: 10.5,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DriverActions(radius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GlassButton(
                label: 'Finalizar viaje',
                filled: true,
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FinalizarViaje(trip: trip),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverActions extends StatelessWidget {
  const _DriverActions({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: .12),
          shape: const CircleBorder(),
          child: const InkWell(
            customBorder: CircleBorder(),
            onTap: _nothing,
            child: SizedBox(
              height: 34,
              width: 34,
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white.withValues(alpha: .12),
          shape: const CircleBorder(),
          child: const InkWell(
            customBorder: CircleBorder(),
            onTap: _nothing,
            child: SizedBox(
              height: 34,
              width: 34,
              child: Icon(Icons.share_outlined, color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
    );
  }

  static void _nothing() {}
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.index,
    required this.label,
    required this.last,
  });

  final int index;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = last ? mint : cyan;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .18),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
          ),
          child: Icon(
            last ? Icons.flag_rounded : Icons.circle,
            color: color,
            size: last ? 12 : 8,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ),
        ),
        if (last)
          const StatusPill(text: 'Activo', color: mint),
      ],
    );
  }
}

class _IncoexMap extends StatefulWidget {
  const _IncoexMap({required this.route});

  final List<TrackingPoint> route;

  @override
  State<_IncoexMap> createState() => _IncoexMapState();
}

class _IncoexMapState extends State<_IncoexMap> {
  GoogleMapController? _controller;
  BitmapDescriptor _originIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
  BitmapDescriptor _destIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  static const String _mapStyle = '['
      '{"elementType":"geometry","stylers":[{"color":"#f6f9fe"}]},'
      '{"elementType":"labels.text.fill","stylers":[{"color":"#6b7791"}]},'
      '{"elementType":"labels.text.stroke","stylers":[{"color":"#f6f9fe"}]},'
      '{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#d3def2"}]},'
      '{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#e9f0fb"}]},'
      '{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},'
      '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#c8d9f5"}]},'
      '{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#f6f9fe"}]},'
      '{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#9fb9ec"}]},'
      '{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#f6f9fe"}]},'
      '{"featureType":"road.highway","elementType":"labels","stylers":[{"color":"#3c4f7d"}]},'
      '{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#d9e8f7"}]},'
      '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a2c7d"}]}'
      ']';

  static const LatLng _managua = LatLng(12.114993, -86.236174);

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    const cfg = ImageConfiguration(devicePixelRatio: 2, size: Size(48, 72));
    final origin =
        await BitmapDescriptor.asset(cfg, 'assets/img/PantallaInicio/pin_incoex_cyan.png');
    final dest =
        await BitmapDescriptor.asset(cfg, 'assets/img/PantallaInicio/pin_incoex_red.png');
    if (!mounted) return;
    setState(() {
      _originIcon = origin;
      _destIcon = dest;
    });
  }

  void _fitRoute() {
    final pts = widget.route.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final c = _controller;
    if (c == null || pts.isEmpty) return;
    if (pts.length == 1) {
      c.moveCamera(CameraUpdate.newLatLngZoom(pts.first, 14));
      return;
    }
    var minLat = pts.first.latitude, maxLat = pts.first.latitude;
    var minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    c.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.route.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final center = pts.isNotEmpty ? pts.first : _managua;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('incoex-origen'),
        position: pts.first,
        icon: _originIcon,
        infoWindow: InfoWindow(title: widget.route.first.label),
      ),
      if (pts.length > 1)
        Marker(
          markerId: const MarkerId('incoex-destino'),
          position: pts.last,
          icon: _destIcon,
          infoWindow: InfoWindow(title: widget.route.last.label),
        ),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: center, zoom: pts.length > 1 ? 13 : 14),
              onMapCreated: (controller) {
                _controller = controller;
                _fitRoute();
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: false,
              mapType: MapType.normal,
              style: _mapStyle,
              rotateGesturesEnabled: true,
              polylines: pts.length > 1
                  ? {
                      Polyline(
                        polylineId: const PolylineId('ruta-incoex'),
                        points: pts,
                        color: const Color(0xFF1D5CFF),
                        width: 4,
                      ),
                    }
                  : const {},
              markers: markers,
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33071B53),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/brand/incoex-logo.png',
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
