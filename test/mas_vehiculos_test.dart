import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/screens/mas_vehiculos.dart';

void main() {
  testWidgets('muestra el tipo seleccionado y devuelve la cantidad adicional',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<int>(
                  MaterialPageRoute(
                    builder: (_) => const MasVehiculosScreen(
                      vehicleType: 'SUV',
                    ),
                  ),
                );
              },
              child: const Text('Abrir más vehículos'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir más vehículos'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('SUV = cantidad de SUVs'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Añadir vehículos'));
    await tester.pumpAndSettle();
    expect(result, 1);
  });
}
