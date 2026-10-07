import '../models/api_models.dart';

String _normalized(String? value) =>
    (value ?? '').trim().toLowerCase().replaceAll('ó', 'o');

bool isTripServiceMode(String? serviceMode) {
  final normalized = _normalized(serviceMode);
  return normalized == 'taxi privado' ||
      normalized == 'viaje' ||
      normalized == 'viajes';
}

bool shouldRouteThroughPickup(String? status) {
  switch (_normalized(status)) {
    case 'recogio':
    case 'en viaje':
    case 'en entrega':
    case 'completado':
    case 'cancelado':
    case 'anulado':
      return false;
    default:
      return true;
  }
}

DateTime? scheduledStartForTrip(Trip trip) {
  final scheduled = trip.isScheduled ||
      _normalized(trip.serviceType) == 'programado';
  if (!scheduled) return null;
  final date = DateTime.tryParse(trip.scheduledDate ?? '');
  if (date == null) return null;

  final timeParts = (trip.scheduledTime ?? '').trim().split(':');
  final hour = timeParts.isNotEmpty ? int.tryParse(timeParts.first) : null;
  final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) : null;
  return DateTime(
    date.year,
    date.month,
    date.day,
    hour != null && hour >= 0 && hour <= 23 ? hour : 0,
    minute != null && minute >= 0 && minute <= 59 ? minute : 0,
  );
}

bool isScheduledBeforeStart(Trip trip, DateTime now) {
  final start = scheduledStartForTrip(trip);
  return start != null && now.isBefore(start);
}
