import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/widgets/glass.dart';

void main() {
  testWidgets('GlassField permite mostrar y ocultar una contraseña',
      (tester) async {
    final controller = TextEditingController(text: 'secreta');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassField(
            label: 'Contraseña actual',
            controller: controller,
            obscure: true,
          ),
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });
}
