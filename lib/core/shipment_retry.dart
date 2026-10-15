bool shouldCreateShipmentTrip(String? existingTripId) {
  return existingTripId == null || existingTripId.trim().isEmpty;
}
