import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/dialog_lifecycle.dart';

void main() {
  testWidgets('espera a que se desmonte un diálogo antes de continuar',
      (tester) async {
    var openSecondDialog = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              await showDialogAndWaitForDismissal<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Validar'),
                    ),
                  ],
                ),
              );
              openSecondDialog = true;
              if (context.mounted) {
                await showDialogAndWaitForDismissal<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    content: const Text('Cámara'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Abrir'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Iniciar'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validar'));
    await tester.pumpAndSettle();

    expect(openSecondDialog, isTrue);
    expect(tester.takeException(), isNull);
  });
}
