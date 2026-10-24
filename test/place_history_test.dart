import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/place_history.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

void main() {
  const place = PlaceSuggestion(
    placeId: 'place-1',
    description: 'Casa amarilla, Managua, Nicaragua',
    main: 'Casa amarilla',
    secondary: 'Managua, Nicaragua',
    latitude: 12.1,
    longitude: -86.2,
  );

  test('agrega una dirección a recientes y evita duplicados', () {
    final history = PlaceHistory();

    history.remember(place);
    history.remember(place);

    expect(history.recent, hasLength(1));
    expect(history.recent.single.address, place.description);
    expect(history.recent.single.latitude, place.latitude);
  });

  test('marca y desmarca una dirección como favorita', () {
    final history = PlaceHistory();

    history.remember(place);
    expect(history.toggleFavorite(place.placeId), isTrue);
    expect(history.favorites.single.address, place.description);
    expect(history.toggleFavorite(place.placeId), isFalse);
    expect(history.favorites, isEmpty);
  });

  test('serializa el texto exacto y las coordenadas para persistirlo', () {
    final saved = SavedPlace.fromSuggestion(place, isFavorite: true);

    final restored = SavedPlace.fromJson(saved.toJson());

    expect(restored.address, place.description);
    expect(restored.latitude, place.latitude);
    expect(restored.longitude, place.longitude);
    expect(restored.isFavorite, isTrue);
  });

  test('genera una clave distinta para cada perfil', () {
    const supervisor = SessionUser(
      id: 'user-1',
      email: 'supervisor@incoex.test',
      role: 'client',
      displayName: 'Supervisor',
      profileId: 'profile-supervisor',
      profileRole: 'supervisor',
    );
    const operator = SessionUser(
      id: 'user-2',
      email: 'walford@incoex.test',
      role: 'client',
      displayName: 'Walford Santana',
      profileId: 'profile-walford',
      profileRole: 'operator',
    );

    expect(placeHistoryProfileKey(supervisor),
        isNot(placeHistoryProfileKey(operator)));
  });

  test('oculta el historial cuando ya se está escribiendo una búsqueda', () {
    expect(shouldShowPlaceHistory(hasFocus: true, query: ''), isTrue);
    expect(shouldShowPlaceHistory(hasFocus: true, query: 'Sabana'), isFalse);
    expect(shouldShowPlaceHistory(hasFocus: false, query: ''), isFalse);
  });

  test('separa los elementos visibles por filtro', () {
    final history = PlaceHistory()
      ..remember(place)
      ..toggleFavorite(place.placeId);

    expect(history.itemsForTab(favorites: true), hasLength(1));
    expect(history.itemsForTab(favorites: false), isEmpty);
  });
}
