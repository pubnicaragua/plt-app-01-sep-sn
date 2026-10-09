import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/screens/crear_envio_carga.dart';

void main() {
  test('el método de pago solo se muestra cuando el producto está pendiente', () {
    expect(shouldShowProductPaymentMethod('Pendiente'), isTrue);
    expect(shouldShowProductPaymentMethod('Pagado'), isFalse);
  });

  testWidgets('oculta el selector al marcar el producto como pagado',
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

    expect(find.text('Método de pago'), findsOneWidget);
    await tester.tap(find.text('Pagado'));
    await tester.pump();

    expect(find.text('Método de pago'), findsNothing);
  });
}
