import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/delivery_confirmation_flow.dart';

void main() {
  test('inicia solicitando validar el código', () {
    expect(
      deliveryConfirmationButtonLabel(
        codeValidated: false,
        evidenceUploaded: false,
      ),
      'Validar código',
    );
  });

  test('después del código solicita agregar la foto', () {
    expect(
      deliveryConfirmationButtonLabel(
        codeValidated: true,
        evidenceUploaded: false,
      ),
      'Agregar foto del paquete',
    );
  });

  test('después de subir la foto permite registrar la entrega', () {
    expect(
      deliveryConfirmationButtonLabel(
        codeValidated: true,
        evidenceUploaded: true,
      ),
      'Registrar entrega',
    );
  });
}
