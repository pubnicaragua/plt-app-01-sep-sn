import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/place_history.dart';
import 'package:incoex_logistics_app/screens/crear_envio1.dart';

void main() {
  test('la moto de viajes permite un pasajero', () {
    expect(maxPassengersForTripVehicle('Moto'), 1);
    expect(maxPassengersForTripVehicle('Sedán'), 4);
    expect(maxPassengersForTripVehicle('SUV'), 6);
    expect(maxPassengersForTripVehicle('Microbus'), 12);
    expect(maxPassengersForTripVehicle('Minibus'), 36);
  });

  test('moto aparece como primera opción de viajes', () {
    expect(tripVehicleOptions.first, 'Moto');
    expect(tripVehicleOptions, contains('Minibus'));
  });

  test('un lugar guardado llena el campo con su dirección exacta', () {
    const place = SavedPlace(
      placeId: 'sabana-grande',
      address: 'Sabana Grande, Managua, Nicaragua',
      main: 'Sabana Grande',
      secondary: 'Managua, Nicaragua',
    );

    expect(
      destinationEditingValueForSavedPlace(place).text,
      'Sabana Grande, Managua, Nicaragua',
    );
  });

  test('un toque dentro del panel no se envía al mapa', () {
    expect(
      historyPanelBlocksMapTap(
        historyVisible: true,
        pointerInsidePanel: true,
      ),
      isTrue,
    );
    expect(
      historyPanelBlocksMapTap(
        historyVisible: true,
        pointerInsidePanel: false,
      ),
      isFalse,
    );
  });

  test('la estrella deshabilitada conserva un manejador que consume el toque',
      () {
    var called = false;
    routeFavoriteTapHandler(
      enabled: false,
      onPressed: () => called = true,
    )();

    expect(called, isFalse);
  });

  test('el panel permanece visible mientras se interactúa con sus filtros', () {
    expect(
      placeHistoryPanelVisible(
        panelOpen: true,
        query: '',
        hasHistory: true,
      ),
      isTrue,
    );
    expect(
      placeHistoryPanelVisible(
        panelOpen: true,
        query: 'Managua',
        hasHistory: true,
      ),
      isFalse,
    );
  });

  test('pickup aparece en envíos y tiene una tarifa temporal propia', () {
    expect(shippingVehicleOptions, ['Moto', 'Vehículo', 'Pickup', 'VAN']);
    expect(shippingVehicleAsset('Pickup'),
        'assets/img/HomeCliente/figma_pickup.png');
    expect(temporaryShippingRate('Pickup').baseFeeCs, 120);
    expect(temporaryShippingRate('Pickup').farePerKmCs, 12);
    expect(temporaryShippingRate('Pickup').includedKm, 5);
    expect(shippingVehicleAsset('VAN'), 'assets/img/HomeCliente/figma_van.png');
    expect(temporaryShippingRate('VAN').baseFeeCs, 160);
    expect(temporaryShippingRate('VAN').farePerKmCs, 15);
    expect(temporaryShippingRate('VAN').includedKm, 5);
  });

  test('usa los iconos Figma para favorito apagado y activo', () {
    expect(favoriteCircleAsset(false), favoriteCircleOffAsset);
    expect(favoriteStarAsset(false), favoriteStarOffAsset);
    expect(favoriteCircleAsset(true), favoriteCircleOnAsset);
    expect(favoriteStarAsset(true), favoriteStarOnAsset);
  });
}
