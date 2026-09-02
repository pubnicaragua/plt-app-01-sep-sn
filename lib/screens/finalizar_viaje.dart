import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'resumen_cliente.dart';

class FinalizarViaje extends StatefulWidget {
  const FinalizarViaje({super.key, required this.trip});

  final Trip trip;

  @override
  State<FinalizarViaje> createState() => _FinalizarViajeState();
}

class _FinalizarViajeState extends State<FinalizarViaje> {
  int stars = 0;
  bool evidencia = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Entrega completada',
          style: TextStyle(
            fontFamily: 'Acumin Pro',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 74, 22, 28),
            children: [
              const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: mint,
                  size: 76,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '¡Paquete entregado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'El conductor confirmó la entrega.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 12.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINO FINAL',
                      style: TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      trip.destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Entregado hoy, 14:30 hrs',
                      style: TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 11.5,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const Divider(height: 25, color: Color(0x22FFFFFF)),
                    const Text(
                      'EVIDENCIA DE ENTREGA',
                      style: TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => setState(() => evidencia = !evidencia),
                      child: Container(
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(15),
                          border: evidencia
                              ? Border.all(color: mint, width: 1.3)
                              : Border.all(color: glassBorder),
                        ),
                        child: Center(
                          child: toolIcon(
                            evidencia
                                ? Icons.check_rounded
                                : Icons.add_a_photo_outlined,
                            count: 96,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evidencia ? 'Evidencia adjunta.' : 'Foto del paquete recibido.',
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10.5,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '¿Cómo fue tu experiencia?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => stars = i),
                      icon: Icon(
                        i <= stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFC64D),
                        size: 34,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              GlassButton(
                label: 'Finalizar y ver resumen',
                filled: true,
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ResumenCliente(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget toolIcon(IconData icon, {double count = 0}) {
    return Icon(icon, color: mint, size: 28);
  }
}
