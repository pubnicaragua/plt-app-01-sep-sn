import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';

class SavedPlace {
  const SavedPlace({
    required this.placeId,
    required this.address,
    required this.main,
    required this.secondary,
    this.latitude,
    this.longitude,
    this.isFavorite = false,
  });

  final String placeId;
  final String address;
  final String main;
  final String secondary;
  final double? latitude;
  final double? longitude;
  final bool isFavorite;

  factory SavedPlace.fromSuggestion(
    PlaceSuggestion place, {
    bool isFavorite = false,
  }) {
    return SavedPlace(
      placeId: place.placeId,
      address: place.description,
      main: place.main,
      secondary: place.secondary,
      latitude: place.latitude,
      longitude: place.longitude,
      isFavorite: isFavorite,
    );
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      placeId: json['placeId']?.toString() ?? json['address']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      main: json['main']?.toString() ?? json['address']?.toString() ?? '',
      secondary: json['secondary']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'address': address,
        'main': main,
        'secondary': secondary,
        'latitude': latitude,
        'longitude': longitude,
        'isFavorite': isFavorite,
      };

  PlaceSuggestion toSuggestion() => PlaceSuggestion(
        placeId: placeId,
        description: address,
        main: main,
        secondary: secondary,
        latitude: latitude,
        longitude: longitude,
      );

  SavedPlace copyWith({bool? isFavorite}) => SavedPlace(
        placeId: placeId,
        address: address,
        main: main,
        secondary: secondary,
        latitude: latitude,
        longitude: longitude,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

class PlaceHistory {
  PlaceHistory([Iterable<SavedPlace> places = const []])
      : _places = List<SavedPlace>.from(places);

  final List<SavedPlace> _places;

  List<SavedPlace> get recent => List.unmodifiable(_places);

  List<SavedPlace> get favorites => List.unmodifiable(
        _places.where((place) => place.isFavorite),
      );

  List<SavedPlace> itemsForTab({required bool favorites}) {
    return List.unmodifiable(
      favorites ? _places.where((place) => place.isFavorite) : _places,
    );
  }

  void remember(PlaceSuggestion place) {
    final previous = _find(place.placeId, place.description);
    _places.removeWhere(
      (item) =>
          item.placeId == place.placeId || item.address == place.description,
    );
    _places.insert(
      0,
      SavedPlace.fromSuggestion(
        place,
        isFavorite: previous?.isFavorite ?? false,
      ),
    );
    if (_places.length > 12) {
      final removable = _places.lastIndexWhere((item) => !item.isFavorite);
      if (removable >= 0) _places.removeAt(removable);
    }
  }

  bool toggleFavorite(String placeId) {
    final index = _places.indexWhere((place) => place.placeId == placeId);
    if (index < 0) return false;
    final nextValue = !_places[index].isFavorite;
    _places[index] = _places[index].copyWith(isFavorite: nextValue);
    return nextValue;
  }

  SavedPlace? _find(String placeId, String address) {
    for (final place in _places) {
      if (place.placeId == placeId || place.address == address) return place;
    }
    return null;
  }
}

class PlaceHistoryStore {
  static const _prefix = 'incoex.place_history.';

  static Future<PlaceHistory> load(String profileKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$profileKey');
    if (raw == null || raw.isEmpty) return PlaceHistory();
    try {
      final data = jsonDecode(raw);
      if (data is! List) return PlaceHistory();
      return PlaceHistory(
        data.whereType<Map>().map(
              (item) => SavedPlace.fromJson(item.cast<String, dynamic>()),
            ),
      );
    } catch (_) {
      return PlaceHistory();
    }
  }

  static Future<void> save(String profileKey, PlaceHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$profileKey',
      jsonEncode(history.recent.map((place) => place.toJson()).toList()),
    );
  }
}

String placeHistoryProfileKey(SessionUser? user) {
  final profileId = user?.profileId?.trim();
  if (profileId != null && profileId.isNotEmpty) return 'profile_$profileId';
  final accountId = user?.accountId?.trim();
  if (accountId != null && accountId.isNotEmpty) return 'account_$accountId';
  final userId = user?.id.trim();
  if (userId != null && userId.isNotEmpty) return 'user_$userId';
  return 'guest';
}

bool shouldShowPlaceHistory({
  required bool hasFocus,
  required String query,
}) {
  return hasFocus && query.trim().isEmpty;
}
