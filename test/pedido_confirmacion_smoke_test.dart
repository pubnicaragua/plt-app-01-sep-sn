import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/screens/confirmar_pedido.dart';
import 'package:incoex_logistics_app/screens/crear_envio2.dart';

void main() {
  testWidgets('renderiza el paso 2 con sus datos de carga', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrearEnvio2(
          origin: 'Mi ubicación actual',
          destination: 'Oficinas Incoex',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Paso 2 de 3'), findsOneWidget);
    expect(find.text('Peso y dimensiones'), findsOneWidget);
    expect(find.text('Información del paquete'), findsOneWidget);
    expect(find.text('ESTADO DEL PAGO'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });

  testWidgets('renderiza confirmación y cálculo del destinatario', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Confirmarpedido(
          origin: 'Mi ubicación actual',
          destination: 'Oficinas Incoex',
          weight: 10,
          weightUnit: 'kg',
          bundles: 1,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Paso 3 de 3'), findsOneWidget);
    expect(find.text('Transporte recomendado'), findsOneWidget);
    expect(find.text('TOTAL A COBRAR AL DESTINATARIO'), findsOneWidget);
    expect(find.text('Confirmar envío'), findsOneWidget);
  });
}
