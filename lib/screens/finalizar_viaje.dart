import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

class FinalizarViaje extends StatefulWidget {
  const FinalizarViaje({super.key, required this.trip});

  final Trip trip;

  @override
  State<FinalizarViaje> createState() => _FinalizarViajeState();
}

class _FinalizarViajeState extends State<FinalizarViaje> {
  int stars = 0;
  Uint8List? evidencePhoto;
  bool uploadingEvidence = false;

  Future<void> _pickEvidencePhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        evidencePhoto = bytes;
        uploadingEvidence = true;
      });

      await apiClient.uploadEvidence(
        bytes,
        image.name.trim().isEmpty ? 'evidencia-entrega.jpg' : image.name,
      );
      if (mounted) setState(() => uploadingEvidence = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => uploadingEvidence = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'No se pudo subir la evidencia.',
            style: TextStyle(fontFamily: 'Figtree'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final isTaxi = trip.serviceMode == 'Taxi Privado';

    return Scaffold(
      body: AppBackground(
        darken: 0,
        child: Stack(
          children: [
            // CAPA 1: La mascota gigante en el fondo (detrás de las tarjetas)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/img/mascotaEntrega.png',
                  width: 560,
                  height: 560,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // CAPA 2: Cuadro de información único sobrepuesto sobre la mascota
            Positioned.fill(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 300, 18, 80),
                  children: [
                    AppGlassSurface(
                      borderRadius: 24,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          // Check Verde
                          const _DeliveryCheck(),
                          const SizedBox(height: 16),

                          // Título
                          Text(
                            isTaxi
                                ? '¡Viaje terminado!'
                                : '¡Paquete entregado!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtítulo
                          Text(
                            isTaxi
                                ? 'Tu pasajero ha llegado a su destino de forma segura y puntual.'
                                : 'Tu paquete ha llegado a su destino con éxito.\nGracias por usar INCOEX.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              height: 1.3,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 18),

                          // Destino Final
                          Text(
                            'Destino final',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trip.destination,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Figtree',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Pill con Icono de Reloj y Hora
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 14,
                                  color: Colors.white24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTaxi
                                      ? 'Viaje hecho hoy, 14:30 hrs'
                                      : 'Entregado hoy, 14:30 hrs',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Figtree',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Evidencia
                          InkWell(
                            onTap: _pickEvidencePhoto,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              child: Text(
                                isTaxi
                                    ? 'Evidencia de viaje'
                                    : 'Evidencia de entrega',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  fontFamily: 'Figtree',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Caja Interna de Calificación
                          AppGlassSurface(
                            borderRadius: 16,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '¿Cómo fue tu experiencia?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Figtree',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (var i = 1; i <= 5; i++)
                                        IconButton(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          constraints: const BoxConstraints(),
                                          onPressed: () =>
                                              setState(() => stars = i),
                                          icon: Icon(
                                            i <= stars
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color: i <= stars
                                                ? Colors.white
                                                : Colors.white38,
                                            size: 32,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CAPA 3: Botón inferior "Regresar al inicio"
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text(
                    'Regresar al inicio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCheck extends StatelessWidget {
  const _DeliveryCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF00D656),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x6600D656),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
    );
  }
}
