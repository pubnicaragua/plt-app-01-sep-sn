import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/screens/crear_envio1.dart';

void main() {
  testWidgets('renderiza los detalles de carga sin excepciones', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CrearEnvio1()),
    );
    await tester.pump();

    expect(find.text('Detalles de carga'), findsOneWidget);
    expect(find.text('Peso y dimensiones'), findsOneWidget);
    expect(find.text('Información del paquete'), findsOneWidget);
    expect(find.text('Paso 2'), findsOneWidget);
  });
}
