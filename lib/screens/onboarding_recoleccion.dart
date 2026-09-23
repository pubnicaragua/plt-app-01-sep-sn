import 'dart:ui';

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
      'Gestiona la recolección,\nentrega de tus paquetes de forma rápida\ny segura desde un solo lugar.';
  static const visual = 'assets/img/imagen_pantalla1.png';

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
                            color: index == 0
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
                    asset: visual,
                    scale: 1.85,
                    topFactor: 0,
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
            fontSize: 18,
            height: 1.22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Figtree',
          ),
        ),
        const SizedBox(height: 64),
        _PillButton(
          label: 'Continuar',
          filled: false,
          onTap: onNext,
        ),
        const SizedBox(height: 8),
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
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(45),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(45),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: filled ? Colors.white : null,
                  gradient: filled
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x603A4E80),
                            Color(0x4C15244F),
                            Color(0x2A0B1536),
                          ],
                          stops: [0, .52, 1],
                        ),
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(
                    color: filled
                        ? Colors.white
                        : Colors.white.withValues(alpha: .28),
                  ),
                  boxShadow: filled
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x552D5EAA),
                            blurRadius: 12,
                            spreadRadius: -2,
                            offset: Offset(0, 1),
                          ),
                          BoxShadow(
                            color: Color(0x44000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: blueText ? figmaBlue : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
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

class OnboardingVisual extends StatelessWidget {
  const OnboardingVisual({
    super.key,
    required this.asset,
    this.scale = 1.25,
    this.topFactor = .17,
  });

  final String asset;
  final double scale;
  final double topFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxWidth * scale;
        final imageTop = constraints.maxHeight * topFactor;

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
                  top: imageTop,
                  left: (fullWidth - imageSize) / 2,
                  width: imageSize,
                  height: imageSize,
                  child: Image.asset(
                    asset,
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
                        stops: [.63, .96],
                        colors: [
                          Colors.transparent,
                          Color(0x330B1B4D),
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
