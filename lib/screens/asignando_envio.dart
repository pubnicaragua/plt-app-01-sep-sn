import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/sprite_truck_animation.dart';
import 'envio_asignado.dart';

class AsignandoEnvioScreen extends StatefulWidget {
  const AsignandoEnvioScreen({
    super.key,
    required this.tripId,
    required this.initialTrip,
    required this.isScheduled,
  });

  final String tripId;
  final Trip initialTrip;
  final bool isScheduled;

  @override
  State<AsignandoEnvioScreen> createState() => _AsignandoEnvioScreenState();
}

class _AsignandoEnvioScreenState extends State<AsignandoEnvioScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController characterAnimation;
  Timer? _pollTimer;
  Trip? _latestTrip;
  bool loading = true;
  bool navigating = false;
  String? error;

  @override
  void initState() {
    super.initState();
    characterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _latestTrip = widget.initialTrip;
    if (widget.initialTrip.status == 'Asignado') {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showAssigned(widget.initialTrip));
    } else {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    setState(() {
      loading = true;
      error = null;
    });
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || navigating) return;
    try {
      final trip = await apiClient.getTrip(widget.tripId);
      if (!mounted || navigating) return;
      _latestTrip = trip;
      if (trip.status == 'Asignado') {
        _pollTimer?.cancel();
        _showAssigned(trip);
      } else {
        setState(() {
          loading = false;
          error = null;
        });
      }
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = failure is ApiException
            ? failure.message
            : 'No se pudo consultar la asignación.';
      });
    }
  }

  void _showAssigned(Trip trip) {
    if (!mounted || navigating) return;
    navigating = true;
    _pollTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => EnvioAsignadoScreen(trip: trip)),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    characterAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _latestTrip ?? widget.initialTrip;
    final isCargoFlow = trip.transport == 'Camión';
    return Scaffold(
      backgroundColor: navy,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 28,
                      child: Image.asset('assets/brand/incoex-logo.png',
                          fit: BoxFit.contain, alignment: Alignment.centerLeft),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 27,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .28)),
                        ),
                        child: const Center(
                          child: Text('× Cancelar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Figtree')),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imageHeight = (constraints.maxHeight * .50)
                          .clamp(230.0, 330.0)
                          .toDouble();
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: isCargoFlow
                                ? const SpriteTruckAnimation(
                                    asset:
                                        'assets/img/EstadosCrearEnvio/camion_asignacion_sprite.png',
                                  )
                                : AnimatedBuilder(
                                    animation: characterAnimation,
                                    builder: (context, child) {
                                      final value = characterAnimation.value;
                                      return Transform.translate(
                                        offset: Offset(0, -5 * value),
                                        child: Transform.scale(
                                          scale: .98 + value * .02,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/img/EstadosCrearEnvio/crearenvio.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.local_shipping_rounded,
                                          color: Colors.white70,
                                          size: 100),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: .25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (error == null)
                                  const SizedBox(
                                    width: 11,
                                    height: 11,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5, color: Colors.white),
                                  ),
                                if (error == null) const SizedBox(width: 5),
                                Text(
                                    error == null
                                        ? 'Buscando conductor...'
                                        : 'No se pudo consultar',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Figtree')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            error == null
                                ? 'Asignando conductor'
                                : 'No se pudo asignar',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Figtree'),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            error == null
                                ? 'Estamos buscando un conductor disponible\ncerca de ti.'
                                : error!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFE1E8FF),
                                fontSize: 9.5,
                                height: 1.25,
                                fontFamily: 'Figtree'),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: error == null ? null : 1,
                                minHeight: 4,
                                backgroundColor: Colors.white,
                                color: accentBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isScheduled
                                ? 'Tu envío quedará listo para la fecha programada.'
                                : 'Esto puede tardar unos segundos...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFFD4DCFA),
                                fontSize: 8.5,
                                fontFamily: 'Figtree'),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 17),
                            GlassButton(
                              label: 'Reintentar búsqueda',
                              filled: true,
                              height: 38,
                              onPressed: _startPolling,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Text('Solicitud #${trip.id}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 8.5,
                        fontFamily: 'Figtree')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
