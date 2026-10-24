import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/place_history.dart';
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
  State<SeleccionarPuntosEnvio> createState() => _SeleccionarPuntosEnvioState();
}

class _SeleccionarPuntosEnvioState extends State<SeleccionarPuntosEnvio> {
  late final TextEditingController origin;
  late final TextEditingController destination;
  late final FocusNode destinationFocusNode;
  late PlaceSuggestion? originPlace;
  late PlaceSuggestion? destinationPlace;
  PlaceHistory _placeHistory = PlaceHistory();
  late final String _profileKey;
  bool _showDestinationHistory = false;

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
    _profileKey = placeHistoryProfileKey(apiClient.currentUser);
    destinationFocusNode = FocusNode()..addListener(_onDestinationFocusChanged);
    originPlace = widget.startOriginPlace ?? _defaultOrigin;
    destinationPlace = widget.startDestinationPlace;
    origin = TextEditingController(
      text: widget.startOrigin.trim().isEmpty
          ? originPlace?.description ?? ''
          : widget.startOrigin,
    );
    destination = TextEditingController(text: widget.startDestination);
    destination.addListener(_onDestinationTextChanged);
    unawaited(_loadPlaceHistory());
  }

  Future<void> _loadPlaceHistory() async {
    final history = await PlaceHistoryStore.load(_profileKey);
    if (!mounted) return;
    setState(() => _placeHistory = history);
  }

  void _onDestinationFocusChanged() {
    _updateDestinationHistoryVisibility();
  }

  void _onDestinationTextChanged() {
    _updateDestinationHistoryVisibility();
  }

  void _updateDestinationHistoryVisibility() {
    final shouldShow = shouldShowPlaceHistory(
      hasFocus: destinationFocusNode.hasFocus,
      query: destination.text,
    );
    if (!mounted || _showDestinationHistory == shouldShow) {
      return;
    }
    setState(() => _showDestinationHistory = shouldShow);
  }

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    destinationFocusNode.dispose();
    super.dispose();
  }

  void _setOrigin(PlaceSuggestion place) {
    _rememberPlace(place);
    setState(() {
      originPlace = place;
      origin.text = place.description;
    });
  }

  void _setDestination(PlaceSuggestion place) {
    _rememberPlace(place);
    setState(() {
      destinationPlace = place;
      destination.text = place.description;
    });
  }

  void _rememberPlace(PlaceSuggestion place) {
    _placeHistory.remember(place);
    unawaited(PlaceHistoryStore.save(_profileKey, _placeHistory));
  }

  void _toggleDestinationFavorite() {
    final place = destinationPlace;
    if (place == null) return;
    _placeHistory.remember(place);
    _placeHistory.toggleFavorite(place.placeId);
    unawaited(PlaceHistoryStore.save(_profileKey, _placeHistory));
    setState(() {});
  }

  void _toggleSavedFavorite(SavedPlace place) {
    _placeHistory.toggleFavorite(place.placeId);
    unawaited(PlaceHistoryStore.save(_profileKey, _placeHistory));
    setState(() {});
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
                  Text(
                    widget.selectionOnly ? 'Regresar al mapa' : 'Regresar',
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
                destinationFocusNode: destinationFocusNode,
                destinationPlace: destinationPlace,
                destinationFavorite: destinationPlace != null &&
                    _placeHistory.favorites.any(
                      (item) => item.placeId == destinationPlace!.placeId,
                    ),
                onOriginSelected: _setOrigin,
                onDestinationSelected: _setDestination,
                onToggleDestinationFavorite: _toggleDestinationFavorite,
                onMap: _continue,
                selectionOnly: widget.selectionOnly,
              ),
              const SizedBox(height: 9),
              if (_showDestinationHistory) ...[
                _SavedPlacesPanel(
                  history: _placeHistory,
                  onSelect: (place) => _setDestination(place.toSuggestion()),
                  onToggleFavorite: _toggleSavedFavorite,
                ),
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
    required this.destinationFocusNode,
    required this.destinationPlace,
    required this.destinationFavorite,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onToggleDestinationFavorite,
    required this.onMap,
    required this.selectionOnly,
  });

  final TextEditingController origin;
  final TextEditingController destination;
  final FocusNode destinationFocusNode;
  final PlaceSuggestion? destinationPlace;
  final bool destinationFavorite;
  final ValueChanged<PlaceSuggestion> onOriginSelected;
  final ValueChanged<PlaceSuggestion> onDestinationSelected;
  final VoidCallback onToggleDestinationFavorite;
  final VoidCallback onMap;
  final bool selectionOnly;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      borderRadius: 22,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
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
                    focusNode: destinationFocusNode,
                    label: 'Destino',
                    hint: '¿A dónde va tu pedido?',
                    bare: true,
                    onSelected: onDestinationSelected,
                  ),
                ),
                const SizedBox(width: 6),
                _FavoritePlaceButton(
                  active: destinationFavorite,
                  enabled: destinationPlace != null,
                  onPressed: onToggleDestinationFavorite,
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: destination.text.trim().isEmpty ? null : onMap,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: accentBlue,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: .10),
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
      ),
    );
  }
}

class _SavedPlacesPanel extends StatelessWidget {
  const _SavedPlacesPanel({
    required this.history,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  final PlaceHistory history;
  final ValueChanged<SavedPlace> onSelect;
  final ValueChanged<SavedPlace> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final favorites = history.favorites;
    final recent = history.recent;
    if (favorites.isEmpty && recent.isEmpty) {
      return AppGlassSurface(
        borderRadius: 16,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            'Tus direcciones seleccionadas aparecerán aquí.',
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 11,
              fontFamily: 'Figtree',
            ),
          ),
        ),
      );
    }

    return AppGlassSurface(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LUGARES GUARDADOS',
              style: TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                fontFamily: 'Figtree',
              ),
            ),
            if (favorites.isNotEmpty) ...[
              const SizedBox(height: 7),
              const _SavedPlacesSectionTitle(
                icon: Icons.star_rounded,
                label: 'Favoritos',
              ),
              for (final place in favorites)
                _SavedPlaceRow(
                  place: place,
                  icon: Icons.star_rounded,
                  onTap: () => onSelect(place),
                  onToggleFavorite: () => onToggleFavorite(place),
                ),
            ],
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 7),
              const _SavedPlacesSectionTitle(
                icon: Icons.history_rounded,
                label: 'Recientes',
              ),
              for (final place in recent)
                _SavedPlaceRow(
                  place: place,
                  icon: Icons.history_rounded,
                  onTap: () => onSelect(place),
                  onToggleFavorite: () => onToggleFavorite(place),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedPlacesSectionTitle extends StatelessWidget {
  const _SavedPlacesSectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: .82), size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'Figtree',
          ),
        ),
      ],
    );
  }
}

class _SavedPlaceRow extends StatelessWidget {
  const _SavedPlaceRow({
    required this.place,
    required this.icon,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final SavedPlace place;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: .70), size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.main.isEmpty ? place.address : place.main,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                  if (place.secondary.isNotEmpty)
                    Text(
                      place.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 10.5,
                        fontFamily: 'Figtree',
                      ),
                    ),
                ],
              ),
            ),
            _FavoritePlaceButton(
              active: place.isFavorite,
              enabled: true,
              onPressed: onToggleFavorite,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePlaceButton extends StatelessWidget {
  const _FavoritePlaceButton({
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: active ? 'Quitar de favoritos' : 'Guardar en favoritos',
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? accentBlue.withValues(alpha: .24)
              : Colors.white.withValues(alpha: .08),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accentBlue.withValues(alpha: .42),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          active ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: enabled
              ? (active
                  ? const Color(0xFF58A6FF)
                  : Colors.white.withValues(alpha: .82))
              : Colors.white.withValues(alpha: .25),
        ),
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
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
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
