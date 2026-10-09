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
    this.collectRecipientDetails = false,
    this.initialRecipientName = '',
    this.initialRecipientPhone = '',
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final List<TripStop> initialStops;
  final bool collectRecipientDetails;
  final String initialRecipientName;
  final String initialRecipientPhone;

  @override
  State<EstablecerDestinos> createState() => _EstablecerDestinosState();
}

class _EstablecerDestinosState extends State<EstablecerDestinos> {
  late final List<TripStop> stops;
  late String origin;
  late String destination;
  PlaceSuggestion? originPlace;
  PlaceSuggestion? destinationPlace;
  String? destinationRecipientName;
  String? destinationRecipientPhone;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    stops = List<TripStop>.of(widget.initialStops);
    origin = widget.origin;
    destination = widget.destination;
    originPlace = widget.originPlace;
    destinationPlace = widget.destinationPlace;
    destinationRecipientName = widget.initialRecipientName;
    destinationRecipientPhone = widget.initialRecipientPhone;
  }

  List<_RoutePoint> get points {
    final routePoints = <_RoutePoint>[
      _RoutePoint('Origen', origin, originPlace),
    ];

    if (stops.isEmpty) {
      routePoints.add(
        _RoutePoint('1', destination, destinationPlace, isFinal: true),
      );
      return routePoints;
    }

    final fixedDestination = stops.first;
    routePoints.add(
      _RoutePoint(
        '1',
        fixedDestination.address,
        PlaceSuggestion(
          placeId: fixedDestination.id ?? 'stop-${fixedDestination.order}',
          description: fixedDestination.address,
          main: fixedDestination.label,
          secondary: fixedDestination.address,
          latitude: fixedDestination.latitude,
          longitude: fixedDestination.longitude,
        ),
      ),
    );

    for (final stop in stops.skip(1)) {
      routePoints.add(
        _RoutePoint(
          '${stop.order}',
          stop.address,
          PlaceSuggestion(
            placeId: stop.id ?? 'stop-${stop.order}',
            description: stop.address,
            main: stop.label,
            secondary: stop.address,
            latitude: stop.latitude,
            longitude: stop.longitude,
          ),
        ),
      );
    }

    routePoints.add(
      _RoutePoint(
        '${stops.length + 1}',
        destination,
        destinationPlace,
        isFinal: true,
      ),
    );
    return routePoints;
  }

  Future<void> _editEndpoint({
    required bool isOrigin,
    bool isFixedDestination = false,
  }) async {
    final updated = await Navigator.of(context).push<PlaceSuggestion>(
      MaterialPageRoute(
        builder: (_) => _EditRoutePointPage(
          isOrigin: isOrigin,
          initialAddress: isOrigin
              ? origin
              : isFixedDestination && stops.isNotEmpty
                  ? stops.first.address
                  : destination,
          initialPlace: isOrigin
              ? originPlace
              : isFixedDestination && stops.isNotEmpty
                  ? PlaceSuggestion(
                      placeId: stops.first.id ?? 'stop-${stops.first.order}',
                      description: stops.first.address,
                      main: stops.first.label,
                      secondary: stops.first.address,
                      latitude: stops.first.latitude,
                      longitude: stops.first.longitude,
                    )
                  : destinationPlace,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      if (isOrigin) {
        origin = updated.description;
        originPlace = updated;
      } else if (isFixedDestination && stops.isNotEmpty) {
        final fixed = stops.first;
        stops[0] = TripStop(
          id: fixed.id,
          label: fixed.label,
          address: updated.description,
          order: fixed.order,
          latitude: updated.latitude,
          longitude: updated.longitude,
          refs: fixed.refs,
          recipientName: fixed.recipientName,
          recipientPhone: fixed.recipientPhone,
        );
      } else {
        destination = updated.description;
        destinationPlace = updated;
      }
    });
  }

  Future<void> _addDestination() async {
    final addedDestination =
        await Navigator.of(context).push<_AddedDestination>(
      MaterialPageRoute(
        builder: (_) => _AddDestinationPage(
          collectRecipientDetails: widget.collectRecipientDetails,
        ),
      ),
    );
    if (!mounted || addedDestination == null) return;
    setState(() {
      // El destino que ya estaba seleccionado conserva la primera posición.
      // El nuevo pasa a ser el destino final, para que cada parada se mantenga
      // en el mismo orden en que fue agregada.
      stops.add(
        TripStop(
          id: 'stop-${DateTime.now().microsecondsSinceEpoch}',
          label: 'Destino adicional',
          address: destination,
          latitude: destinationPlace?.latitude,
          longitude: destinationPlace?.longitude,
          order: stops.length + 1,
          recipientName: destinationRecipientName,
          recipientPhone: destinationRecipientPhone,
        ),
      );
      destination = addedDestination.place.description;
      destinationPlace = addedDestination.place;
      destinationRecipientName = addedDestination.recipientName;
      destinationRecipientPhone = addedDestination.recipientPhone;
    });
    _fitMap();
  }

  void _confirmDestinations() {
    if (widget.collectRecipientDetails &&
        stops.any((stop) =>
            (stop.recipientName ?? '').trim().isEmpty ||
            (stop.recipientPhone ?? '').trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa el destinatario y teléfono de cada destino adicional.',
            style: TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(RouteDestinationsResult(
      origin: origin,
      destination: destination,
      originPlace: originPlace,
      destinationPlace: destinationPlace,
      stops: stops,
    ));
  }

  void _fitMap() {
    final coordinates = points
        .map((point) => point.place)
        .where((place) => place?.latitude != null && place?.longitude != null)
        .map((place) => LatLng(place!.latitude!, place.longitude!))
        .toList();
    if (mapController == null || coordinates.isEmpty) return;
    if (coordinates.length == 1) {
      mapController!
          .animateCamera(CameraUpdate.newLatLngZoom(coordinates.first, 14));
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
                        'Servicios adicionales',
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
                      child: Row(
                        children: [
                          AppGlassSurface(
                            borderRadius: 13,
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Padding(
                                padding: const EdgeInsets.all(9),
                                child: Image.asset(
                                  'assets/img/HomeCliente/route_multiple_stops.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Varios destinos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Figtree',
                                    )),
                                SizedBox(height: 3),
                                Text(
                                  'Agrega paradas y ordénalas según el recorrido que necesitas.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AppGlassSurface(
                        borderRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < points.length;
                                  index++)
                                Column(
                                  key: ValueKey(
                                      'route-point-$index-${points[index].place?.placeId ?? points[index].label}'),
                                  children: [
                                    _RouteRow(
                                      point: points[index],
                                      removable: stops.isNotEmpty && index >= 2,
                                      showMap: stops.isNotEmpty
                                          ? index == 1
                                          : index == points.length - 1,
                                      onMap: _openMap,
                                      showEdit: index == 0 ||
                                          (stops.isNotEmpty && index == 1) ||
                                          (stops.isEmpty &&
                                              index == points.length - 1),
                                      onEdit: () => _editEndpoint(
                                        isOrigin: index == 0,
                                        isFixedDestination: stops.isNotEmpty &&
                                            index == 1,
                                      ),
                                      onRemove: stops.isNotEmpty && index >= 2
                                          ? () => setState(() {
                                                if (index == points.length - 1) {
                                                  final previous = stops.removeLast();
                                                  destination = previous.address;
                                                  destinationPlace = PlaceSuggestion(
                                                    placeId: previous.id ??
                                                        'stop-${previous.order}',
                                                    description: previous.address,
                                                    main: previous.label,
                                                    secondary: previous.address,
                                                    latitude: previous.latitude,
                                                    longitude: previous.longitude,
                                                  );
                                                  destinationRecipientName =
                                                      previous.recipientName;
                                                  destinationRecipientPhone =
                                                      previous.recipientPhone;
                                                } else {
                                                  stops.removeAt(index - 1);
                                                }
                                                for (var i = 0;
                                                    i < stops.length;
                                                    i++) {
                                                  stops[i] = TripStop(
                                                    id: stops[i].id,
                                                    label: stops[i].label,
                                                    address: stops[i].address,
                                                    order: i + 1,
                                                    latitude: stops[i].latitude,
                                                    longitude: stops[i].longitude,
                                                    refs: stops[i].refs,
                                                    recipientName:
                                                        stops[i].recipientName,
                                                    recipientPhone:
                                                        stops[i].recipientPhone,
                                                  );
                                                }
                                              })
                                          : null,
                                    ),
                                    if (index < points.length - 1)
                                      Container(
                                        height: 1,
                                        margin: const EdgeInsets.only(
                                            left: 37, top: 5, bottom: 5),
                                        color: Colors.white
                                            .withValues(alpha: .25),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _RouteAddButton(onPressed: _addDestination),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
                child: GlassButton(
                  label: 'Confirmar destinos',
                  onPressed: _confirmDestinations,
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
  const _RoutePoint(this.label, this.name, this.place, {this.isFinal = false});

  final String label;
  final String name;
  final PlaceSuggestion? place;
  final bool isFinal;
}

class RouteDestinationsResult {
  const RouteDestinationsResult({
    required this.origin,
    required this.destination,
    required this.originPlace,
    required this.destinationPlace,
    required this.stops,
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final List<TripStop> stops;
}

class _AddedDestination {
  const _AddedDestination({
    required this.place,
    this.recipientName,
    this.recipientPhone,
  });

  final PlaceSuggestion place;
  final String? recipientName;
  final String? recipientPhone;
}

class _DestinationContactInput extends StatelessWidget {
  const _DestinationContactInput({
    required this.label,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Figtree',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xBFFFFFFF),
          fontSize: 12,
          fontFamily: 'Figtree',
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: cyan),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.point,
    required this.removable,
    required this.showMap,
    required this.onMap,
    required this.showEdit,
    required this.onEdit,
    this.onRemove,
  });

  final _RoutePoint point;
  final bool removable;
  final bool showMap;
  final VoidCallback onMap;
  final bool showEdit;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (point.label == 'Origen')
            Image.asset(
              'assets/img/HomeCliente/route_origin_home.png',
              width: 27,
              height: 27,
            )
          else if (point.isFinal)
            Image.asset(
              'assets/img/HomeCliente/route_destination_flag.png',
              width: 27,
              height: 27,
            )
          else
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: accentBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                point.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
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
          if (showEdit) _RouteEditButton(onPressed: onEdit),
          if (showMap) ...[
            if (showEdit) const SizedBox(width: 7),
            GlassButton(
              label: 'Mapa',
              onPressed: onMap,
              filled: true,
              width: 58,
              height: 28,
              fontSize: 9,
            ),
          ],
          if (removable) ...[
            const SizedBox(width: 7),
            GlassButton(
              label: 'Eliminar',
              onPressed: onRemove!,
              width: 70,
              height: 28,
              fontSize: 9,
              filled: true,
              backgroundColor: const Color(0xCCB83750),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteEditButton extends StatelessWidget {
  const _RouteEditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: 18,
      child: SizedBox(
        width: 76,
        height: 30,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/img/HomeCliente/route_edit_pencil.png',
                    width: 13,
                    height: 13,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Editar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteAddButton extends StatelessWidget {
  const _RouteAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRouteBorderPainter(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 82,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/HomeCliente/route_add_plus.png',
                  width: 38,
                  height: 38,
                ),
                const SizedBox(width: 14),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar parada adicional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Puedes agregar más paradas si lo necesitas.',
                      style: TextStyle(
                        color: Color(0xCFFFFFFF),
                        fontSize: 10,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRouteBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(16),
      ));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 8, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditRoutePointPage extends StatefulWidget {
  const _EditRoutePointPage({
    required this.isOrigin,
    required this.initialAddress,
    required this.initialPlace,
  });

  final bool isOrigin;
  final String initialAddress;
  final PlaceSuggestion? initialPlace;

  @override
  State<_EditRoutePointPage> createState() => _EditRoutePointPageState();
}

class _EditRoutePointPageState extends State<_EditRoutePointPage> {
  late final TextEditingController controller;
  PlaceSuggestion? selected;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialAddress);
    controller.addListener(_onAddressChanged);
    selected = widget.initialPlace ??
        PlaceSuggestion(
          placeId: 'existing-route-point',
          description: widget.initialAddress,
          main: widget.initialAddress,
          secondary: '',
        );
  }

  @override
  void dispose() {
    controller.removeListener(_onAddressChanged);
    controller.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOrigin = widget.isOrigin;
    final title = isOrigin ? 'Editar origen' : 'Editar destino final';
    final canUseSelection = selected != null &&
        selected!.description.trim() == controller.text.trim();
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                    Text(title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PlaceAutocompleteField(
                  controller: controller,
                  label: isOrigin ? 'Origen' : 'Destino final',
                  hint: 'Busca una dirección o referencia',
                  icon: isOrigin ? Icons.home_outlined : Icons.flag_outlined,
                  onSelected: (place) => setState(() => selected = place),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: GlassButton(
                  label: 'Usar este punto',
                  filled: true,
                  height: 48,
                  fontSize: 13,
                  backgroundColor: canUseSelection
                      ? accentBlue
                      : Colors.white.withValues(alpha: .12),
                  onPressed: !canUseSelection
                      ? () {}
                      : () => Navigator.of(context).pop(selected!),
                ),
              ),
            ],
          ),
        ),
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
      final asset = index == 0
          ? 'assets/img/HomeCliente/route_origin_home.png'
          : index == widget.points.length - 1
              ? 'assets/img/HomeCliente/route_destination_flag.png'
              : null;
      icons[label] = asset != null
          ? await _createAssetMarker(asset)
          : await _createLabelMarker(label, accentBlue);
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
    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createAssetMarker(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 48,
      targetHeight: 48,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<List<LatLng>> _loadRoadRoute() async {
    if (coordinates.length < 2) return const [];

    // Solicita una sola ruta con todos los puntos para que el proveedor
    // mantenga una geometría continua y no se dibujen tramos duplicados
    // cuando dos destinos comparten parte del mismo camino.
    final combinedRoute = await _loadCombinedRoadRoute();
    if (combinedRoute.length >= 2) return combinedRoute;

    // Respaldo para cuando el proveedor no acepte varios puntos en una
    // misma solicitud.
    final route = <LatLng>[];
    for (var index = 0; index < coordinates.length - 1; index++) {
      final leg =
          await _loadRoadLeg(coordinates[index], coordinates[index + 1]);
      if (leg.length < 2) return const [];
      route.addAll(route.isEmpty ? leg : leg.skip(1));
    }
    return route;
  }

  Future<List<LatLng>> _loadCombinedRoadRoute() async {
    final requests = <Uri>[];
    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'AIzaSyCMwxArmM-BEJuxgbjOiON8KdH_IsNH1F4',
    );
    final first = coordinates.first;
    final last = coordinates.last;
    final waypoints = coordinates
        .sublist(1, coordinates.length - 1)
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');

    if (!kIsWeb && mapsKey.isNotEmpty) {
      requests.add(Uri.https(
        'maps.googleapis.com',
        '/maps/api/directions/json',
        {
          'origin': '${first.latitude},${first.longitude}',
          'destination': '${last.latitude},${last.longitude}',
          if (waypoints.isNotEmpty) 'waypoints': 'optimize:false|$waypoints',
          'mode': 'driving',
          'alternatives': 'false',
          'key': mapsKey,
        },
      ));
    }

    requests.add(Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${coordinates.map((point) => '${point.longitude},${point.latitude}').join(';')}',
      {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
    ));

    for (final uri in requests) {
      try {
        final response = await http.get(uri);
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final payload = jsonDecode(response.body);

        if (uri.host == 'maps.googleapis.com') {
          if (payload is! Map || payload['status'] != 'OK') continue;
          final routes = payload['routes'];
          final route =
              routes is List && routes.isNotEmpty ? routes.first : null;
          final overview = route is Map ? route['overview_polyline'] : null;
          final encoded =
              overview is Map ? overview['points']?.toString() : null;
          if (encoded != null && encoded.isNotEmpty) {
            final result = _decodePolyline(encoded);
            if (result.length >= 2) return result;
          }
        } else {
          if (payload is! Map || payload['code'] != 'Ok') continue;
          final routes = payload['routes'];
          final route =
              routes is List && routes.isNotEmpty ? routes.first : null;
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
        // Intenta el proveedor siguiente y, después, el respaldo por tramos.
      }
    }
    return const [];
  }

  Future<List<LatLng>> _loadRoadLeg(LatLng from, LatLng to) async {
    final requests = <Uri>[];
    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'AIzaSyCMwxArmM-BEJuxgbjOiON8KdH_IsNH1F4',
    );
    if (!kIsWeb && mapsKey.isNotEmpty) {
      requests
          .add(Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
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
                final encoded =
                    (step['polyline'] as Map?)?['points']?.toString();
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
          final route =
              routes is List && routes.isNotEmpty ? routes.first : null;
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
          target: coordinates.isEmpty
              ? const LatLng(12.1026, -86.2632)
              : coordinates.first,
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
                icon: markerIcons[widget.points[index].label] ??
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
  const _AddDestinationPage({required this.collectRecipientDetails});

  final bool collectRecipientDetails;

  @override
  State<_AddDestinationPage> createState() => _AddDestinationPageState();
}

class _AddDestinationPageState extends State<_AddDestinationPage> {
  final controller = TextEditingController();
  PlaceSuggestion? selected;
  String recipientName = '';
  String recipientPhone = '';

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
                      if (widget.collectRecipientDetails) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'Destinatario de este punto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        const SizedBox(height: 9),
                        _DestinationContactInput(
                          label: 'Nombre del destinatario *',
                          onChanged: (value) =>
                              setState(() => recipientName = value),
                        ),
                        const SizedBox(height: 9),
                        _DestinationContactInput(
                          label: 'Teléfono del destinatario *',
                          keyboardType: TextInputType.phone,
                          onChanged: (value) =>
                              setState(() => recipientPhone = value),
                        ),
                      ],
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
                    onPressed: selected == null ||
                            (widget.collectRecipientDetails &&
                                (recipientName.trim().isEmpty ||
                                    recipientPhone.trim().isEmpty))
                        ? null
                        : () => Navigator.of(context).pop(
                              _AddedDestination(
                                place: selected!,
                                recipientName: widget.collectRecipientDetails
                                    ? recipientName.trim()
                                    : null,
                                recipientPhone: widget.collectRecipientDetails
                                    ? recipientPhone.trim()
                                    : null,
                              ),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: .12),
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
