import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';

final ApiClient apiClient = ApiClient();

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment('INCOEX_API_URL');
  static const defaultBaseUrl = 'http://10.0.2.2:3000/api';

  final http.Client _client;
  String? accessToken;
  SessionUser? currentUser;

  String get baseUrl =>
      _configuredBaseUrl.isEmpty ? defaultBaseUrl : _configuredBaseUrl;

  Future<LoginResponse> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final json = (await _send(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password, 'role': role},
    )) as Map<String, dynamic>;
    final response = LoginResponse.fromJson(json);
    accessToken = response.accessToken;
    currentUser = response.user;
    return response;
  }

  Future<LoginResponse> register({
    required String name,
    required String companyName,
    required String email,
    required String password,
    required String role,
  }) async {
    final json = (await _send(
      'POST',
      '/auth/register',
      body: {
        'name': name,
        'companyName': companyName,
        'email': email,
        'password': password,
        'role': role,
      },
    )) as Map<String, dynamic>;
    final response = LoginResponse.fromJson(json);
    accessToken = response.accessToken;
    currentUser = response.user;
    return response;
  }

  Future<DashboardSummary> getDashboardSummary() async {
    return DashboardSummary.fromJson(
      (await _send('GET', '/dashboard/summary')) as Map<String, dynamic>,
    );
  }

  Future<List<Trip>> getTrips({String? status, String? driver}) async {
    final query = <String, String>{
      if (status != null) 'status': status,
      if (driver != null) 'driver': driver,
    };
    final params = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final json = await _send('GET', '/trips$params');
    final list = json is List
        ? json
        : json is Map && json['items'] is List
            ? json['items'] as List
            : [json];
    return list
        .whereType<Map>()
        .map((item) => Trip.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Trip> getTrip(String id) async {
    final json = (await _send(
      'GET',
      '/trips/${Uri.encodeComponent(id)}',
    )) as Map<String, dynamic>;
    return Trip.fromJson(json);
  }

  Future<Trip> updateTripStatus(String id, String status) async {
    final json = (await _send(
      'PATCH',
      '/trips/${Uri.encodeComponent(id)}/status',
      body: {'status': status},
    )) as Map<String, dynamic>;
    return Trip.fromJson(json);
  }

  Future<Trip> createTrip({
    required String client,
    required String origin,
    required String destination,
    required int packages,
    String? description,
    String? recipientName,
    String? recipientPhone,
    bool fragile = false,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    double? distanceKm,
    String? serviceType,
    String? transport,
    bool autoAssign = false,
    String? originRefs,
    String? destinationRefs,
    String? scheduledDate,
    String? scheduledTime,
    bool isScheduled = false,
  }) async {
    final json = (await _send(
      'POST',
      '/trips',
      body: {
        'client': client,
        'origin': origin,
        'destination': destination,
        'packages': packages,
        'description': description,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'fragile': fragile,
        'originLat': originLat,
        'originLng': originLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'distanceKm': distanceKm,
        'serviceType': serviceType,
        'transport': transport,
        'autoAssign': autoAssign,
        'originRefs': originRefs,
        'destinationRefs': destinationRefs,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'isScheduled': isScheduled,
      },
    )) as Map<String, dynamic>;
    return Trip.fromJson(json);
  }

  Future<TrackingData> getTracking(String tripId) async {
    final encodedTripId = Uri.encodeComponent(tripId);
    return TrackingData.fromJson(
      (await _send('GET', '/trips/$encodedTripId/tracking'))
          as Map<String, dynamic>,
    );
  }

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return const [];
    final json = await _send(
      'GET',
      '/places/autocomplete?q=${Uri.encodeComponent(query)}',
    );
    final list = json is List ? json : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => PlaceSuggestion.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<PlaceSuggestion?> placeDetail(String placeId) async {
    final json = await _send(
      'GET',
      '/places/detail?place_id=${Uri.encodeComponent(placeId)}',
    );
    final map = json is Map ? json.cast<String, dynamic>() : null;
    final latitude = (map?['latitude'] as num?)?.toDouble();
    final longitude = (map?['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;
    return PlaceSuggestion(
      placeId: placeId,
      description: '',
      main: '',
      secondary: '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<AppSettings> getSettings() async {
    return AppSettings.fromJson(
      (await _send('GET', '/settings')) as Map<String, dynamic>,
    );
  }

  Future<void> reportDriverLocation({
    required String driver,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speedKmh,
  }) async {
    try {
      await _send(
        'POST',
        '/drivers/location',
        body: {
          'driver': driver,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'speedKmh': speedKmh,
          'source': 'app',
        },
      );
    } catch (_) {}
  }

  Future<Map<String, dynamic>> reportIncident({
    required String type,
    required String client,
    String? trip,
    String? driver,
    String? priority,
    String? description,
    double? latitude,
    double? longitude,
    String? evidence,
  }) async {
    final json = await _send(
      'POST',
      '/incidents',
      body: {
        'type': type,
        'client': client,
        'trip': trip,
        'driver': driver,
        'priority': priority,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'evidence': evidence,
      },
    );
    return json as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadEvidence(
    List<int> bytes,
    String filename,
  ) async {
    final uri = Uri.parse('$baseUrl/uploads/evidence');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        decoded is Map
            ? decoded['message']?.toString() ?? 'No se pudo subir la evidencia.'
            : 'No se pudo subir la evidencia.',
      );
    }
    return (decoded as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> sendDriverLocation({
    required String driver,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speedKmh,
  }) async {
    return (await _send(
      'POST',
      '/drivers/location',
      body: {
        'driver': driver,
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speedKmh != null) 'speedKmh': speedKmh,
        'source': 'app',
      },
    )) as Map<String, dynamic>;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    late http.Response response;
    if (method == 'POST') {
      response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? const {}),
      );
    } else if (method == 'PATCH') {
      response = await _client.patch(
        uri,
        headers: headers,
        body: jsonEncode(body ?? const {}),
      );
    } else {
      response = await _client.get(uri, headers: headers);
    }

    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message'] : null;
      throw ApiException(message?.toString() ?? 'La API respondió con error.');
    }
    if (decoded is Map) return decoded.cast<String, dynamic>();
    if (decoded is List) return decoded;
    throw const ApiException('La API devolvió una respuesta inválida.');
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
