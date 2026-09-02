import 'dart:math' as math;

class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
    this.vehicle,
    this.plate,
    this.phone,
  });

  final String id;
  final String email;
  final String role;
  final String displayName;
  final String? vehicle;
  final String? plate;
  final String? phone;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Usuario INCOEX',
      vehicle: json['vehicle']?.toString(),
      plate: json['plate']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.user});

  final String accessToken;
  final SessionUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      user: SessionUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.tripsToday,
    required this.activeTrips,
    required this.pendingTrips,
    required this.completedTrips,
    required this.activeDrivers,
    required this.registeredClients,
    required this.packagesInTransit,
    required this.openIncidents,
  });

  final int tripsToday;
  final int activeTrips;
  final int pendingTrips;
  final int completedTrips;
  final int activeDrivers;
  final int registeredClients;
  final int packagesInTransit;
  final int openIncidents;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;

    return DashboardSummary(
      tripsToday: number('tripsToday'),
      activeTrips: number('activeTrips'),
      pendingTrips: number('pendingTrips'),
      completedTrips: number('completedTrips'),
      activeDrivers: number('activeDrivers'),
      registeredClients: number('registeredClients'),
      packagesInTransit: number('packagesInTransit'),
      openIncidents: number('openIncidents'),
    );
  }
}

class Trip {
  const Trip({
    required this.id,
    required this.client,
    required this.driver,
    required this.origin,
    required this.destination,
    required this.date,
    required this.packages,
    required this.status,
    this.description,
    this.recipientName,
    this.recipientPhone,
    this.fragile = false,
    this.distanceKm,
    this.estimatedCostCs,
    this.serviceType,
    this.contactName,
    this.contactPhone,
    this.pickupTime,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
  });

  final String id;
  final String client;
  final String driver;
  final String origin;
  final String destination;
  final String date;
  final int packages;
  final String status;
  final String? description;
  final String? recipientName;
  final String? recipientPhone;
  final bool fragile;
  final double? distanceKm;
  final double? estimatedCostCs;
  final String? serviceType;
  final String? contactName;
  final String? contactPhone;
  final String? pickupTime;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;

  bool get isPending => status == 'Pendiente';
  bool get isAssigned => status == 'Asignado';
  bool get isOnWay => status == 'En camino';
  bool get isDelivering => status == 'En entrega';
  bool get isCompleted => status == 'Completado';
  bool get isActive => !{'Completado', 'Cancelado'}.contains(status);

  String get statusLabel {
    switch (status) {
      case 'Asignado':
        return 'Asignado';
      case 'En camino':
        return 'En camino';
      case 'En entrega':
        return 'En entrega';
      case 'Completado':
        return 'Completado';
      case 'Cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString() ?? '',
      client: json['client']?.toString() ?? 'Cliente pendiente',
      driver: json['driver']?.toString() ?? 'Sin asignar',
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      packages: (json['packages'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'Pendiente',
      description: json['description']?.toString(),
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      fragile: json['fragile']?.toString() == 'true',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      estimatedCostCs: (json['estimatedCostCs'] as num?)?.toDouble(),
      serviceType: json['serviceType']?.toString(),
      contactName: json['contactName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      pickupTime: json['pickupTime']?.toString(),
      originLat: (json['originLat'] as num?)?.toDouble(),
      originLng: (json['originLng'] as num?)?.toDouble(),
      destinationLat: (json['destinationLat'] as num?)?.toDouble(),
      destinationLng: (json['destinationLng'] as num?)?.toDouble(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    this.tripId,
    this.read = false,
  });

  final String title;
  final String body;
  final String? tripId;
  final bool read;
}

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      label: json['label']?.toString() ?? '',
    );
  }
}

class TrackingData {
  const TrackingData({
    required this.tripId,
    required this.status,
    required this.driver,
    required this.lastUpdate,
    required this.route,
  });

  final String tripId;
  final String status;
  final String driver;
  final String lastUpdate;
  final List<TrackingPoint> route;

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    final points = (json['route'] as List? ?? const [])
        .whereType<Map>()
        .map((point) => TrackingPoint.fromJson(point.cast<String, dynamic>()))
        .toList();
    return TrackingData(
      tripId: json['tripId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pendiente',
      driver: json['driver']?.toString() ?? 'Sin asignar',
      lastUpdate: json['lastUpdate']?.toString() ?? '',
      route: points,
    );
  }
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.main,
    required this.secondary,
    this.latitude,
    this.longitude,
  });

  final String placeId;
  final String description;
  final String main;
  final String secondary;
  final double? latitude;
  final double? longitude;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['placeId']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      main: json['main']?.toString() ?? '',
      secondary: json['secondary']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class VehicleRate {
  const VehicleRate({
    required this.baseFeeCs,
    required this.farePerKmCs,
  });

  final double baseFeeCs;
  final double farePerKmCs;

  factory VehicleRate.fromJson(Map<String, dynamic> json) {
    return VehicleRate(
      baseFeeCs: (json['baseFeeCs'] as num?)?.toDouble() ?? 80,
      farePerKmCs: (json['farePerKmCs'] as num?)?.toDouble() ?? 8.5,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.dollarRate,
    required this.vehicleRates,
  });

  final double dollarRate;
  final Map<String, VehicleRate> vehicleRates;

  VehicleRate rateFor(String vehicle) =>
      vehicleRates[vehicle] ?? vehicleRates['Vehículo'] ?? const VehicleRate(baseFeeCs: 80, farePerKmCs: 8.5);

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rates = (json['vehicleRates'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return AppSettings(
      dollarRate: (json['dollarRate'] as num?)?.toDouble() ?? 36.5,
      vehicleRates: rates.map(
        (key, value) => MapEntry(
          key,
          VehicleRate.fromJson((value as Map?)?.cast<String, dynamic>() ?? const {}),
        ),
      ),
    );
  }
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _radians(lat2 - lat1);
  final dLng = _radians(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return earthRadiusKm * 2 * math.asin(math.sqrt(a));
}

double _radians(double degrees) => degrees * math.pi / 180.0;
