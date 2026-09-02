import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart' show BrandLockup;
import 'inicio.dart';
import 'onboarding_entrega.dart';
import 'onboarding_recoleccion.dart' show HeroCopy;

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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 20),
                const BrandLockup(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FractionallySizedBox(
                          heightFactor: .92,
                          widthFactor: 1,
                          child: Image.asset(
                            'assets/img/imagen_pantalla2.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [.55, .85],
                                colors: [
                                  Colors.transparent,
                                  Color(0xCC0B1B4D),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
