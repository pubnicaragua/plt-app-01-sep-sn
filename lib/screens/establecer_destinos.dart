import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';

/// Editor completo de paradas adicionales. Las paradas se seleccionan con
/// autocomplete para conservar coordenadas y permitir que Maps calcule la
/// ruta real, en lugar de guardar únicamente texto libre.
class EstablecerDestinos extends StatefulWidget {
  const EstablecerDestinos({
    super.key,
    required this.origin,
    required this.destination,
    this.initialStops = const [],
  });

  final String origin;
  final String destination;
  final List<TripStop> initialStops;

  @override
  State<EstablecerDestinos> createState() => _EstablecerDestinosState();
}

class _EstablecerDestinosState extends State<EstablecerDestinos> {
  late final TextEditingController stopController;
  late final List<TripStop> stops;
  PlaceSuggestion? selectedPlace;

  @override
  void initState() {
    super.initState();
    stopController = TextEditingController();
    stops = List<TripStop>.of(widget.initialStops);
  }

  @override
  void dispose() {
    stopController.dispose();
    super.dispose();
  }

  void _addStop() {
    final place = selectedPlace;
    if (place == null || stopController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un destino de las sugerencias.')),
      );
      return;
    }
    setState(() {
      stops.add(
        TripStop(
          label: String.fromCharCode('B'.codeUnitAt(0) + stops.length),
          address: place.description,
          latitude: place.latitude,
          longitude: place.longitude,
          order: stops.length + 1,
        ),
      );
      selectedPlace = null;
      stopController.clear();
    });
  }

  void _removeStop(int index) {
    setState(() {
      stops.removeAt(index);
      for (var i = 0; i < stops.length; i++) {
        final previous = stops[i];
        stops[i] = TripStop(
          id: previous.id,
          label: String.fromCharCode('B'.codeUnitAt(0) + i),
          address: previous.address,
          latitude: previous.latitude,
          longitude: previous.longitude,
          refs: previous.refs,
          order: i + 1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        darken: .04,
        backgroundLogoOpacity: .48,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _BackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Establecer varios destinos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    _RouteCard(
                      label: 'A',
                      title: 'Origen',
                      address: widget.origin,
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < stops.length; i++) ...[
                      _StopCard(
                        stop: stops[i],
                        onRemove: () => _removeStop(i),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _RouteCard(
                      label: String.fromCharCode('B'.codeUnitAt(0) + stops.length),
                      title: 'Destino final',
                      address: widget.destination,
                      icon: Icons.flag_rounded,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Agregar una ruta adicional',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree',
                      ),
                    ),
                    const SizedBox(height: 8),
                    PlaceAutocompleteField(
                      controller: stopController,
                      label: 'Nueva parada',
                      hint: 'Busca una dirección o lugar',
                      icon: Icons.add_location_alt_outlined,
                      onSelected: (place) => setState(() {
                        selectedPlace = place;
                        stopController.text = place.description;
                      }),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 43,
                      child: OutlinedButton.icon(
                        onPressed: _addStop,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Agregar ruta adicional'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: .30)),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: SizedBox(
          height: 45,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(List<TripStop>.of(stops)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Confirmar destinos',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.label, required this.title, required this.address, required this.icon});

  final String label;
  final String title;
  final String address;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: label == 'A' ? Colors.white.withValues(alpha: .12) : accentBlue,
              shape: BoxShape.circle,
            ),
            child: label == 'A'
                ? Icon(icon, color: Colors.white, size: 17)
                : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Figtree')),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Figtree')),
                const SizedBox(height: 3),
                Text(address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Figtree')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop, required this.onRemove});

  final TripStop stop;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .22)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: accentBlue, shape: BoxShape.circle),
                child: Text(stop.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Figtree')),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(stop.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Figtree'))),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20), tooltip: 'Eliminar'),
            ],
          ),
        ),
      ),
    );
  }
}
