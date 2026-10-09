import '../models/api_models.dart';
import 'trip_routing.dart';

bool hasShipmentInsurance(List<TripOptionSelection> options) => options.any(
      (option) => option.code.startsWith('shipment-insurance-'),
    );

bool shouldOpenInsuranceBeforeBilling(String? serviceMode) =>
    !isTripServiceMode(serviceMode);
