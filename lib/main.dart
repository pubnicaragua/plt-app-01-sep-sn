import 'package:flutter/material.dart';

import 'core/notifications.dart';
import 'core/theme.dart';
import 'screens/onboarding_recoleccion.dart';

void main() {
  initNotifications();
  runApp(const IncoexApp());
}

class IncoexApp extends StatelessWidget {
  const IncoexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INCOEX Logistics',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Acumin Pro',
        scaffoldBackgroundColor: navy,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: cobalt,
          brightness: Brightness.light,
        ),
      ),
      home: const OnboardingRecoleccion(),
    );
  }
}
