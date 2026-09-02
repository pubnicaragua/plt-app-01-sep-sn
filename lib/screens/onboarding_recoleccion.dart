import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart' show BrandLockup;
import 'inicio.dart';
import 'onboarding_monitoreo.dart';

class OnboardingRecoleccion extends StatefulWidget {
  const OnboardingRecoleccion({super.key});

  @override
  State<OnboardingRecoleccion> createState() => _OnboardingRecoleccionState();
}

class _OnboardingRecoleccionState extends State<OnboardingRecoleccion> {
  static const titulo =
      'Gestiona la recolección,\nentrega de tus paquetes de forma\nrápida y segura desde un solo lugar.';
  static const visual = 'assets/img/imagen_pantalla1.png';

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
                          color: index == 0
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
                            visual,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                  onNext: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingMonitoreo(),
                      ),
                    );
                  },
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

class HeroCopy extends StatelessWidget {
  const HeroCopy({
    super.key,
    required this.title,
    required this.onNext,
    required this.onSkip,
  });

  final String title;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.7,
            fontWeight: FontWeight.w600,
            fontFamily: 'Acumin Pro',
          ),
        ),
        const SizedBox(height: 24),
        _PillButton(
          label: 'Continuar',
          filled: false,
          onTap: onNext,
        ),
        const SizedBox(height: 10),
        _PillButton(
          label: 'Omitir',
          filled: true,
          blueText: true,
          onTap: onSkip,
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.blueText = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool blueText;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(45),
          child: Container(
            decoration: BoxDecoration(
              color: filled
                  ? Colors.white
                  : const Color(0xFF111230).withValues(alpha: .92),
              borderRadius: BorderRadius.circular(45),
              border: Border.all(
                color: filled
                    ? Colors.white
                    : const Color(0xB3FFFFFF).withValues(alpha: .45),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: blueText ? figmaBlue : Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return button;
  }
}
