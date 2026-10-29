import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/shipment_form_rules.dart';

void main() {
  test('exige la referencia de recojo la primera vez que se llena un envío',
      () {
    expect(
      requiresFirstPickupReference(
        isShipping: true,
        hasSavedReference: false,
        reference: '',
      ),
      isTrue,
    );
    expect(
      requiresFirstPickupReference(
        isShipping: true,
        hasSavedReference: true,
        reference: '',
      ),
      isFalse,
    );
    expect(
      requiresFirstPickupReference(
        isShipping: false,
        hasSavedReference: false,
        reference: '',
      ),
      isFalse,
    );
  });

  test('precarga el usuario del perfil sin reemplazar un nombre guardado', () {
    expect(
      initialPickupName(
        isSupervisor: false,
        username: 'walford santana',
        savedName: '',
      ),
      'walford santana',
    );
    expect(
      initialPickupName(
        isSupervisor: false,
        username: 'walford santana',
        savedName: 'Walford Santana',
      ),
      'Walford Santana',
    );
    expect(
      initialPickupName(
        isSupervisor: true,
        username: 'supervisor',
        savedName: '',
      ),
      '',
    );
  });

  test('muestra la recomendación del ayudante únicamente para carga', () {
    expect(cargoHelperNoticeFor('Camión', 'cargo-helper'), cargoHelperNotice);
    expect(cargoHelperCardMessage('Camión'), cargoHelperNotice);
    expect(cargoHelperNoticeFor('Camión', 'cargo-round-trip'), isNull);
    expect(cargoHelperNoticeFor('Auto', 'cargo-helper'), isNull);
    expect(cargoHelperCardMessage('Auto'), isNull);
  });
}
