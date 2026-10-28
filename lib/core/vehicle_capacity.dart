import '../core/theme.dart';
import '../models/api_models.dart';

const vehicleMaxWeightKg = <String, double>{
  'Moto': 10,
  'Vehículo': 400,
  'VAN': 650,
  'Pickup': 900,
};

double maxWeightKgForVehicle(String vehicle) =>
    vehicleMaxWeightKg[vehicle] ?? double.infinity;

double weightToKg(double value, String unit) =>
    unit == 'lb' ? value / 2.20462 : value;

String? recommendedVehicleForWeight(double weightKg) {
  for (final entry in vehicleMaxWeightKg.entries) {
    if (weightKg <= entry.value) return entry.key;
  }
  return null;
}

List<String> compatibleVehiclesForWeight(double weightKg) =>
    vehicleMaxWeightKg.entries
        .where((entry) => weightKg <= entry.value)
        .map((entry) => entry.key)
        .toList(growable: false);

VehicleRate defaultShippingRateForVehicle(String vehicle) {
  switch (vehicle) {
    case 'VAN':
      return const VehicleRate(baseFeeCs: 160, farePerKmCs: 15, includedKm: 5);
    case 'Pickup':
      return const VehicleRate(baseFeeCs: 120, farePerKmCs: 12, includedKm: 5);
    default:
      return const VehicleRate(baseFeeCs: 80, farePerKmCs: 8.5, includedKm: 4);
  }
}

double estimatedShippingForVehicle({
  required String vehicle,
  required double distanceKm,
  Map<String, VehicleRate> configuredRates = const {},
  double fareRoundingCs = 5,
}) {
  final rate =
      configuredRates[vehicle] ?? defaultShippingRateForVehicle(vehicle);
  final chargeableKm =
      (distanceKm - rate.includedKm).clamp(0, double.infinity).toDouble();
  return roundFareCs(
    rate.baseFeeCs + chargeableKm * rate.farePerKmCs,
    fareRoundingCs,
  );
}
