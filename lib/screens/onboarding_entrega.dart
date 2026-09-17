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

/// Composition used only by the delivery onboarding screen. Its artwork is
/// taller and slightly wider than the viewport so the complete flying pose is
/// visible while the lower part fades into the background.
class _DeliveryVisual extends StatelessWidget {
  const _DeliveryVisual();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 1.08;
        final imageHeight = imageWidth * 1.55;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                // Keep the top of the character inside the visual viewport.
                top: 0,
                left: (constraints.maxWidth - imageWidth) / 2,
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/img/imagen_pantalla3.png',
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                        Color(0xCC0B1B4D),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
