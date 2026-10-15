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

ThemeData appDatePickerTheme(ThemeData base) {
  const pickerSurface = Color(0xFF102A67);
  return base.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      onPrimary: Colors.white,
      surface: pickerSurface,
      onSurface: Colors.white,
      secondary: accentBlue,
      onSecondary: Colors.white,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: pickerSurface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: accentBlue,
      headerForegroundColor: Colors.white,
      rangePickerBackgroundColor: pickerSurface,
      rangePickerHeaderBackgroundColor: accentBlue,
      rangePickerHeaderForegroundColor: Colors.white,
      weekdayStyle: TextStyle(color: Colors.white),
      dayStyle: TextStyle(color: Colors.white),
      yearStyle: TextStyle(color: Colors.white),
      headerHeadlineStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      headerHelpStyle: TextStyle(color: Colors.white70),
      dayForegroundColor: MaterialStatePropertyAll(Colors.white),
      todayForegroundColor: MaterialStatePropertyAll(Colors.white),
      todayBackgroundColor: MaterialStatePropertyAll(Colors.transparent),
      rangeSelectionBackgroundColor: Color(0x660A57FF),
    ),
  );
}

/// Redondea al múltiplo comercial configurado más cercano.
/// Con múltiplo 5, la unidad 7 conserva la regla especial 857 -> 860.
double roundFareCs(double value, [double multiple = 5]) {
  final whole = value.isFinite ? value.floor() : 0;
  if (whole <= 0) return 0;
  final step = multiple.isFinite ? multiple.round().clamp(1, 1000000) : 5;
  if (step == 5 && whole % 10 == 7) {
    return (((whole ~/ 10) + 1) * 10).toDouble();
  }
  return ((whole / step).round() * step).toDouble();
}

String formatFareCs(double value, [double multiple = 5]) =>
    'C\$ ${roundFareCs(value, multiple).toStringAsFixed(0)}';

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
