import 'package:flutter/material.dart';

import 'dart:typed_data';

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
            style: TextStyle(fontFamily: 'Acumin Pro'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const logoScale = 1.04;
    final logoOffsetX = screenWidth > 390
        ? -((screenWidth - 390 * logoScale) / 2)
        : 0.0;
    return Scaffold(
      body: AppBackground(
        darken: 0,
        backgroundLogoOpacity: 1,
        backgroundLogoOffsetX: logoOffsetX,
        backgroundLogoOffsetY: 30,
        backgroundLogoScale: logoScale,
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(17, 34, 17, 78),
            children: [
              const Center(
                child: _DeliveryCheck(),
              ),
              const SizedBox(height: 10),
              const Text(
                '¡Paquete entregado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Tu paquete ha llegado a su destino de forma segura y puntual.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 11,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 13),
              GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/img/PantallaSeguimiento/location.png',
                        width: 17,
                        height: 17,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Destino final',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      trip.destination,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/img/PantallaSeguimiento/reloj.png',
                            width: 15,
                            height: 15,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          const Text('Entregado hoy, 14:30 hrs',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Acumin Pro')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    const Divider(height: 1, color: Color(0x55FFFFFF)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickEvidencePhoto,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 1),
                        child: Center(
                          child: Text(
                            'Evidencia de entrega',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0x55FFFFFF)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: glassBorder),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '¿Cómo fue tu experiencia?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 1; i <= 5; i++)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  onPressed: () => setState(() => stars = i),
                                  icon: Opacity(
                                    opacity: i <= stars ? 1 : .3,
                                    child: Image.asset(
                                      'assets/img/PantallaSeguimiento/calificacion.png',
                                      width: 23,
                                      height: 23,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: SizedBox(
                height: 34,
                child: Material(
                  color: accentBlue,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    child: const Center(
                      child: Text(
                        'Regresar al inicio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
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
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0x7A00FF37),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
    );
  }
}
