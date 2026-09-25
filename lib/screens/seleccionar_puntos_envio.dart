import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';

class RouteSelectionResult {
  const RouteSelectionResult({
    required this.origin,
    required this.destination,
    required this.originPlace,
    required this.destinationPlace,
  });

  final String origin;
  final String destination;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
}

class SeleccionarPuntosEnvio extends StatefulWidget {
  const SeleccionarPuntosEnvio({
    super.key,
    this.startOrigin = '',
    this.startDestination = '',
    this.startOriginPlace,
    this.startDestinationPlace,
    this.startTransport = 'Moto',
    this.selectionOnly = false,
    this.onOpenMap,
  });

  final String startOrigin;
  final String startDestination;
  final PlaceSuggestion? startOriginPlace;
  final PlaceSuggestion? startDestinationPlace;
  final String startTransport;
  final bool selectionOnly;
  final Future<RouteSelectionResult?> Function(RouteSelectionResult result)?
      onOpenMap;

  @override
  State<SeleccionarPuntosEnvio> createState() =>
      _SeleccionarPuntosEnvioState();
}

class _SeleccionarPuntosEnvioState extends State<SeleccionarPuntosEnvio> {
  late final TextEditingController origin;
  late final TextEditingController destination;
  late PlaceSuggestion? originPlace;
  late PlaceSuggestion? destinationPlace;

  static const _defaultOrigin = PlaceSuggestion(
    placeId: 'incoex-edificio-pellas',
    description: 'Oficinas Incoex, Edificio Pellas',
    main: 'Oficinas Incoex, Edificio Pellas',
    secondary: 'Managua, Nicaragua',
    latitude: 12.1026,
    longitude: -86.2632,
  );

  static const _recommended = [
    _RecommendedPlace(
      place: PlaceSuggestion(
        placeId: 'hospital-vivian-pellas',
        description: 'Hospital Metropolitano Vivian Pellas, Managua',
        main: 'Hospital Metropolitano Vivian Pellas',
        secondary: 'Carretera a Masaya, Managua',
        latitude: 12.0968,
        longitude: -86.2558,
      ),
    ),
    _RecommendedPlace(
      place: PlaceSuggestion(
        placeId: 'galerias-santo-domingo',
        description: 'Galerías Santo Domingo, Managua',
        main: 'Galerías Santo Domingo',
        secondary: 'Carretera a Masaya, Managua',
        latitude: 12.0838,
        longitude: -86.2394,
      ),
    ),
    _RecommendedPlace(
      place: PlaceSuggestion(
        placeId: 'hospital-militar-managua',
        description: 'Hospital Militar Escuela Dr. Alejandro Dávila Bolaños',
        main: 'Hospital Militar Escuela Dr. Alejandro Dávila Bolaños',
        secondary: 'Managua, Nicaragua',
        latitude: 12.1245,
        longitude: -86.2675,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    originPlace = widget.startOriginPlace ?? _defaultOrigin;
    destinationPlace = widget.startDestinationPlace;
    origin = TextEditingController(
      text: widget.startOrigin.trim().isEmpty
          ? originPlace?.description ?? ''
          : widget.startOrigin,
    );
    destination = TextEditingController(text: widget.startDestination);
  }

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    super.dispose();
  }

  void _setOrigin(PlaceSuggestion place) {
    setState(() {
      originPlace = place;
      origin.text = place.description;
    });
  }

  void _setDestination(PlaceSuggestion place) {
    setState(() {
      destinationPlace = place;
      destination.text = place.description;
    });
  }

  RouteSelectionResult get _result => RouteSelectionResult(
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        originPlace: originPlace,
        destinationPlace: destinationPlace,
      );

  Future<void> _continue() async {
    if (originPlace == null || destinationPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un punto de recogida y uno de entrega.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final result = _result;
    if (widget.selectionOnly) {
      Navigator.of(context).pop(result);
      return;
    }
    final updated = await widget.onOpenMap?.call(result);
    if (!mounted || updated == null) return;
    setState(() {
      origin.text = updated.origin;
      destination.text = updated.destination;
      originPlace = updated.originPlace;
      destinationPlace = updated.destinationPlace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width < 380 ? 14.0 : 16.0;
    return Scaffold(
      backgroundColor: const Color(0xFF082B66),
      body: AppBackground(
        backgroundLogoOpacity: .16,
        backgroundLogoOffsetY: 100,
        backgroundLogoScale: 1.08,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Regresar al inicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _RouteSelectionCard(
                origin: origin,
                destination: destination,
                onOriginSelected: _setOrigin,
                onDestinationSelected: _setDestination,
                onMap: _continue,
                selectionOnly: widget.selectionOnly,
              ),
              const SizedBox(height: 9),
              for (var index = 0; index < _recommended.length; index++) ...[
                _RecommendedPlaceCard(
                  item: _recommended[index],
                  selected: destinationPlace?.placeId ==
                      _recommended[index].place.placeId,
                  onTap: () => _setDestination(_recommended[index].place),
                ),
                if (index != _recommended.length - 1)
                  const SizedBox(height: 2),
              ],
              if (widget.selectionOnly) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 43,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Guardar puntos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSelectionCard extends StatelessWidget {
  const _RouteSelectionCard({
    required this.origin,
    required this.destination,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onMap,
    required this.selectionOnly,
  });

  final TextEditingController origin;
  final TextEditingController destination;
  final ValueChanged<PlaceSuggestion> onOriginSelected;
  final ValueChanged<PlaceSuggestion> onDestinationSelected;
  final VoidCallback onMap;
  final bool selectionOnly;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
      color: Colors.white.withValues(alpha: .08),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PointIcon(asset: 'assets/img/HomeCliente/punto_desde.png'),
              const SizedBox(width: 9),
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
            margin: const EdgeInsets.only(left: 31, top: 2, bottom: 2),
            color: Colors.white.withValues(alpha: .28),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PointIcon(asset: 'assets/img/HomeCliente/punto_hasta.png'),
              const SizedBox(width: 9),
              Expanded(
                child: PlaceAutocompleteField(
                  controller: destination,
                  label: 'Destino',
                  hint: '¿A dónde va tu pedido?',
                  bare: true,
                  onSelected: onDestinationSelected,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: destination.text.trim().isEmpty ? null : onMap,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: accentBlue,
                    disabledBackgroundColor: Colors.white.withValues(alpha: .10),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    minimumSize: const Size(58, 30),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    selectionOnly ? 'Mapa' : 'Mapa',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Figtree',
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
}

class _PointIcon extends StatelessWidget {
  const _PointIcon({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Image.asset(
        asset,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.place_outlined,
          color: Colors.white,
          size: 19,
        ),
      ),
    );
  }
}

class _RecommendedPlace {
  const _RecommendedPlace({required this.place});

  final PlaceSuggestion place;
}

class _RecommendedPlaceCard extends StatelessWidget {
  const _RecommendedPlaceCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _RecommendedPlace item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: selected ? cyan : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.place.main,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    Text(
                      item.place.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 9.5,
                        fontFamily: 'Figtree',
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: cyan, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
