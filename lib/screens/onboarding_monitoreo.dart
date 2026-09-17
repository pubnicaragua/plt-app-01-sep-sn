import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart' show BrandLockup;
import 'inicio.dart';
import 'onboarding_entrega.dart';
import 'onboarding_recoleccion.dart' show HeroCopy, OnboardingVisual;

class OnboardingMonitoreo extends StatefulWidget {
  const OnboardingMonitoreo({super.key});

  @override
  State<OnboardingMonitoreo> createState() => _OnboardingMonitoreoState();
}

class _OnboardingMonitoreoState extends State<OnboardingMonitoreo> {
  static const titulo =
      'Monitorea cada pedido en tiempo real y\nrecibe asistencia profesional cuando lo\nnecesites.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              children: [
                FractionallySizedBox(
                  widthFactor: .9,
                  child: Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 5,
                          margin: EdgeInsets.only(
                            right: index == 2 ? 0 : 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: index <= 1
                                ? Colors.white
                                : Colors.white.withValues(alpha: .18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const BrandLockup(),
                const Expanded(
                  child: OnboardingVisual(
                    asset: 'assets/img/imagen_pantalla2.png',
                  ),
                ),
                HeroCopy(
                  title: titulo,
                  onNext: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingEntrega(),
                    ),
                  ),
                  onSkip: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Inicio()),
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
