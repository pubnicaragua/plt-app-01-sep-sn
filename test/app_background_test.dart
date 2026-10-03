import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/widgets/glass.dart';

void main() {
  for (final size in [const Size(360, 800), const Size(430, 932)]) {
    testWidgets('mantiene el fondo completo y ocupa $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBackground(
              child: Center(child: Text('Contenido de pantalla')),
            ),
          ),
        ),
      );

      final backgroundImages = tester.widgetList<Image>(find.byType(Image));
      expect(backgroundImages.length, 1);
      expect(backgroundImages.single.fit, BoxFit.fill);
      expect(find.text('Contenido de pantalla'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
