class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
    this.vehicle,
    this.plate,
  });

  final String id;
  final String email;
  final String role;
  final String displayName;
  final String? vehicle;
  final String? plate;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Usuario INCOEX',
      vehicle: json['vehicle']?.toString(),
      plate: json['plate']?.toString(),
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
  });

  final String id;
  final String client;
  final String driver;
  final String origin;
  final String destination;
  final String date;
  final int packages;
  final String status;

  bool get isActive => !{'Completado', 'Cancelado'}.contains(status);

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
    );
  }
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
