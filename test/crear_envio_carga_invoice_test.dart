import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/screens/crear_envio_carga.dart';

void main() {
  test('convierte la selección de pago del producto al estado del flujo', () {
    expect(productPaymentStatusForSelection(true), 'Pagado');
    expect(productPaymentStatusForSelection(false), 'Pendiente');
  });

  testWidgets('muestra los datos de venta del nuevo diseño',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrearEnvioCarga(
          origin: 'Origen',
          destination: 'Destino',
          originPlace: null,
          destinationPlace: null,
          transport: 'Moto',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('¿Este envío corresponde a una venta?'), findsOneWidget);
    expect(find.text('¿El producto ya está pagado?'), findsOneWidget);
    expect(find.text('Método de pago'), findsOneWidget);
    expect(find.text('Valor del producto'), findsOneWidget);

    await tester.tap(find.text('No').first);
    await tester.pump();

    expect(find.text('¿El producto ya está pagado?'), findsNothing);
    expect(find.text('Método de pago'), findsNothing);
    expect(find.text('Valor aproximado del producto'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump();

    expect(
      find.text('Ingresa el valor del producto para continuar.'),
      findsOneWidget,
    );
  });
}
