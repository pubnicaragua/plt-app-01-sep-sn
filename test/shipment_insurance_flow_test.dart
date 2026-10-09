import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/insurance_flow.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

void main() {
  test('un seguro seleccionado se identifica para no volver a mostrarlo', () {
    const options = [
      TripOptionSelection(
        code: 'cargo-helper',
        title: 'Ayudante',
        priceCs: 40,
      ),
      TripOptionSelection(
        code: 'shipment-insurance-a',
        title: 'Seguro A',
        priceCs: 15,
      ),
    ];

    expect(hasShipmentInsurance(options), isTrue);
  });

  test('Envíos y Carga deben elegir seguro antes de facturar', () {
    expect(shouldOpenInsuranceBeforeBilling('Envíos'), isTrue);
    expect(shouldOpenInsuranceBeforeBilling('Taxi Privado'), isFalse);
  });
}
