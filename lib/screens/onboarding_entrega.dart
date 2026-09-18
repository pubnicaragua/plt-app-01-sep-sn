import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart' show BrandLockup;
import 'inicio.dart';
import 'onboarding_recoleccion.dart' show HeroCopy;

class OnboardingEntrega extends StatefulWidget {
  const OnboardingEntrega({super.key});

  @override
  State<OnboardingEntrega> createState() => _OnboardingEntregaState();
}

class _OnboardingEntregaState extends State<OnboardingEntrega> {
  static const titulo =
      'Disfruta de entregas express sin\ncomplicaciones y llega a cualquier lugar\ncon la máxima eficiencia.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                            color: index == 2
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
                  child: _DeliveryVisual(),
                ),
                HeroCopy(
                  title: titulo,
                  onNext: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Inicio()),
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

class _DeliveryVisual extends StatelessWidget {
  const _DeliveryVisual();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxWidth * 1.55;
        final fullWidth = constraints.maxWidth + 40;

        return OverflowBox(
          alignment: Alignment.center,
          minWidth: fullWidth,
          maxWidth: fullWidth,
          child: SizedBox(
            width: fullWidth,
            height: constraints.maxHeight,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: constraints.maxHeight * .16,
                  left:
                      (fullWidth - imageSize) / 2 + constraints.maxWidth * .055,
                  width: imageSize,
                  height: imageSize,
                  child: Transform.rotate(
                    angle: -.43,
                    child: Image.asset(
                      'assets/img/imagen_pantalla3.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [.68, .98],
                        colors: [
                          Colors.transparent,
                          Color(0x1A0B1B4D),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
