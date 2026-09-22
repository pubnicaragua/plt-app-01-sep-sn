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
    this.companyName,
  });

  final String id;
  final String email;
  final String role;
  final String displayName;
  final String? vehicle;
  final String? plate;
  final String? phone;
  final String? companyName;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Usuario INCOEX',
      vehicle: json['vehicle']?.toString(),
      plate: json['plate']?.toString(),
      phone: json['phone']?.toString(),
      companyName: json['companyName']?.toString(),
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.user,
    this.profile = const {},
  });

  final String accessToken;
  final SessionUser user;
  final Map<String, dynamic> profile;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      user: SessionUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      profile: (json['profile'] as Map?)?.cast<String, dynamic>() ?? const {},
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
      this.invoiceAmountCs,
      this.serviceType,
    this.transport,
    this.contactName,
    this.contactPhone,
    this.driverPhoto,
    this.pickupTime,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    this.scheduledDate,
    this.scheduledTime,
    this.isScheduled = false,
    this.weight,
    this.weightUnit,
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
  final double? invoiceAmountCs;
  final String? serviceType;
  final String? transport;
  final String? contactName;
  final String? contactPhone;
  final String? driverPhoto;
  final String? pickupTime;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? scheduledDate;
  final String? scheduledTime;
  final bool isScheduled;
  final double? weight;
  final String? weightUnit;

  bool get isPending => status == 'Pendiente';
  bool get isAssigned => status == 'Asignado';
  bool get isOnWay => status == 'En camino';
  bool get isDelivering => status == 'En entrega';
  bool get isCompleted => status == 'Completado';
  bool get isActive => !{'Completado', 'Cancelado', 'Anulado'}.contains(status);

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
    final description = json['description']?.toString();
    final invoiceAmount = (json['invoiceAmountCs'] as num?)?.toDouble();
    return Trip(
      id: json['id']?.toString() ?? '',
      client: json['client']?.toString() ?? 'Cliente pendiente',
      driver: json['driver']?.toString() ?? 'Sin asignar',
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      packages: (json['packages'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'Pendiente',
      description: description,
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      fragile: json['fragile']?.toString() == 'true',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      estimatedCostCs: (json['estimatedCostCs'] as num?)?.toDouble(),
      invoiceAmountCs: invoiceAmount != null && invoiceAmount > 0
          ? invoiceAmount
          : _invoiceAmountFromDescription(description),
      serviceType: json['serviceType']?.toString(),
      transport: json['transport']?.toString(),
      contactName: json['contactName']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      driverPhoto: (json['driverPhoto'] ?? json['driverAvatar'] ?? json['photo'])?.toString(),
      pickupTime: json['pickupTime']?.toString(),
      originLat: (json['originLat'] as num?)?.toDouble(),
      originLng: (json['originLng'] as num?)?.toDouble(),
      destinationLat: (json['destinationLat'] as num?)?.toDouble(),
      destinationLng: (json['destinationLng'] as num?)?.toDouble(),
      scheduledDate: json['scheduledDate']?.toString(),
      scheduledTime: json['scheduledTime']?.toString(),
      isScheduled: json['isScheduled']?.toString() == 'true',
      weight: (json['weight'] as num?)?.toDouble(),
      weightUnit: json['weightUnit']?.toString(),
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

class DriverLive {
  const DriverLive({
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    this.accuracy,
    this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final double? speedKmh;
  final double? accuracy;
  final int? updatedAt;

  factory DriverLive.fromJson(Map<String, dynamic> json) {
    return DriverLive(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      updatedAt: (json['updatedAt'] as num?)?.toInt(),
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
    this.driverLocation,
    this.shareUrl,
    this.driverVehicle,
    this.driverPlate,
    this.driverPhone,
    this.driverPhoto,
    this.currentLocationLabel,
    this.transport,
    this.routeProvider,
    this.routeDistanceKm,
    this.routeDurationSeconds,
  });

  final String tripId;
  final String status;
  final String driver;
  final String lastUpdate;
  final List<TrackingPoint> route;
  final DriverLive? driverLocation;
  final String? shareUrl;
  final String? driverVehicle;
  final String? driverPlate;
  final String? driverPhone;
  final String? driverPhoto;
  final String? currentLocationLabel;
  final String? transport;
  final String? routeProvider;
  final double? routeDistanceKm;
  final int? routeDurationSeconds;

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    final points = (json['route'] as List? ?? const [])
        .whereType<Map>()
        .map((point) => TrackingPoint.fromJson(point.cast<String, dynamic>()))
        .toList();
    final location = json['driverLocation'];
    return TrackingData(
      tripId: json['tripId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pendiente',
      driver: json['driver']?.toString() ?? 'Sin asignar',
      lastUpdate: json['lastUpdate']?.toString() ?? '',
      route: points,
      driverLocation: location is Map
          ? DriverLive.fromJson(location.cast<String, dynamic>())
          : null,
      shareUrl: json['shareUrl']?.toString(),
      driverVehicle: json['driverVehicle']?.toString(),
      driverPlate: json['driverPlate']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      driverPhoto: (json['driverPhoto'] ?? json['driverAvatar'] ?? json['photo'])?.toString(),
      currentLocationLabel: json['currentLocationLabel']?.toString(),
      transport: json['transport']?.toString(),
      routeProvider: json['routeProvider']?.toString(),
      routeDistanceKm: (json['routeDistanceKm'] as num?)?.toDouble(),
      routeDurationSeconds: (json['routeDurationSeconds'] as num?)?.toInt(),
    );
  }
}

double? _invoiceAmountFromDescription(String? description) {
  final text = description ?? '';
  final match = RegExp(
    r'(?:Valor de factura|por)\s+C\$\s*([0-9]+(?:[.,][0-9]+)?)',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;
  return double.tryParse(match.group(1)!.replaceAll(',', '.'));
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
    required this.includedKm,
  });

  final double baseFeeCs;
  final double farePerKmCs;
  final double includedKm;

  factory VehicleRate.fromJson(Map<String, dynamic> json) {
    return VehicleRate(
      baseFeeCs: (json['baseFeeCs'] as num?)?.toDouble() ?? 80,
      farePerKmCs: (json['farePerKmCs'] as num?)?.toDouble() ?? 8.5,
      includedKm: (json['includedKm'] as num?)?.toDouble() ?? 4,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.dollarRate,
    required this.vehicleRates,
    this.fareRoundingCs = 5,
    this.prioritySurchargePct = 25,
    this.scheduledSurchargePct = 0,
  });

  final double dollarRate;
  final Map<String, VehicleRate> vehicleRates;
  final double fareRoundingCs;
  final double prioritySurchargePct;
  final double scheduledSurchargePct;

  VehicleRate rateFor(String vehicle) =>
      vehicleRates[vehicle] ??
      vehicleRates['Vehículo'] ??
      const VehicleRate(baseFeeCs: 80, farePerKmCs: 8.5, includedKm: 4);

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rates = (json['vehicleRates'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return AppSettings(
      dollarRate: (json['dollarRate'] as num?)?.toDouble() ?? 36.5,
      fareRoundingCs: (json['fareRoundingCs'] as num?)?.toDouble() ?? 5,
      vehicleRates: rates.map(
        (key, value) => MapEntry(
          key,
          VehicleRate.fromJson(
              (value as Map?)?.cast<String, dynamic>() ?? const {}),
        ),
      ),
      prioritySurchargePct:
          (json['prioritySurchargePct'] as num?)?.toDouble() ?? 25,
      scheduledSurchargePct:
          (json['scheduledSurchargePct'] as num?)?.toDouble() ?? 0,
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

double? distanceKm(PlaceSuggestion? from, PlaceSuggestion? to) {
  if (from == null || to == null) return null;
  final fromLatitude = from.latitude;
  final fromLongitude = from.longitude;
  final toLatitude = to.latitude;
  final toLongitude = to.longitude;
  if (fromLatitude == null ||
      fromLongitude == null ||
      toLatitude == null ||
      toLongitude == null) {
    return null;
  }
  return haversineKm(
    fromLatitude,
    fromLongitude,
    toLatitude,
    toLongitude,
  );
}

double _radians(double degrees) => degrees * math.pi / 180.0;

class IncidentNotification {
  const IncidentNotification({
    required this.id,
    required this.scope,
    required this.trip,
    required this.driver,
    required this.client,
    required this.type,
    required this.priority,
    required this.status,
    this.description = '',
    this.createdAt = 0,
  });

  final String id;
  final String scope;
  final String trip;
  final String driver;
  final String client;
  final String type;
  final String priority;
  final String status;
  final String description;
  final int createdAt;

  bool get isGeneral => scope == 'general';

  factory IncidentNotification.fromJson(Map<String, dynamic> json) {
    return IncidentNotification(
      id: json['id']?.toString() ?? '',
      scope: json['scope']?.toString() ?? 'trip',
      trip: json['trip']?.toString() ?? '',
      driver: json['driver']?.toString() ?? '',
      client: json['client']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Incidencia',
      priority: json['priority']?.toString() ?? 'Media',
      status: json['status']?.toString() ?? 'Abierta',
      description: json['description']?.toString() ?? '',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}
