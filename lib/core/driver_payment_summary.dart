import '../models/api_models.dart';

/// Payment information persisted by the client flow in the trip description
/// and by the API in the regular service-payment fields.
class DriverPaymentSummary {
  const DriverPaymentSummary({
    required this.productAmount,
    required this.productPaid,
    required this.productMethod,
    required this.productApproximate,
    required this.shipmentPayer,
    required this.serviceAmount,
    required this.servicePaid,
    required this.serviceCredit,
    required this.serviceMethod,
  });

  final double productAmount;
  final bool productPaid;
  final String productMethod;
  final bool productApproximate;
  final String shipmentPayer;
  final double serviceAmount;
  final bool servicePaid;
  final bool serviceCredit;
  final String serviceMethod;

  bool get recipientPays => shipmentPayer.toLowerCase().contains('destinatario');
  bool get productNeedsCollection =>
      productAmount > 0 && !productPaid && !productApproximate;
  bool get serviceSettled => servicePaid || serviceCredit;
  bool get serviceNeedsCollection => !serviceSettled;
  bool get complete => !productNeedsCollection && !serviceNeedsCollection;
  double get totalToCollect =>
      (productNeedsCollection ? productAmount : 0) +
      (serviceNeedsCollection && serviceMethod == 'Efectivo'
          ? serviceAmount
          : 0);
}

DriverPaymentSummary driverPaymentSummaryFor(Trip trip) {
  final description = trip.description ?? '';
  final productStatus = _descriptionValue(
    description,
    r'(?:Estado factura producto|Estado pago producto)',
  );
  final productMethod = _normalizeMethod(
    _descriptionValue(description, r'Método factura producto'),
  );
  final shipmentPayer = _descriptionValue(description, r'Quién paga envío');
  final serviceMethod = _normalizeMethod(
    trip.servicePaymentMethod ??
        trip.paymentMethod ??
        _descriptionValue(description, r'Método pago envío'),
  );
  final serviceStatus = trip.servicePaymentStatus ??
      trip.paymentStatus ??
      _descriptionValue(description, r'Estado pago envío');
  final describedServiceStatus =
      _descriptionValue(description, r'Estado pago envío');
  final recipientPays = shipmentPayer.toLowerCase().contains('destinatario');
  final servicePaymentRecordedByDriver = _hasDriverPaymentReceipt(trip);
  final productApproximate = _descriptionValue(
    description,
    r'Tipo valor producto',
  ).toLowerCase().contains('aproximado');

  return DriverPaymentSummary(
    productAmount: trip.invoiceAmountCs ?? 0,
    productPaid: _isPaid(productStatus),
    productMethod: productMethod.isEmpty ? 'Efectivo' : productMethod,
    productApproximate: productApproximate,
    shipmentPayer: shipmentPayer,
    serviceAmount: trip.estimatedCostCs ?? 0,
    servicePaid: (!recipientPays || servicePaymentRecordedByDriver) &&
        (_isPaid(serviceStatus) || _isPaid(describedServiceStatus)),
    serviceCredit: !recipientPays &&
        (_isCredit(serviceStatus) || _isCredit(describedServiceStatus)),
    serviceMethod: serviceMethod.isEmpty ? 'Efectivo' : serviceMethod,
  );
}

String driverServicePaymentStatusLabel(DriverPaymentSummary payment) {
  if (payment.serviceCredit) return 'Crédito';
  return payment.servicePaid ? 'Pagado' : 'Pendiente';
}

bool paymentValueIsComplete(String? value) => _isPaid(value) || _isCredit(value);

String _descriptionValue(String source, String labelPattern) {
  final match = RegExp(
    '$labelPattern\\s*:\\s*([^·]+)',
    caseSensitive: false,
  ).firstMatch(source);
  return match?.group(1)?.trim() ?? '';
}

bool _isPaid(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized.contains('pagad') ||
      normalized.contains('verificad') ||
      normalized.contains('aprob');
}

bool _isCredit(String? value) =>
    (value ?? '').trim().toLowerCase().contains('crédito') ||
    (value ?? '').trim().toLowerCase().contains('credito');

bool _hasDriverPaymentReceipt(Trip trip) {
  final reference = trip.paymentRef?.trim().toUpperCase() ?? '';
  return reference.startsWith('DRIVER_CONFIRMED') ||
      reference.startsWith('EFECTIVO-') ||
      reference == 'BYPASS_LOCAL_PAYMENT';
}

String _normalizeMethod(String? value) {
  final normalized = (value ?? '').trim();
  if (normalized.isEmpty) return '';
  final lower = normalized.toLowerCase();
  if (lower == 'cash' || lower.contains('efect')) return 'Efectivo';
  if (lower.contains('transfer')) return 'Transferencia';
  if (lower.contains('tarjet') || lower.contains('pocket')) {
    return 'Tarjeta / link de pago';
  }
  return normalized;
}
