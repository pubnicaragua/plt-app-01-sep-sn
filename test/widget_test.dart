// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/main.dart';

void main() {
  testWidgets('muestra onboarding y permite avanzar hasta acceso',
      (tester) async {
    await tester.pumpWidget(const IncoexApp());

    expect(find.textContaining('Gestiona la recolección'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Monitorea cada pedido'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Disfruta de entregas express'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Inicia Sesión'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
