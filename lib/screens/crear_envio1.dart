import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';
import '../widgets/wizard.dart';
import 'confirmar_pedido.dart';
import 'crear_envio2.dart';
import 'seleccionar_puntos_envio.dart';

/// Primera vista del flujo de creación de envío.
///
/// El formulario de carga se conserva en [_CargaDetailsPage] como el paso
/// siguiente. Así, CrearEnvio1 queda alineado con el diseño de Figma sin
/// perder la información que ya se enviaba al confirmar el pedido.
class CrearEnvio1 extends StatefulWidget {
  const CrearEnvio1({
    super.key,
    this.startOrigin = '',
    this.startDestination = '',
    this.startOriginPlace,
    this.startDestinationPlace,
    this.startTransport = 'Moto',
    this.startOriginRefs = '',
    this.startDestinationRefs = '',
    this.startRecipientName = '',
    this.startRecipientPhone = '',
    this.startScheduled = false,
    this.startDate,
    this.startTime,
    this.returnToPointSelection = false,
  });

  final String startOrigin;
  final String startDestination;
  final PlaceSuggestion? startOriginPlace;
  final PlaceSuggestion? startDestinationPlace;
  final String startTransport;
  final String startOriginRefs;
  final String startDestinationRefs;
  final String startRecipientName;
  final String startRecipientPhone;
  final bool startScheduled;
  final String? startDate;
  final String? startTime;
  final bool returnToPointSelection;

  @override
  State<CrearEnvio1> createState() => _CrearEnvio1State();
}

class _CrearEnvio1State extends State<CrearEnvio1> {
  late final TextEditingController origin;
  late final TextEditingController destination;
  PlaceSuggestion? originPlace;
  PlaceSuggestion? destinationPlace;
  late String transport;
  String serviceTab = 'Envíos';
  AppSettings? settings;
  Timer? _settingsPoll;
  GoogleMapController? _mapController;
  List<LatLng> _roadRoute = const [];
  double? _routeDistanceKm;
  int? _routeDurationSeconds;
  bool _routeLoading = false;

  @override
  void initState() {
    super.initState();
    origin = TextEditingController(text: widget.startOrigin);
    destination = TextEditingController(text: widget.startDestination);
    originPlace = widget.startOriginPlace;
    destinationPlace = widget.startDestinationPlace;
    transport = _normalizeTransport(widget.startTransport);

    apiClient.getSettings().then((data) {
      if (mounted) setState(() => settings = data);
    }).catchError((_) {});
    _settingsPoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSettings(),
    );

    if (originPlace == null) {
      requestCurrentLocation().then((location) {
        if (!mounted || location == null || origin.text.trim().isNotEmpty) {
          return;
        }
        final current = PlaceSuggestion(
          placeId: 'current',
          description: location.label,
          main: location.label,
          secondary: 'Managua',
          latitude: location.latitude,
          longitude: location.longitude,
        );
        setState(() {
          originPlace = current;
          origin.text = location.label;
        });
        _loadRoadRoute();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoadRoute());
  }

  String _normalizeTransport(String value) {
    if (value == 'Auto') return 'Vehículo';
    if (value == 'Carga') return 'Camión';
    return value == 'Vehículo' || value == 'Camión' ? value : 'Moto';
  }

  Future<void> _refreshSettings() async {
    try {
      final data = await apiClient.getSettings();
      if (mounted) setState(() => settings = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _settingsPoll?.cancel();
    origin.dispose();
    destination.dispose();
    super.dispose();
  }

  double? get _straightDistanceKm {
    final from = originPlace;
    final to = destinationPlace;
    if (from?.latitude == null ||
        from?.longitude == null ||
        to?.latitude == null ||
        to?.longitude == null) {
      return null;
    }
    return haversineKm(
      from!.latitude!,
      from.longitude!,
      to!.latitude!,
      to.longitude!,
    );
  }

  double? get _distanceKm => _routeDistanceKm ?? _straightDistanceKm;

  VehicleRate _rateFor(String vehicle) =>
      settings?.rateFor(vehicle) ??
      const VehicleRate(baseFeeCs: 80, farePerKmCs: 8.5, includedKm: 4);

  double? _priceFor(String vehicle) {
    final distance = _distanceKm;
    if (distance == null) return null;
    final rate = _rateFor(vehicle);
    final chargeableKm =
        (distance - rate.includedKm).clamp(0, double.infinity).toDouble();
    return roundFareCs(
      rate.baseFeeCs + chargeableKm * rate.farePerKmCs + logisticsServiceFeeCs,
      settings?.fareRoundingCs ?? 5,
    );
  }

  Future<void> _selectPlace(
      {required bool isOrigin, required PlaceSuggestion place}) async {
    setState(() {
      if (isOrigin) {
        originPlace = place;
        origin.text = place.description;
      } else {
        destinationPlace = place;
        destination.text = place.description;
      }
      _roadRoute = const [];
      _routeDistanceKm = null;
      _routeDurationSeconds = null;
    });
    await _loadRoadRoute();
  }

  Future<void> _loadRoadRoute() async {
    final from = originPlace;
    final to = destinationPlace;
    if (from?.latitude == null ||
        from?.longitude == null ||
        to?.latitude == null ||
        to?.longitude == null) {
      return;
    }
    if (_routeLoading) return;
    setState(() => _routeLoading = true);
    final fromLat = from!.latitude!;
    final fromLng = from.longitude!;
    final toLat = to!.latitude!;
    final toLng = to.longitude!;
    final requests = <Uri>[];
    const mapsKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: 'AIzaSyCMwxArmM-BEJuxgbjOiON8KdH_IsNH1F4',
    );
    // En web se usa OSRM directamente porque Directions de Google bloquea
    // el fetch del navegador por CORS. En Android/iOS Google queda primero.
    if (!kIsWeb && mapsKey.isNotEmpty) {
      requests
          .add(Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '$fromLat,$fromLng',
        'destination': '$toLat,$toLng',
        'mode': 'driving',
        'alternatives': 'false',
        'key': mapsKey,
      }));
    }
    requests.add(Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat',
      {'overview': 'full', 'geometries': 'geojson'},
    ));

    try {
      for (final uri in requests) {
        try {
          final response = await http.get(uri);
          if (response.statusCode < 200 || response.statusCode >= 300) continue;
          final payload = jsonDecode(response.body);
          List<LatLng> points = const [];
          double? distanceKm;
          int? durationSeconds;
          if (uri.host == 'maps.googleapis.com') {
            if (payload is! Map || payload['status'] != 'OK') continue;
            final routes = payload['routes'];
            if (routes is! List || routes.isEmpty) continue;
            final route = routes.first;
            points = _decodeGoogleRoute(route);
            final legs = route is Map ? route['legs'] : null;
            if (legs is List) {
              var meters = 0.0;
              var seconds = 0;
              for (final leg in legs.whereType<Map>()) {
                final legDistance = leg['distance'];
                final legDuration =
                    leg['duration_in_traffic'] ?? leg['duration'];
                meters += (legDistance is Map
                        ? (legDistance['value'] as num?)?.toDouble()
                        : null) ??
                    0;
                seconds += (legDuration is Map
                        ? (legDuration['value'] as num?)?.toInt()
                        : null) ??
                    0;
              }
              if (meters > 0) distanceKm = meters / 1000;
              if (seconds > 0) durationSeconds = seconds;
            }
          } else {
            if (payload is! Map || payload['code'] != 'Ok') continue;
            final routes = payload['routes'];
            final route =
                routes is List && routes.isNotEmpty ? routes.first : null;
            final geometry = route is Map ? route['geometry'] : null;
            final coordinates =
                geometry is Map ? geometry['coordinates'] : null;
            if (coordinates is! List) continue;
            points = coordinates
                .whereType<List>()
                .where((pair) => pair.length >= 2)
                .map((pair) => LatLng(
                      (pair[1] as num).toDouble(),
                      (pair[0] as num).toDouble(),
                    ))
                .toList();
            if (route is Map) {
              final meters = (route['distance'] as num?)?.toDouble();
              distanceKm = meters == null ? null : meters / 1000;
              durationSeconds = (route['duration'] as num?)?.toInt();
            }
          }
          if (points.length < 2) continue;
          if (!mounted) return;
          setState(() {
            _roadRoute = points;
            _routeDistanceKm = distanceKm;
            _routeDurationSeconds = durationSeconds;
          });
          _fitRoute(points);
          return;
        } catch (_) {
          // Prueba el proveedor siguiente.
        }
      }
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  List<LatLng> _decodeGoogleRoute(dynamic route) {
    final points = <LatLng>[];
    final legs = route is Map ? route['legs'] : null;
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
          points.addAll(points.isNotEmpty && decoded.isNotEmpty
              ? decoded.skip(1)
              : decoded);
        }
      }
    }
    if (points.length >= 2) return points;
    final overview = route is Map ? route['overview_polyline'] : null;
    final encoded = overview is Map ? overview['points']?.toString() : null;
    return encoded == null || encoded.isEmpty
        ? const []
        : _decodePolyline(encoded);
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
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 54));
  }

  LatLng get _mapCenter {
    final place = originPlace;
    if (place?.latitude != null && place?.longitude != null) {
      return LatLng(place!.latitude!, place.longitude!);
    }
    return const LatLng(12.1364, -86.2514);
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final from = originPlace;
    final to = destinationPlace;
    if (from?.latitude != null && from?.longitude != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(from!.latitude!, from.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }
    if (to?.latitude != null && to?.longitude != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(to!.latitude!, to.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    return markers;
  }

  Set<Polyline> get _polylines => _roadRoute.length < 2
      ? const {}
      : {
          Polyline(
            polylineId: const PolylineId('delivery-route'),
            points: _roadRoute,
            color: const Color(0xFF1677FF),
            width: 6,
            jointType: JointType.round,
          ),
        };

  Future<void> _editRoutePoints() async {
    final result = await Navigator.of(context).push<RouteSelectionResult>(
      MaterialPageRoute(
        builder: (_) => SeleccionarPuntosEnvio(
          startOrigin: origin.text.trim(),
          startDestination: destination.text.trim(),
          startOriginPlace: originPlace,
          startDestinationPlace: destinationPlace,
          startTransport: transport,
          selectionOnly: true,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      origin.text = result.origin;
      destination.text = result.destination;
      originPlace = result.originPlace;
      destinationPlace = result.destinationPlace;
      _roadRoute = const [];
      _routeDistanceKm = null;
      _routeDurationSeconds = null;
    });
    await _loadRoadRoute();
  }

  void _handleMapBack() {
    if (!widget.returnToPointSelection) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(
      RouteSelectionResult(
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        originPlace: originPlace,
        destinationPlace: destinationPlace,
      ),
    );
  }

  Future<void> _continueToDetails() async {
    if (originPlace == null || destinationPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona el lugar de recogida y entrega.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CrearEnvio2(
          origin: origin.text.trim(),
          destination: destination.text.trim(),
          originPlace: originPlace,
          destinationPlace: destinationPlace,
          transport: transport,
          estimatedShipping: _priceFor(transport),
          originRefs: widget.startOriginRefs,
          destinationRefs: widget.startDestinationRefs,
          recipientName: widget.startRecipientName,
          recipientPhone: widget.startRecipientPhone,
          startScheduled: widget.startScheduled,
          startDate: widget.startDate,
          startTime: widget.startTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sheetHeight = (size.height * .54).clamp(390.0, 540.0).toDouble();
    return Scaffold(
      backgroundColor: const Color(0xFF082B66),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _mapCenter, zoom: 12.5),
            padding: EdgeInsets.only(bottom: sheetHeight * .80),
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
              _mapController = controller;
              _fitRoute(_roadRoute);
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 12,
            child: _MapBackButton(onTap: _handleMapBack),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: sheetHeight,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xD91F477F), Color(0xC2173264)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x45000000),
                blurRadius: 26,
                offset: Offset(0, -8),
              ),
            ],
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: .28)),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Enviar paquete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: accentBlue,
                        minimumSize: const Size(84, 32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Programar',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _RouteEditor(
                  origin: origin,
                  destination: destination,
                  onOriginSelected: (place) =>
                      _selectPlace(isOrigin: true, place: place),
                  onDestinationSelected: (place) =>
                      _selectPlace(isOrigin: false, place: place),
                  loading: _routeLoading,
                  durationSeconds: _routeDurationSeconds,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final label in ['Envíos', 'Taxi Privado'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: _ServiceTab(
                            label: label,
                            selected: serviceTab == label,
                            enabled: true,
                            onTap: () => setState(() => serviceTab = label),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ImageVehicleCard(
                      label: 'Moto',
                      subtitle: 'Envíos en moto',
                      asset: 'assets/img/HomeCliente/crear_moto.png',
                      selected: transport == 'Moto',
                      onTap: () => setState(() => transport = 'Moto'),
                    ),
                    const SizedBox(width: 7),
                    _ImageVehicleCard(
                      label: 'Auto',
                      subtitle: 'Envíos en auto',
                      asset: 'assets/img/HomeCliente/crear_auto.png',
                      selected: transport == 'Vehículo',
                      onTap: () => setState(() => transport = 'Vehículo'),
                    ),
                    const SizedBox(width: 7),
                    _ImageVehicleCard(
                      label: 'Carga',
                      subtitle: 'Carga',
                      asset: 'assets/img/HomeCliente/crear_carga.png',
                      selected: transport == 'Camión',
                      onTap: () => setState(() => transport = 'Camión'),
                    ),
                  ],
                ),
                if (_distanceKm != null) ...[
                  const SizedBox(height: 8),
                  _SelectedRateSummary(
                    vehicle: transport == 'Moto'
                        ? 'Moto'
                        : transport == 'Vehículo'
                            ? 'Auto'
                            : 'Carga',
                    distanceKm: _distanceKm!,
                    routeDistanceKm: _routeDistanceKm,
                    price: _priceFor(transport)!,
                    rate: _rateFor(transport),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  height: 43,
                  child: ElevatedButton(
                    onPressed: _continueToDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Completar formulario de envío',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapBackButton extends StatelessWidget {
  const _MapBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC123E68),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _RouteEditor extends StatelessWidget {
  const _RouteEditor({
    required this.origin,
    required this.destination,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.loading,
    required this.durationSeconds,
  });

  final TextEditingController origin;
  final TextEditingController destination;
  final ValueChanged<PlaceSuggestion> onOriginSelected;
  final ValueChanged<PlaceSuggestion> onDestinationSelected;
  final bool loading;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    final minutes = durationSeconds == null
        ? null
        : (durationSeconds! / 60).ceil().clamp(1, 999);
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 11, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: .24)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Image.asset(
                  'assets/img/HomeCliente/punto_desde.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: PlaceAutocompleteField(
                  controller: origin,
                  label: 'Desde',
                  hint: 'Selecciona el punto de recogida',
                  bare: true,
                  onSelected: onOriginSelected,
                ),
              ),
            ],
          ),
          Container(
            height: 1,
            margin:
                const EdgeInsets.only(left: 31, right: 1, top: 2, bottom: 2),
            color: Colors.white.withValues(alpha: .26),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Image.asset(
                  'assets/img/HomeCliente/punto_hasta.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: PlaceAutocompleteField(
                  controller: destination,
                  label: 'Hacia',
                  hint: 'Selecciona el punto de entrega',
                  bare: true,
                  onSelected: onDestinationSelected,
                ),
              ),
              if (minutes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '$minutes min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(left: 26, right: 1, top: 2),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: cyan,
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceTab extends StatelessWidget {
  const _ServiceTab({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? accentBlue.withValues(alpha: .86)
                  : enabled
                      ? Colors.white.withValues(alpha: .08)
                      : Colors.black.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? cyan
                    : enabled
                        ? Colors.white.withValues(alpha: .24)
                        : Colors.white.withValues(alpha: .12),
              ),
            ),
            child: Opacity(
              opacity: enabled ? 1 : .55,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageVehicleCard extends StatelessWidget {
  const _ImageVehicleCard({
    required this.label,
    required this.subtitle,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 104,
              padding: const EdgeInsets.fromLTRB(7, 4, 7, 6),
              decoration: BoxDecoration(
                color: selected
                    ? accentBlue.withValues(alpha: .40)
                    : Colors.white.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected ? cyan : Colors.white.withValues(alpha: .22),
                  width: selected ? 1.2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.asset(
                      asset,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white70,
                        size: 30,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xBFFFFFFF),
                      fontSize: 8,
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

class _SelectedRateSummary extends StatelessWidget {
  const _SelectedRateSummary({
    required this.vehicle,
    required this.distanceKm,
    required this.routeDistanceKm,
    required this.price,
    required this.rate,
  });

  final String vehicle;
  final double distanceKm;
  final double? routeDistanceKm;
  final double price;
  final VehicleRate rate;

  @override
  Widget build(BuildContext context) {
    final routeKm = routeDistanceKm ?? distanceKm;
    final extraKm = (routeKm - rate.includedKm).clamp(0, double.infinity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: .28)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.payments_outlined, color: cyan, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tarifa estimada · $vehicle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                  Text(
                    'C\$ ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${routeKm.toStringAsFixed(1)} km · base C\$ ${rate.baseFeeCs.toStringAsFixed(0)} + ${extraKm.toStringAsFixed(1)} km adicionales × C\$ ${rate.farePerKmCs.toStringAsFixed(1)} + C\$ ${logisticsServiceFeeCs.toStringAsFixed(0)} servicio',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 8.8,
                    height: 1.2,
                    fontFamily: 'Figtree',
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

class _CargaDetailsPage extends StatefulWidget {
  const _CargaDetailsPage({
    super.key,
    this.startOrigin = '',
    this.startDestination = '',
    this.startOriginPlace,
    this.startDestinationPlace,
    this.startTransport = 'Moto',
    this.startOriginRefs = '',
    this.startDestinationRefs = '',
    this.startRecipientName = '',
    this.startRecipientPhone = '',
    this.startScheduled = false,
    this.startDate,
    this.startTime,
  });

  final String startOrigin;
  final String startDestination;
  final PlaceSuggestion? startOriginPlace;
  final PlaceSuggestion? startDestinationPlace;
  final String startTransport;
  final String startOriginRefs;
  final String startDestinationRefs;
  final String startRecipientName;
  final String startRecipientPhone;
  final bool startScheduled;
  final String? startDate;
  final String? startTime;

  @override
  State<_CargaDetailsPage> createState() => _CargaDetailsState();
}

class _CargaDetailsState extends State<_CargaDetailsPage> {
  int weight = 10;
  String weightUnit = 'kg';
  int bundles = 1;
  late String transport;
  late final TextEditingController origin;
  late final TextEditingController destination;
  late PlaceSuggestion? originPlace;
  late PlaceSuggestion? destinationPlace;
  AppSettings? settings;
  Timer? _settingsPoll;
  final description = TextEditingController();
  final invoicePrice = TextEditingController(text: '0,00');
  final invoiceNumber = TextEditingController(text: 'FAC-1003');
  late final TextEditingController recipient;
  late final TextEditingController phone;
  bool fragile = true;
  String currency = 'C\$';
  String paymentStatus = 'Pendiente';
  String paymentMethod = 'Efectivo';
  final productPhotos = <Uint8List>[];
  Uint8List? invoicePhoto;

  @override
  void initState() {
    super.initState();
    transport = widget.startTransport;
    origin = TextEditingController(text: widget.startOrigin);
    destination = TextEditingController(text: widget.startDestination);
    recipient = TextEditingController(text: widget.startRecipientName);
    phone = TextEditingController(text: widget.startRecipientPhone);
    originPlace = widget.startOriginPlace;
    destinationPlace = widget.startDestinationPlace;
    if (origin.text.isEmpty && widget.startOriginPlace == null) {
      requestCurrentLocation().then((location) {
        if (location != null) {
          originPlace = PlaceSuggestion(
            placeId: 'current',
            description: '${location.label}',
            main: location.label,
            secondary: 'Managua',
            latitude: location.latitude,
            longitude: location.longitude,
          );
          if (mounted) origin.text = location.label;
        }
      });
    }
    apiClient.getSettings().then((data) {
      if (mounted) setState(() => settings = data);
    }).catchError((_) {});
    _settingsPoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshSettings(),
    );
  }

  Future<void> _refreshSettings() async {
    try {
      final data = await apiClient.getSettings();
      if (mounted) setState(() => settings = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _settingsPoll?.cancel();
    origin.dispose();
    destination.dispose();
    description.dispose();
    invoicePrice.dispose();
    invoiceNumber.dispose();
    recipient.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _takePhoto({required bool invoice}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 78,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (invoice) {
          invoicePhoto = bytes;
        } else if (productPhotos.length < 5) {
          productPhotos.add(bytes);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la cámara.')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery({required bool invoice}) async {
    if (!invoice && productPhotos.length >= 5) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 78,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (invoice) {
          invoicePhoto = bytes;
        } else {
          productPhotos.add(bytes);
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo seleccionar la imagen.')),
        );
      }
    }
  }

  double get _invoiceAmount {
    final normalized = invoicePrice.text
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double get _invoiceAmountCs =>
      _invoiceAmount * (currency == 'USD' ? settings?.dollarRate ?? 36.5 : 1);

  double? get _distanceKm {
    final from = originPlace;
    final to = destinationPlace;
    if (from == null || to == null) return null;
    final fromLatitude = from.latitude;
    final fromLongitude = from.longitude;
    final toLatitude = to.latitude;
    final toLongitude = to.longitude;
    if (fromLatitude == null ||
        fromLongitude == null ||
        toLatitude == null ||
        toLongitude == null) {
      return null;
    }
    return haversineKm(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }

  double get _weightKg =>
      weightUnit == 'lb' ? weight / 2.20462 : weight.toDouble();

  String get _recommended {
    if (_weightKg <= 20) return 'Moto';
    if (_weightKg <= 200) return 'Vehículo';
    return 'Camión';
  }

  double? _priceFor(String vehicle) {
    final distance = _distanceKm;
    if (distance == null) return null;
    final rate = settings?.rateFor(vehicle);
    if (rate == null) return null;
    final chargeableKm =
        (distance - rate.includedKm).clamp(0, double.infinity).toDouble();
    return roundFareCs(
        rate.baseFeeCs +
            chargeableKm * rate.farePerKmCs +
            logisticsServiceFeeCs,
        settings?.fareRoundingCs ?? 5);
  }

  @override
  Widget build(BuildContext context) {
    final distance = _distanceKm;
    final price = _priceFor(transport);
    final selectedInvoicePhoto = invoicePhoto;
    return WizardScaffold(
      title: 'Detalles de carga',
      subtitle: '¿Qué tipo de carga enviarás?',
      description:
          'Indica las características de tu carga y te recomendamos el transporte adecuado.',
      step: 0,
      onClose: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: cyan, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Peso y dimensiones',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Paso 1',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Calcula el peso y dimensiones que necesitas',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundStep(
                      icon: Icons.remove,
                      onTap:
                          weight > 1 ? () => setState(() => weight -= 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '$weight $weightUnit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    RoundStep(
                      icon: Icons.add,
                      onTap: () => setState(() => weight += 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final unit in ['kg', 'lb'])
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (weightUnit == unit) return;
                            final converted = unit == 'lb'
                                ? (weight * 2.20462).round().clamp(1, 9999)
                                : (weight / 2.20462).round().clamp(1, 9999);
                            weightUnit = unit;
                            weight = converted;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: weightUnit == unit
                                ? figmaBlue
                                : Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: weightUnit == unit
                                  ? cyan
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            unit.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    'Cambia la unidad según la use tu cliente u operación',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 9.5,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Atajo:',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 10.5,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 9,
                  children: [
                    for (final value in [5, 10, 40, 405]) _weightChip(value),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: Colors.white.withValues(alpha: .14), height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cantidad de bultos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$bundles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundStep(
                      icon: Icons.remove,
                      onTap: bundles > 1
                          ? () => setState(() => bundles -= 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        '$bundles bulto${bundles == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    RoundStep(
                      icon: Icons.add,
                      onTap: () => setState(() => bundles += 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Información del paquete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cyan,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Paso 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'DESCRIPCIÓN DEL PAQUETE',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 8),
                GlassField(
                  label: 'Descripción',
                  hint: 'Ej. Electrónicos, ropa, documentos…',
                  controller: description,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: GlassField(
                        label: 'Precio de factura',
                        hint: '0,00',
                        controller: invoicePrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CurrencyChoice(
                      value: currency,
                      onChanged: (value) => setState(() => currency = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassField(
                  label: 'Número de factura',
                  hint: 'FAC-1003',
                  controller: invoiceNumber,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GlassField(
                        label: 'Destinatario',
                        hint: 'Nombre completo',
                        controller: recipient,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: GlassField(
                        label: 'Teléfono',
                        hint: '+505 …',
                        controller: phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF5C63), size: 21),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Carga frágil?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            Text(
                              'Requiere manejo especial',
                              style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 10,
                                fontFamily: 'Figtree',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        fragile ? 'SÍ' : 'NO',
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                      Switch.adaptive(
                        value: fragile,
                        onChanged: (value) => setState(() => fragile = value),
                        activeThumbColor: cyan,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EVIDENCIAS DEL PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _takePhoto(invoice: false),
                  child: Container(
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: glassBorder),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            color: cyan, size: 25),
                        SizedBox(height: 5),
                        Text(
                          'Tomar foto del producto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        Text(
                          'JPG, PNG · máximo 5 MB por archivo',
                          style: TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 9.5,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final photo in productPhotos)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(photo,
                            width: 62, height: 62, fit: BoxFit.cover),
                      ),
                    GestureDetector(
                      onTap: productPhotos.length >= 5
                          ? null
                          : () => _pickImageFromGallery(invoice: false),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FACTURA DEL PRODUCTO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _takePhoto(invoice: true),
                  child: Container(
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: glassBorder),
                    ),
                    child: selectedInvoicePhoto == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_outlined,
                                    color: cyan, size: 26),
                                SizedBox(height: 6),
                                Text(
                                  'Toca para tomar foto de la factura',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(selectedInvoicePhoto,
                                width: double.infinity,
                                height: 104,
                                fit: BoxFit.cover),
                          ),
                  ),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _pickImageFromGallery(invoice: true),
                    icon: const Icon(Icons.photo_library_outlined,
                        color: cyan, size: 16),
                    label: const Text(
                      'Seleccionar de galería',
                      style: TextStyle(
                        color: cyan,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESTADO DEL PAGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Pendiente',
                        selected: paymentStatus == 'Pendiente',
                        onTap: () =>
                            setState(() => paymentStatus = 'Pendiente'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Pagado',
                        selected: paymentStatus == 'Pagado',
                        onTap: () => setState(() => paymentStatus = 'Pagado'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'MÉTODO DE PAGO',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 9.5,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Efectivo',
                        icon: Icons.payments_outlined,
                        selected: paymentMethod == 'Efectivo',
                        onTap: () => setState(() => paymentMethod = 'Efectivo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PaymentChoice(
                        label: 'Transferencia',
                        icon: Icons.account_balance_outlined,
                        selected: paymentMethod == 'Transferencia',
                        onTap: () =>
                            setState(() => paymentMethod = 'Transferencia'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Itinerario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 11),
                PlaceAutocompleteField(
                  label: 'Desde',
                  hint: 'Busca un lugar de Managua…',
                  icon: Icons.radio_button_checked,
                  controller: origin,
                  onSelected: (place) => setState(() {
                    originPlace = place;
                  }),
                ),
                const SizedBox(height: 11),
                PlaceAutocompleteField(
                  label: 'Hacia',
                  hint: 'Busca un lugar de Managua…',
                  icon: Icons.location_on_outlined,
                  controller: destination,
                  onSelected: (place) =>
                      setState(() => destinationPlace = place),
                ),
                if (distance != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cyan.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'Ruta aproximada: ${distance.toStringAsFixed(1)} km en línea recta',
                      style: const TextStyle(
                        color: cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Transporte recomendado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: cyan.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: cyan, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'RECOMENDADO: ${_recommended}',
                            style: const TextStyle(
                              color: cyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona el transporte según tu tipo de carga. El precio se calcula con tu origen y destino.',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11,
                    fontFamily: 'Figtree',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final (label, cap, icon, maxKg) in [
                      ('Moto', 'Hasta 20 kg', Icons.two_wheeler, 20),
                      (
                        'Vehículo',
                        'Hasta 300 kg',
                        Icons.directions_car_filled,
                        300
                      ),
                      (
                        'Camión',
                        'Hasta 1,500 kg',
                        Icons.local_shipping_outlined,
                        1500
                      ),
                    ])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _CompactVehicleTile(
                            icon: icon,
                            label: label,
                            capacity: cap,
                            price: _priceFor(label),
                            selected: transport == label,
                            recommended: _recommended == label,
                            blocked: _weightKg > maxKg,
                            onTap: _weightKg > maxKg
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          '$label no soporta $weight $weightUnit. Cambia el peso o usa otro vehículo.',
                                          style: const TextStyle(
                                              fontFamily: 'Figtree'),
                                        ),
                                      ),
                                    );
                                  }
                                : () => setState(() => transport = label),
                          ),
                        ),
                      ),
                  ],
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  _PriceBreakdown(
                    transport: transport,
                    price: price,
                    recommended: _recommended == transport,
                    productValue: _invoiceAmountCs,
                    currency: currency,
                    exchangeRate: settings?.dollarRate ?? 36.5,
                    fareRoundingCs: settings?.fareRoundingCs ?? 5,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Solicitar nuevo envío',
            filled: true,
            textColor: Colors.white,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Confirmarpedido(
                  origin: origin.text.trim(),
                  destination: destination.text.trim(),
                  weight: weight,
                  weightUnit: weightUnit,
                  bundles: bundles,
                  originPlace: originPlace,
                  destinationPlace: destinationPlace,
                  transport: transport,
                  estimatedShipping: price,
                  description: description.text.trim(),
                  fragile: fragile,
                  invoiceNumber: invoiceNumber.text.trim(),
                  invoiceAmount: _invoiceAmountCs,
                  paymentStatus: paymentStatus,
                  paymentMethod: paymentMethod,
                  productPhotos: productPhotos,
                  invoicePhoto: invoicePhoto,
                  originRefs: widget.startOriginRefs,
                  destinationRefs: widget.startDestinationRefs,
                  recipientName: recipient.text.trim(),
                  recipientPhone: phone.text.trim(),
                  serviceType: widget.startScheduled ? 'Programado' : 'Express',
                  scheduledDate: widget.startDate,
                  scheduledTime: widget.startTime,
                  isScheduled: widget.startScheduled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightChip(int value) {
    final converted = weightUnit == 'lb' ? (value * 2.20462).round() : value;
    final active = weight == converted;
    return GestureDetector(
      onTap: () => setState(() => weight = converted),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: active ? figmaBlue : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? cyan : Colors.transparent,
          ),
        ),
        child: Text(
          '$converted $weightUnit',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'Figtree',
          ),
        ),
      ),
    );
  }
}

class _CompactVehicleTile extends StatelessWidget {
  const _CompactVehicleTile({
    required this.icon,
    required this.label,
    required this.capacity,
    required this.price,
    required this.selected,
    required this.recommended,
    required this.blocked,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String capacity;
  final double? price;
  final bool selected;
  final bool recommended;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = price;
    final borderColor = blocked
        ? const Color(0xFFE5484D).withValues(alpha: .45)
        : selected
            ? cyan
            : glassBorder;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 126,
        padding: const EdgeInsets.fromLTRB(9, 9, 8, 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .17)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        ),
        child: Opacity(
          opacity: blocked ? .55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? figmaBlue
                          : Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 17),
                  ),
                  Icon(
                    selected && !blocked
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected && !blocked ? cyan : Colors.white54,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                capacity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 9.5,
                  fontFamily: 'Figtree',
                ),
              ),
              const Spacer(),
              if (recommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: mint.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'RECOMENDADO',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: mint,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                )
              else
                Text(
                  amount == null ? 'C\$ —' : 'C\$${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyChoice extends StatelessWidget {
  const _CurrencyChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          _item('C\$', value == 'C\$'),
          _item('USD', value == 'USD'),
        ],
      ),
    );
  }

  Widget _item(String label, bool selected) {
    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFB9D4FF),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
      ),
    );
  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cyan : Colors.white.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? cyan : glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(height: 3),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleRateTile extends StatelessWidget {
  const _VehicleRateTile({
    required this.icon,
    required this.label,
    required this.capacity,
    required this.subtitle,
    required this.selected,
    required this.recommended,
    required this.onTap,
    this.price,
    this.blocked = false,
    this.blockedNote,
  });

  final IconData icon;
  final String label;
  final String capacity;
  final String subtitle;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;
  final double? price;
  final bool blocked;
  final String? blockedNote;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: .14)
              : Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: blocked
                ? const Color(0xFFE5484D).withValues(alpha: .55)
                : selected
                    ? cyan
                    : glassBorder,
            width: blocked ? 1.4 : 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: blocked ? 0.55 : 1,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? figmaBlue
                          : Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                fontFamily: 'Figtree',
                              ),
                            ),
                            if (recommended) ...[
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: mint.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'RECOMENDADO',
                                  style: TextStyle(
                                    color: mint,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 10,
                            fontFamily: 'Figtree',
                          ),
                        ),
                        Text(
                          'Capacidad: $capacity',
                          style: const TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 10,
                            fontFamily: 'Figtree',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ENVÍO DESDE',
                        style: TextStyle(
                          color: Color(0xFF8FA0C4),
                          fontSize: 8,
                          letterSpacing: .6,
                          fontFamily: 'Figtree',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price == null
                            ? 'C\$ —'
                            : 'C\$${price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 9),
                  Icon(
                    selected && !blocked
                        ? Icons.radio_button_checked
                        : blocked
                            ? Icons.not_interested_rounded
                            : Icons.radio_button_unchecked,
                    color: blocked
                        ? const Color(0xFFE5484D)
                        : selected
                            ? cyan
                            : Colors.white38,
                    size: 21,
                  ),
                ],
              ),
            ),
            if (blockedNote != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                child: Text(
                  blockedNote!,
                  style: const TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.transport,
    required this.price,
    required this.recommended,
    required this.productValue,
    required this.currency,
    required this.exchangeRate,
    required this.fareRoundingCs,
  });

  final String transport;
  final double price;
  final bool recommended;
  final double productValue;
  final String currency;
  final double exchangeRate;
  final double fareRoundingCs;

  String _money(double valueCs) {
    final value = currency == 'USD'
        ? valueCs / exchangeRate
        : roundFareCs(valueCs, fareRoundingCs);
    final symbol = currency == 'USD' ? 'USD' : 'C\$';
    return '$symbol ${value.toStringAsFixed(currency == 'USD' ? 2 : 0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
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
                  'TOTAL A COBRAR AL DESTINATARIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mint.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transport,
                  style: const TextStyle(
                    color: mint,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _money(price),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 6),
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: mint, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'Tarifa calculada al instante',
                    style: TextStyle(
                      color: mint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                'Tarifa calculada con el transporte seleccionado',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 10.5,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: glassBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tarifa base de envío',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Text(
                'Incluida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Costo por kilómetro de la ruta',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Text(
                'Incluido',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
          SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '+ Paquete del cliente (valor)',
                  style: TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 11.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Text(
                _money(productValue),
                style: TextStyle(
                  color: mint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: glassBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Envío ${_money(price * 0.20)}',
                  style: const TextStyle(
                    color: Color(0xFF8FA0C4),
                    fontSize: 10.5,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Total a pagar por el cliente\n${_money(price + productValue)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Figtree',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
