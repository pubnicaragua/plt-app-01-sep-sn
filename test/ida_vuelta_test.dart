import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/screens/ida_vuelta.dart';

void main() {
  testWidgets('la configuración de regreso conserva pasajeros y modalidad',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    IdaVueltaConfig? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<IdaVueltaConfig>(
                    MaterialPageRoute(
                      builder: (_) => const IdaVueltaScreen(
                        initialPassengers: 2,
                        maxPassengers: 4,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir ida y vuelta'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir ida y vuelta'));
    await tester.pumpAndSettle();
    expect(find.text('¿Regresarán más pasajeros?'), findsOneWidget);
    expect(find.textContaining('Máximo 4 pasajeros'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('Guardar configuración de Ida y Vuelta'));
    await tester.pumpAndSettle();
    expect(result?.passengerCount, 3);
    expect(result?.returnTime, const TimeOfDay(hour: 18, minute: 0));
    expect(result?.waitMode, ReturnWaitMode.scheduledReturn);
  });
}
