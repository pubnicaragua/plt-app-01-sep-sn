import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'IX';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.darken = 0.18,
    this.backgroundLogoOpacity = .53,
    this.backgroundLogoOffsetX = 0,
    this.backgroundLogoOffsetY = 0,
    this.backgroundLogoScale = 1,
  });

  final Widget child;
  final double darken;
  final double backgroundLogoOpacity;
  final double backgroundLogoOffsetX;
  final double backgroundLogoOffsetY;
  final double backgroundLogoScale;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appDarkMode,
      builder: (context, dark, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            if (dark)
              _DarkBase(
                logoOpacity: backgroundLogoOpacity,
                logoOffsetX: backgroundLogoOffsetX,
                logoOffsetY: backgroundLogoOffsetY,
                logoScale: backgroundLogoScale,
              )
            else
              _LightBase(
                logoOpacity: backgroundLogoOpacity,
                logoOffsetX: backgroundLogoOffsetX,
                logoOffsetY: backgroundLogoOffsetY,
                logoScale: backgroundLogoScale,
              ),
            if (dark) Container(color: Colors.black.withValues(alpha: darken)),
            child,
          ],
        );
      },
    );
  }
}

class _LightBase extends StatelessWidget {
  const _LightBase({
    required this.logoOpacity,
    required this.logoOffsetX,
    required this.logoOffsetY,
    required this.logoScale,
  });

  final double logoOpacity;
  final double logoOffsetX;
  final double logoOffsetY;
  final double logoScale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: fondoGradient),
        ),
        _BackgroundLogo(
          opacity: logoOpacity,
          offsetX: logoOffsetX,
          offsetY: logoOffsetY,
          scale: logoScale,
        ),
      ],
    );
  }
}

class _DarkBase extends StatelessWidget {
  const _DarkBase({
    required this.logoOpacity,
    required this.logoOffsetX,
    required this.logoOffsetY,
    required this.logoScale,
  });

  final double logoOpacity;
  final double logoOffsetX;
  final double logoOffsetY;
  final double logoScale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: fondoGradient)),
        _BackgroundLogo(
          opacity: logoOpacity,
          offsetX: logoOffsetX,
          offsetY: logoOffsetY,
          scale: logoScale,
        ),
      ],
    );
  }
}

class _BackgroundLogo extends StatelessWidget {
  const _BackgroundLogo({
    required this.opacity,
    required this.offsetX,
    required this.offsetY,
    required this.scale,
  });

  final double opacity;
  final double offsetX;
  final double offsetY;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 390.0).toDouble();
        final height = width * 793 / 390 * scale;
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: width * scale,
              height: height,
              child: Opacity(
                opacity: opacity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF9BA8C5),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/img/fondoapps.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.blur = 24,
    this.borderRadius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double blur;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .14),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
    this.height = 56,
    this.width = double.infinity,
    this.textColor,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;
  final double height;
  final double width;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(45),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(45),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      filled ? accentBlue : Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(
                    color: filled ? const Color(0x40FFFFFF) : glassBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                    ],
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (textColor != null || icon != null) return button;
    return button;
  }
}

class GlassField extends StatefulWidget {
  const GlassField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.suffix,
    this.helper,
    this.readOnly = false,
    this.maxLines = 1,
    this.showFloatingLabel = true,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final String? helper;
  final bool readOnly;
  final int maxLines;
  final bool showFloatingLabel;

  @override
  State<GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<GlassField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final suffixWidget = widget.suffix;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 13),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscure,
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  readOnly: widget.readOnly,
                  maxLines: widget.maxLines,
                  minLines: widget.maxLines == 1 ? null : 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontFamily: 'Acumin Pro',
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.showFloatingLabel ? widget.label : null,
                    labelStyle: const TextStyle(
                      color: Color(0xFFE8F0FF),
                      fontSize: 12,
                      fontFamily: 'Acumin Pro',
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: Color(0x8CFFFFFF),
                      fontSize: 13,
                      fontFamily: 'Acumin Pro',
                    ),
                    helperText: widget.helper,
                    helperStyle: const TextStyle(
                      color: Color(0xAAB9D4FF),
                      fontSize: 10.5,
                    ),
                    floatingLabelBehavior: widget.showFloatingLabel
                        ? FloatingLabelBehavior.always
                        : FloatingLabelBehavior.never,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (suffixWidget != null) suffixWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.light = true});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      height: 48,
      child: Image.asset('assets/brand/incoex-logo.png', fit: BoxFit.contain),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'Acumin Pro',
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        fontFamily: 'Acumin Pro',
      ),
    );
  }
}

String t(String? value, [String fallback = '—']) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value;
}
