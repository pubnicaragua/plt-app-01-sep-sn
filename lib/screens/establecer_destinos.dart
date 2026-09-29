import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';

class EstablecerDestinos extends StatefulWidget {
  const EstablecerDestinos({
    super.key,
    required this.origin,
    required this.destination,
    required this.originPlace,
    required this.destinationPlace,
    this.initialStops = const [],
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final List<TripStop> initialStops;

  @override
  State<EstablecerDestinos> createState() => _EstablecerDestinosState();
}

class _EstablecerDestinosState extends State<EstablecerDestinos> {
  late final List<TripStop> stops;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    stops = List<TripStop>.of(widget.initialStops);
  }

  List<_RoutePoint> get points => [
        _RoutePoint('A', widget.origin, widget.originPlace),
        ...stops.map((stop) => _RoutePoint(
              String.fromCharCode(66 + stop.order - 1),
              stop.address,
              PlaceSuggestion(
                placeId: stop.id ?? 'stop-${stop.order}',
                description: stop.address,
                main: stop.label,
                secondary: stop.address,
                latitude: stop.latitude,
                longitude: stop.longitude,
              ),
            )),
        _RoutePoint('Destino', widget.destination, widget.destinationPlace),
      ];

  Future<void> _addDestination() async {
    final place = await Navigator.of(context).push<PlaceSuggestion>(
      MaterialPageRoute(
        builder: (_) => const _AddDestinationPage(),
      ),
    );
    if (!mounted || place == null) return;
    setState(() {
      stops.add(
        TripStop(
          label: 'Destino adicional',
          address: place.description,
          latitude: place.latitude,
          longitude: place.longitude,
          order: stops.length + 1,
        ),
      );
    });
    _fitMap();
  }

  void _fitMap() {
    final coordinates = points
        .map((point) => point.place)
        .where((place) => place?.latitude != null && place?.longitude != null)
        .map((place) => LatLng(place!.latitude!, place.longitude!))
        .toList();
    if (mapController == null || coordinates.isEmpty) return;
    if (coordinates.length == 1) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(coordinates.first, 14));
      return;
    }
    var minLat = coordinates.first.latitude;
    var maxLat = minLat;
    var minLng = coordinates.first.longitude;
    var maxLng = minLng;
    for (final point in coordinates.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      42,
    ));
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DestinationsMapView(points: points),
      ),
    );
  }

  Set<Marker> get markers => {
        for (var index = 0; index < points.length; index++)
          if (points[index].place?.latitude != null &&
              points[index].place?.longitude != null)
            Marker(
              markerId: MarkerId('route-${points[index].label}'),
              position: LatLng(
                points[index].place!.latitude!,
                points[index].place!.longitude!,
              ),
              infoWindow: InfoWindow(
                title: 'Ruta ${points[index].label}',
                snippet: points[index].name,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                index == 0
                    ? BitmapDescriptor.hueGreen
                    : index == 1
                        ? BitmapDescriptor.hueRed
                        : BitmapDescriptor.hueAzure,
              ),
            ),
      };

  Set<Polyline> get polylines {
    final coordinates = points
        .map((point) => point.place)
        .where((place) => place?.latitude != null && place?.longitude != null)
        .map((place) => LatLng(place!.latitude!, place.longitude!))
        .toList();
    if (coordinates.length < 2) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('multi-route'),
        points: coordinates,
        color: accentBlue,
        width: 5,
        jointType: JointType.round,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        backgroundLogoOpacity: .18,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const Expanded(
                      child: Text(
                        'Establecer varios destinos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                      borderRadius: 18,
                      color: Colors.white.withValues(alpha: .08),
                      child: Column(
                        children: [
                          for (var index = 0; index < points.length; index++)
                            _RouteRow(
                              point: points[index],
                              removable: index > 0 && index < points.length - 1,
                              showMap: index == points.length - 1,
                              onMap: _openMap,
                              onRemove: index > 0 && index < points.length - 1
                                  ? () => setState(() {
                                        // points empieza con A, por eso la
                                        // primera parada corresponde a stops[0].
                                        stops.removeAt(index - 1);
                                        for (var i = 0; i < stops.length; i++) {
                                          stops[i] = TripStop(
                                            id: stops[i].id,
                                            label: stops[i].label,
                                            address: stops[i].address,
                                            order: i + 1,
                                            latitude: stops[i].latitude,
                                            longitude: stops[i].longitude,
                                            refs: stops[i].refs,
                                          );
                                        }
                                      })
                                  : null,
                            ),
                          const SizedBox(height: 9),
                          GlassButton(
                            label: 'Agregar ruta adicional',
                            onPressed: _addDestination,
                            icon: Icons.add_rounded,
                            filled: true,
                            height: 40,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                child: GlassButton(
                  label: 'Confirmar destinos',
                  onPressed: () => Navigator.of(context).pop(stops),
                  filled: true,
                  height: 50,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePoint {
  const _RoutePoint(this.label, this.name, this.place);

  final String label;
  final String name;
  final PlaceSuggestion? place;
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.point,
    required this.removable,
    required this.showMap,
    required this.onMap,
    this.onRemove,
  });

  final _RoutePoint point;
  final bool removable;
  final bool showMap;
  final VoidCallback onMap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: point.label == 'A' ? cyan : accentBlue,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                point.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          if (showMap)
            GlassButton(
              label: 'Mapa',
              onPressed: onMap,
              filled: true,
              width: 64,
              height: 32,
              fontSize: 10,
            ),
          if (removable) ...[
            const SizedBox(width: 6),
            GlassButton(
              label: 'Eliminar',
              onPressed: onRemove!,
              width: 78,
              height: 32,
              fontSize: 10,
              filled: true,
              backgroundColor: const Color(0xFFB83750),
            ),
          ],
        ],
      ),
    );
  }
}

class _DestinationsMapView extends StatefulWidget {
  const _DestinationsMapView({required this.points});

  final List<_RoutePoint> points;

  @override
  State<_DestinationsMapView> createState() => _DestinationsMapViewState();
}

class _DestinationsMapViewState extends State<_DestinationsMapView> {
  GoogleMapController? controller;
  List<LatLng> roadRoute = const [];
  Map<String, BitmapDescriptor> markerIcons = const {};

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  List<LatLng> get coordinates => widget.points
      .map((point) => point.place)
      .where((place) => place?.latitude != null && place?.longitude != null)
      .map((place) => LatLng(place!.latitude!, place.longitude!))
      .toList();

  Future<void> _loadMapData() async {
    final icons = <String, BitmapDescriptor>{};
    for (var index = 0; index < widget.points.length; index++) {
      final label = widget.points[index].label;
      icons[label] = await _createLabelMarker(
        label,
        index == 0
            ? const Color(0xFF16C5E8)
            : index == widget.points.length - 1
                ? const Color(0xFFE53935)
                : accentBlue,
      );
    }
    final route = await _loadRoadRoute();
    if (!mounted) return;
    setState(() {
      markerIcons = icons;
      roadRoute = route.isEmpty ? coordinates : route;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => fitRoute());
  }

  Future<BitmapDescriptor> _createLabelMarker(String label, Color color) async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final center = const ui.Offset(size / 2, size / 2);
    final paint = ui.Paint()..color = color;
    canvas.drawCircle(center, 25, paint);
    final outline = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, 25, outline);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size - 8);
    textPainter.paint(
      canvas,
      ui.Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<List<LatLng>> _loadRoadRoute() async {
    final route = <LatLng>[];
    for (var index = 0; index < coordinates.length - 1; index++) {
      final leg = await _loadRoadLeg(coordinates[index], coordinates[index + 1]);
      if (leg.length < 2) return const [];
      route.addAll(route.isEmpty ? leg : leg.skip(1));
    }
    return route;
  }

  Future<List<LatLng>> _loadRoadLeg(LatLng from, LatLng to) async {
    final requests = <Uri>[];
    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'AIzaSyCMwxArmM-BEJuxgbjOiON8KdH_IsNH1F4',
    );
    if (!kIsWeb && mapsKey.isNotEmpty) {
      requests.add(Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '${from.latitude},${from.longitude}',
        'destination': '${to.latitude},${to.longitude}',
        'mode': 'driving',
        'alternatives': 'false',
        'key': mapsKey,
      }));
    }
    requests.add(Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}',
      {'overview': 'full', 'geometries': 'geojson'},
    ));
    for (final uri in requests) {
      try {
        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final payload = jsonDecode(response.body);
        if (uri.host == 'maps.googleapis.com') {
          if (payload is! Map || payload['status'] != 'OK') continue;
          final routes = payload['routes'];
          if (routes is! List || routes.isEmpty) continue;
          final route = routes.first;
          final legs = route is Map ? route['legs'] : null;
          final result = <LatLng>[];
          if (legs is List) {
            for (final leg in legs.whereType<Map>()) {
              final steps = leg['steps'];
              if (steps is! List) continue;
              for (final step in steps.whereType<Map>()) {
                final encoded = (step['polyline'] as Map?)?['points']?.toString();
                if (encoded == null || encoded.isEmpty) continue;
                final decoded = _decodePolyline(encoded);
                result.addAll(result.isEmpty ? decoded : decoded.skip(1));
              }
            }
          }
          if (result.length >= 2) return result;
        } else {
          if (payload is! Map || payload['code'] != 'Ok') continue;
          final routes = payload['routes'];
          final route = routes is List && routes.isNotEmpty ? routes.first : null;
          final geometry = route is Map ? route['geometry'] : null;
          final values = geometry is Map ? geometry['coordinates'] : null;
          if (values is! List) continue;
          final result = values
              .whereType<List>()
              .where((pair) => pair.length >= 2)
              .map((pair) => LatLng(
                    (pair[1] as num).toDouble(),
                    (pair[0] as num).toDouble(),
                  ))
              .toList();
          if (result.length >= 2) return result;
        }
      } catch (_) {
        // Intenta el proveedor siguiente.
      }
    }
    return const [];
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

  void fitRoute() {
    final values = coordinates;
    if (controller == null || values.isEmpty) return;
    if (values.length == 1) {
      controller!.animateCamera(CameraUpdate.newLatLngZoom(values.first, 14));
      return;
    }
    var minLat = values.first.latitude;
    var maxLat = minLat;
    var minLng = values.first.longitude;
    var maxLng = minLng;
    for (final value in values.skip(1)) {
      minLat = math.min(minLat, value.latitude);
      maxLat = math.max(maxLat, value.latitude);
      minLng = math.min(minLng, value.longitude);
      maxLng = math.max(maxLng, value.longitude);
    }
    controller!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      48,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta de destinos'),
        backgroundColor: const Color(0xFF0C1C53),
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: coordinates.isEmpty ? const LatLng(12.1026, -86.2632) : coordinates.first,
          zoom: 12.5,
        ),
        onMapCreated: (value) {
          controller = value;
          WidgetsBinding.instance.addPostFrameCallback((_) => fitRoute());
        },
        markers: {
          for (var index = 0; index < widget.points.length; index++)
            if (widget.points[index].place?.latitude != null &&
                widget.points[index].place?.longitude != null)
              Marker(
                markerId: MarkerId('map-${widget.points[index].label}'),
                position: LatLng(
                  widget.points[index].place!.latitude!,
                  widget.points[index].place!.longitude!,
                ),
                infoWindow: InfoWindow(
                  title: 'Ruta ${widget.points[index].label}',
                  snippet: widget.points[index].name,
                ),
                icon: index == widget.points.length - 1
                    ? BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      )
                    : markerIcons[widget.points[index].label] ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
              ),
        },
        polylines: {
          if (roadRoute.length >= 2)
            Polyline(
              polylineId: const PolylineId('destinations-route'),
              points: roadRoute,
              color: accentBlue,
              width: 5,
              jointType: JointType.round,
            ),
        },
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}

class _AddDestinationPage extends StatefulWidget {
  const _AddDestinationPage();

  @override
  State<_AddDestinationPage> createState() => _AddDestinationPageState();
}

class _AddDestinationPageState extends State<_AddDestinationPage> {
  final controller = TextEditingController();
  PlaceSuggestion? selected;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        backgroundLogoOpacity: .18,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const Text(
                      'Agregar ruta adicional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    const Text(
                      'Busca el nuevo destino',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 12),
                    PlaceAutocompleteField(
                      controller: controller,
                      label: 'Destino',
                      hint: 'Busca una dirección o referencia',
                      icon: Icons.location_on_outlined,
                      onSelected: (place) => setState(() => selected = place),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 16),
                      GlassCard(
                        color: Colors.white.withValues(alpha: .10),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined,
                                color: cyan, size: 22),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                selected!.description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () => Navigator.of(context).pop(selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      disabledBackgroundColor: Colors.white.withValues(alpha: .12),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Agregar destino',
                      style: TextStyle(
                        fontSize: 12,
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
      ),
    );
  }
}
