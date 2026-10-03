import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/screens/crear_envio2.dart';

void main() {
  testWidgets('muestra el vehículo seleccionado en detalles de viaje',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CrearEnvio2(
          origin: 'Origen',
          destination: 'Destino',
          transport: 'Vehículo',
          serviceMode: 'Taxi Privado',
          taxiVariant: 'SUV',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SUV'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image &&
            widget.image.toString().contains('taxi_suv.png'),
      ),
      findsOneWidget,
    );
  });
}
