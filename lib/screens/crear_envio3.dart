import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/wizard.dart';
import 'seguimiento_pedido.dart';

class CrearEnvio3 extends StatefulWidget {
  const CrearEnvio3({
    super.key,
    required this.origin,
    required this.destination,
    required this.weight,
    required this.bundles,
    this.originPlace,
    this.destinationPlace,
    this.transport = 'Vehículo',
    this.originRefs = '',
    this.destinationRefs = '',
    this.recipientName = '',
    this.recipientPhone = '',
  });

  final String origin;
  final String destination;
  final int weight;
  final int bundles;
  final PlaceSuggestion? originPlace;
  final PlaceSuggestion? destinationPlace;
  final String transport;
  final String originRefs;
  final String destinationRefs;
  final String recipientName;
  final String recipientPhone;

  @override
  State<CrearEnvio3> createState() => _CrearEnvio3State();
}

class _CrearEnvio3State extends State<CrearEnvio3> {
  static const estados = [
    'Buscando conductor...',
    'Conductor encontrado',
    'Asignando conductor...',
  ];

  int estado = 0;
  int seconds = 0;
  bool failed = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _begin() {
    setState(() {
      estado = 0;
      seconds = 0;
      failed = false;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        seconds += 1;
        if (seconds <= 4) {
          estado = 0;
        } else if (seconds <= 7) {
          estado = 1;
        } else {
          estado = 2;
        }
      });
    });
    _create();
  }

  Future<void> _create() async {
    try {
      final originPlace = widget.originPlace;
      final destinationPlace = widget.destinationPlace;
      final created = await apiClient.createTrip(
        client: apiClient.currentUser?.displayName ?? 'Empresa INCOEX',
        origin: widget.origin,
        destination: widget.destination,
        packages: widget.bundles,
        description:
            'Peso ${widget.weight}kg, ${widget.bundles} bulto(s)',
        originLat: originPlace?.latitude,
        originLng: originPlace?.longitude,
        destinationLat: destinationPlace?.latitude,
        destinationLng: destinationPlace?.longitude,
        distanceKm: distanceKm(
          originPlace,
          destinationPlace,
        ),
        transport: widget.transport,
        autoAssign: true,
        originRefs: widget.originRefs.isEmpty ? null : widget.originRefs,
        destinationRefs: widget.destinationRefs.isEmpty ? null : widget.destinationRefs,
        recipientName: widget.recipientName.isEmpty ? null : widget.recipientName,
        recipientPhone: widget.recipientPhone.isEmpty ? null : widget.recipientPhone,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SeguimientoPedido(trip: created),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => failed = true);
      timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WizardScaffold(
      title: 'Asignando conductor',
      subtitle: failed
          ? 'No pudimos crear el pedido'
          : estados[estado],
      description: failed
          ? 'La API respondió con error. Verifica la conexión y reintenta.'
          : 'Estamos buscando un conductor disponible cerca de ti.\nEsto puede tardar unos segundos...',
      step: 2,
      onClose: () => Navigator.of(context).pop(),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Image.asset(
              'assets/img/EstadosCrearEnvio/crearenvio.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            failed ? 'No pudimos crear el pedido' : estados[estado],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            failed
                ? 'La API no respondió. Revisa tu conexión.'
                : 'Estamos buscando un conductor disponible\ncerca de ti. Esto puede tardar unos segundos...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 12,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 210,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: failed ? 1 : (estado + 1) / 3,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: .18),
                color: cyan,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${seconds}s',
            style: const TextStyle(
              color: Color(0xFF8FA0C4),
              fontSize: 10.5,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 30),
          if (failed)
            GlassButton(
              label: 'Reintentar búsqueda',
              filled: true,
              textColor: Colors.white,
              onPressed: _begin,
            )
          else
            GlassButton(
              label: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(),
              width: 220,
            ),
        ],
      ),
    );
  }
}
