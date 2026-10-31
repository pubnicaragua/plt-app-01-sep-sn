import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_models.dart';

final ApiClient apiClient = ApiClient();

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment('INCOEX_API_URL');

  final http.Client _client;
  String? accessToken;
  SessionUser? currentUser;
  String? currentDriverId;

  static String get _defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  String get baseUrl =>
      _configuredBaseUrl.isEmpty ? _defaultBaseUrl : _configuredBaseUrl;

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
    await refreshCurrentDriver(silent: true);
    return response;
  }

  Future<bool> checkSession() async {
    final token = accessToken;
    if (token == null || token.isEmpty) return false;
    try {
      final json = (await _send(
        'GET',
        '/auth/session/$token',
      )) as Map<String, dynamic>;
      final user = json['user'];
      if (user is Map) {
        currentUser = SessionUser.fromJson(user.cast<String, dynamic>());
      }
      await refreshCurrentDriver(silent: true);
      return json['valid'] == true;
    } catch (error) {
      return error is ApiException && error.statusCode == 401 ? false : true;
    }
  }

  Future<void> clearSession() async {
    accessToken = null;
    currentUser = null;
    currentDriverId = null;
  }

  Future<SessionUser?> refreshCurrentDriver({bool silent = false}) async {
    if (currentUser?.role != 'driver' || accessToken == null)
      return currentUser;
    try {
      final driver =
          (await _send('GET', '/drivers/me')) as Map<String, dynamic>;
      currentDriverId = driver['id']?.toString();
      currentUser = currentUser!.copyWith(
        displayName: driver['name']?.toString(),
        phone: driver['phone']?.toString(),
        vehicle: driver['vehicle']?.toString(),
        plate: driver['plate']?.toString(),
        licenseNumber: driver['licenseNo']?.toString(),
        licenseExpiry: driver['licenseExp']?.toString(),
        vehicleType: driver['vehicle']?.toString(),
      );
      return currentUser;
    } catch (_) {
      if (!silent) rethrow;
      return currentUser;
    }
  }

  Future<SessionUser> updateCurrentDriver({
    String? name,
    String? phone,
    String? licenseNo,
    String? licenseExp,
  }) async {
    final driverId = currentDriverId ?? currentUser?.id;
    if (driverId == null || driverId.isEmpty) {
      throw const ApiException('No se encontró el conductor activo.');
    }
    final driver = (await _send(
      'PATCH',
      '/drivers/${Uri.encodeComponent(driverId)}',
      body: {
        if (name != null) 'name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (licenseNo != null) 'licenseNo': licenseNo.trim(),
        if (licenseExp != null) 'licenseExp': licenseExp.trim(),
      },
    )) as Map<String, dynamic>;
    currentDriverId = driver['id']?.toString() ?? driverId;
    currentUser = currentUser!.copyWith(
      displayName: driver['name']?.toString(),
      phone: driver['phone']?.toString(),
      licenseNumber: driver['licenseNo']?.toString(),
      licenseExpiry: driver['licenseExp']?.toString(),
    );
    return currentUser!;
  }

  Future<LoginResponse> register({
    required String name,
    required String companyName,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? identification,
    String? taxId,
    String? documentName,
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
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (identification != null && identification.trim().isNotEmpty)
          'identification': identification.trim(),
        if (taxId != null && taxId.trim().isNotEmpty) 'taxId': taxId.trim(),
        if (documentName != null && documentName.trim().isNotEmpty)
          'documentName': documentName.trim(),
      },
    )) as Map<String, dynamic>;
    final response = LoginResponse.fromJson(json);
    accessToken = response.accessToken;
    currentUser = response.user;
    return response;
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final json = await _send('GET', '/clients');
    final list = json is List
        ? json
        : json is Map && json['items'] is List
            ? json['items'] as List
            : const [];
    return list
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> updateClient(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? contact,
    String? taxId,
    String? notes,
  }) async {
    final json = await _send(
      'PATCH',
      '/clients/${Uri.encodeComponent(id)}',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (contact != null) 'contact': contact,
        if (taxId != null) 'taxId': taxId,
        if (notes != null) 'notes': notes,
      },
    );
    return (json as Map).cast<String, dynamic>();
  }

  Future<DashboardSummary> getDashboardSummary() async {
    return DashboardSummary.fromJson(
      (await _send('GET', '/dashboard/summary')) as Map<String, dynamic>,
    );
  }

  Future<List<Trip>> getTrips({
    String? status,
    String? driver,
    String? client,
  }) async {
    final query = <String, String>{
      if (status != null) 'status': status,
      if (driver != null) 'driver': driver,
      if (client != null) 'client': client,
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

  Future<List<CompanyProfile>> getCompanyProfiles() async {
    final json = await _send('GET', '/profiles');
    final list = json is List
        ? json
        : json is Map && json['items'] is List
            ? json['items'] as List
            : const [];
    return list
        .whereType<Map>()
        .map((item) => CompanyProfile.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<CompanyProfile> createCompanyProfile({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final json = (await _send(
      'POST',
      '/profiles',
      body: {
        'username': username,
        'displayName': displayName,
        'password': password,
      },
    )) as Map<String, dynamic>;
    return CompanyProfile.fromJson(json);
  }

  Future<CompanyProfile> updateCompanyProfile(
    String id, {
    String? displayName,
    String? password,
    String? status,
    bool? canPayInvoices,
  }) async {
    final json = (await _send(
      'PATCH',
      '/profiles/${Uri.encodeComponent(id)}',
      body: {
        if (displayName != null) 'displayName': displayName,
        if (password != null && password.isNotEmpty) 'password': password,
        if (status != null) 'status': status,
        if (canPayInvoices != null) 'canPayInvoices': canPayInvoices,
      },
    )) as Map<String, dynamic>;
    return CompanyProfile.fromJson(json);
  }

  Future<void> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = currentUser;
    if (session == null) {
      throw const ApiException('No se encontró el perfil activo.');
    }
    await _send(
      'POST',
      '/auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<Trip> getTrip(String id) async {
    final json = (await _send(
      'GET',
      '/trips/${Uri.encodeComponent(id)}',
    )) as Map<String, dynamic>;
    return Trip.fromJson(json);
  }

  Future<Trip> updateTripStatus(
    String id,
    String status, {
    String? deliveryCode,
  }) async {
    final json = (await _send(
      'PATCH',
      '/trips/${Uri.encodeComponent(id)}/status',
      body: {
        'status': status,
        if (deliveryCode != null) 'deliveryCode': deliveryCode,
      },
    )) as Map<String, dynamic>;
    return Trip.fromJson(json);
  }

  Future<Trip> confirmPickupWithEvidence({
    required String tripId,
    required String deliveryCode,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/trips/${Uri.encodeComponent(tripId)}/pickup-confirmation',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['deliveryCode'] = deliveryCode
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    final streamed = await request.send().timeout(const Duration(seconds: 75));
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(decoded is Map ? decoded['message']?.toString() ?? 'No se pudo confirmar la recogida.' : 'No se pudo confirmar la recogida.');
    }
    return Trip.fromJson((decoded as Map).cast<String, dynamic>());
  }

  Future<Trip> updateTripSchedule(
      String id, String scheduledDate, String scheduledTime) async {
    final json = (await _send(
      'PATCH',
      '/trips/${Uri.encodeComponent(id)}/schedule',
      body: {
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
      },
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
    String? contactName,
    String? contactPhone,
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
    double? weight,
    String? weightUnit = 'kg',
    String? serviceMode,
    String? vehicleVariant,
    String? truckType,
    int? passengerCount,
    bool returnTrip = false,
    List<TripStop> stops = const [],
    List<TripOptionSelection> options = const [],
    double? quotedBaseCs,
    double? quotedAdditionalCs,
    double? quotedServiceTotalCs,
    List<String> packagePhotos = const [],
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
        'contactName': contactName,
        'contactPhone': contactPhone,
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
        'weight': weight,
        'weightUnit': weightUnit,
        'serviceMode': serviceMode,
        'vehicleVariant': vehicleVariant,
        'truckType': truckType,
        'passengerCount': passengerCount,
        'returnTrip': returnTrip,
        'stops': stops
            .map((stop) => {
                  'id': stop.id,
                  'label': stop.label,
                  'address': stop.address,
                  'latitude': stop.latitude,
                  'longitude': stop.longitude,
                  'refs': stop.refs,
                  'order': stop.order,
                  'recipientName': stop.recipientName,
                  'recipientPhone': stop.recipientPhone,
                })
            .toList(),
        'options': options.map((option) => option.toJson()).toList(),
        'quotedBaseCs': quotedBaseCs,
        'quotedAdditionalCs': quotedAdditionalCs,
        'quotedServiceTotalCs': quotedServiceTotalCs,
        'packagePhotos': packagePhotos,
        'evidence': packagePhotos,
      },
    )) as Map<String, dynamic>;
    return Trip.fromJson(json);
  }

  Future<Trip> updateTripPayment({
    required String id,
    String? method,
    double? amount,
    String? ref,
    String? status,
    String? productStatus,
  }) async {
    final json = (await _send(
      'PATCH',
      '/trips/${Uri.encodeComponent(id)}/payment',
      body: {
        if (method != null) 'method': method,
        if (amount != null) 'amount': amount,
        if (ref != null) 'ref': ref,
        'date': DateTime.now().toIso8601String(),
        if (status != null) 'status': status,
        if (productStatus != null) 'productStatus': productStatus,
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

  Future<List<IncidentNotification>> getIncidentNotifications() async {
    final json = await _send('GET', '/incidents/notifications');
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((item) => IncidentNotification.fromJson(
              item.cast<String, dynamic>(),
            ))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> addFuelRecord({
    required String plate,
    required double liters,
    double? pricePerLiterCs,
    double? odometerKm,
    String? note,
    required String evidence,
    String? driver,
    String source = 'app',
  }) async {
    final json = await _send(
      'POST',
      '/fuel',
      body: {
        'plate': plate,
        'liters': liters,
        'pricePerLiterCs': pricePerLiterCs,
        'odometerKm': odometerKm,
        'note': note,
        'evidence': evidence,
        'driver': driver,
        'source': source,
      },
    );
    return (json as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> uploadEvidence(
    List<int> bytes,
    String filename, {
    String? tripId,
    String? type,
  }) async {
    final uri = Uri.parse('$baseUrl/uploads/evidence');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );
    if (tripId != null && tripId.isNotEmpty) request.fields['tripId'] = tripId;
    if (type != null && type.isNotEmpty) request.fields['type'] = type;
    if (accessToken != null && accessToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    final streamed = await request.send().timeout(const Duration(seconds: 75));
    final response = await http.Response.fromStream(streamed);
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
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

  Future<List<Map<String, dynamic>>> getPendingCortes() async {
    final json = await _send('GET', '/cortes?status=pendiente');
    if (json is List) {
      return json
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }
    return [];
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
    try {
      if (method == 'POST') {
        response = await _client
            .post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? const {}),
            )
            .timeout(const Duration(seconds: 75));
      } else if (method == 'PATCH') {
        response = await _client
            .patch(
              uri,
              headers: headers,
              body: jsonEncode(body ?? const {}),
            )
            .timeout(const Duration(seconds: 75));
      } else {
        response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 75));
      }
    } on TimeoutException {
      throw ApiException(
        'La API tardó demasiado en responder. Intenta nuevamente en unos segundos.',
      );
    }

    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        accessToken = null;
        currentUser = null;
      }
      final message = decoded is Map ? decoded['message'] : null;
      throw ApiException(
        message?.toString() ?? 'La API respondió con error.',
        statusCode: response.statusCode,
      );
    }
    if (decoded is Map) return decoded.cast<String, dynamic>();
    if (decoded is List) return decoded;
    throw const ApiException('La API devolvió una respuesta inválida.');
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
