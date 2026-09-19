import 'package:flutter/material.dart';

const Color ink = Color(0xFF10224A);
const Color navy = Color(0xFF111230);
const Color cobalt = Color(0xFF0755E8);
const Color figmaBlue = Color(0xFF0034A6);
const Color cyan = Color(0xFF3EC8F4);
const Color mint = Color(0xFF21C88A);
const Color mist = Color(0xFFFAF8FF);
const Color glassBorder = Color(0x26FFFFFF);
const Color glassFill = Color(0x0FFFFFFF);
const Color surfaceBlue = Color(0xFF003EC7);
const Color glowBlue = Color(0xFF0047FF);
const Color accentBlue = Color(0xFF0A57FF);
const double logisticsServiceFeeCs = 15.0;

/// Redondea la tarifa final al múltiplo de cinco más cercano.
/// La unidad 7 sube al siguiente 10: 857 -> 860.
double roundFareCs(double value) {
  final whole = value.isFinite ? value.floor() : 0;
  if (whole <= 0) return 0;
  if (whole % 10 == 7) return (((whole ~/ 10) + 1) * 10).toDouble();
  return ((whole / 5).round() * 5).toDouble();
}

String formatFareCs(double value) => 'C\$ ${roundFareCs(value).toStringAsFixed(0)}';

final ValueNotifier<bool> appDarkMode = ValueNotifier<bool>(false);

const LinearGradient fondoGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF0C1C53), Color(0xFF1E439F)],
);

const LinearGradient bgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [figmaBlue, navy],
);

const LinearGradient appGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF00256E), navy],
);
