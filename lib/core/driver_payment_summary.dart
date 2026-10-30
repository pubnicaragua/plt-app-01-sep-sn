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
    required this.serviceMethod,
  });

  final double productAmount;
  final bool productPaid;
  final String productMethod;
  final bool productApproximate;
  final String shipmentPayer;
  final double serviceAmount;
  final bool servicePaid;
  final String serviceMethod;

  bool get recipientPays => shipmentPayer.toLowerCase().contains('destinatario');
  bool get productNeedsCollection =>
      productAmount > 0 && !productPaid && !productApproximate;
  bool get serviceNeedsCollection => !servicePaid;
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
    servicePaid: _isPaid(serviceStatus),
    serviceMethod: serviceMethod.isEmpty ? 'Efectivo' : serviceMethod,
  );
}

bool paymentValueIsComplete(String? value) => _isPaid(value);

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
      normalized == 'contado' ||
      normalized.contains('verificad') ||
      normalized.contains('aprob');
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
