import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'glass.dart' show AppBackground;

class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.step,
    required this.body,
    this.totalSteps = 3,
    this.footer,
    this.onClose,
    this.showNotification = true,
    this.showProgress = true,
    this.showDescription = true,
    this.showStepBadge = false,
    this.backgroundLogoOpacity = .53,
    this.backgroundLogoOffsetY = 0,
    this.backgroundLogoScale = 1,
  });

  final String title;
  final String subtitle;
  final String description;
  final int step;
  final Widget body;
  final int totalSteps;
  final Widget? footer;
  final VoidCallback? onClose;
  final bool showNotification;
  final bool showProgress;
  final bool showDescription;
  final bool showStepBadge;
  final double backgroundLogoOpacity;
  final double backgroundLogoOffsetY;
  final double backgroundLogoScale;

  @override
  Widget build(BuildContext context) {
    final footerWidget = footer;
    final safeTotalSteps = totalSteps.clamp(2, 5).toInt();
    final safeStep = step.clamp(0, safeTotalSteps - 1).toInt();
    final sectionLabels = safeTotalSteps == 3
        ? const ['Información del envío', 'Detalles de la carga', 'Confirmación del envío']
        : const ['Información del envío', 'Confirmación del envío'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: onClose == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
                onPressed: onClose,
              ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Acumin Pro',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (showStepBadge)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: .30)),
                ),
                child: Text(
                  'Paso ${safeStep + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            )
          else if (showNotification)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: .18)),
                ),
                child: Image.asset(
                  'assets/img/HomeCliente/notificaciones.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  semanticLabel: 'Notificaciones',
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        backgroundLogoOpacity: backgroundLogoOpacity,
        backgroundLogoOffsetY: backgroundLogoOffsetY,
        backgroundLogoScale: backgroundLogoScale,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                22, showProgress ? 76 : 68, 22, 28),
            children: [
              if (showProgress) ...[
                Row(
                  children: List.generate(
                    safeTotalSteps,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 5,
                        margin: EdgeInsets.only(
                          right: index == safeTotalSteps - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: index <= safeStep
                              ? cyan
                              : Colors.white.withValues(alpha: .16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paso ${safeStep + 1} de $safeTotalSteps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    Text(
                      sectionLabels[safeStep],
                      style: const TextStyle(
                        color: Color(0xFFB9D4FF),
                        fontSize: 10.5,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB9D4FF),
                    fontSize: 12.5,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
              const SizedBox(height: 22),
              body,
              if (footerWidget != null) ...[
                const SizedBox(height: 22),
                footerWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TransportLine extends StatelessWidget {
  const TransportLine({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? figmaBlue.withValues(alpha: .40)
              : Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? cyan : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 10.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? cyan : Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class RoundStep extends StatelessWidget {
  const RoundStep({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 34,
          width: 34,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 12.5,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
      ],
    );
  }
}

class MiniTitle extends StatelessWidget {
  const MiniTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: 'Acumin Pro',
      ),
    );
  }
}
