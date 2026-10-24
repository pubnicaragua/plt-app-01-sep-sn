import '../models/api_models.dart';

PlaceSuggestion placeFromGeocode({
  required double latitude,
  required double longitude,
  Map<String, dynamic>? result,
}) {
  final address = result?['formatted_address']?.toString().trim();
  final components = (result?['address_components'] as List?)
          ?.whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList() ??
      const <Map<String, dynamic>>[];

  String componentOf(String type) {
    for (final component in components) {
      final types =
          (component['types'] as List?)?.map((value) => value.toString());
      if (types?.contains(type) == true) {
        return component['long_name']?.toString() ?? '';
      }
    }
    return '';
  }

  final main = componentOf('route').isNotEmpty
      ? componentOf('route')
      : componentOf('locality').isNotEmpty
          ? componentOf('locality')
          : address?.isNotEmpty == true
              ? address!
              : 'Punto seleccionado';
  final secondary = componentOf('locality').isNotEmpty
      ? componentOf('locality')
      : componentOf('country');
  final description = address?.isNotEmpty == true
      ? address!
      : 'Punto seleccionado (${latitude.toStringAsFixed(6)}, '
          '${longitude.toStringAsFixed(6)})';

  return PlaceSuggestion(
    placeId: 'map:$latitude,$longitude',
    description: description,
    main: main,
    secondary: secondary,
    latitude: latitude,
    longitude: longitude,
  );
}
