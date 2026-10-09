import '../models/api_models.dart';

class InvoiceBreakdownLine {
  const InvoiceBreakdownLine({
    required this.label,
    required this.amountCs,
    this.suffix,
  });

  final String label;
  final double amountCs;
  final String? suffix;
}

class InvoiceBreakdown {
  const InvoiceBreakdown({
    required this.baseLabel,
    required this.lines,
    required this.shippingSubtotalCs,
    required this.totalCs,
  });

  final String baseLabel;
  final List<InvoiceBreakdownLine> lines;
  final double shippingSubtotalCs;
  final double totalCs;
}

InvoiceBreakdown buildInvoiceBreakdown({
  required String serviceMode,
  required String transport,
  required double shippingCs,
  required double baseCs,
  required double serviceCs,
  required double additionalCs,
  required int weight,
  required String weightUnit,
  required double invoiceAmountCs,
  required bool invoiceAlreadyPaid,
  required List<TripOptionSelection> options,
  double dollarRate = 36.5,
}) {
  final isTrip = _normalized(serviceMode) == 'taxi privado' ||
      _normalized(serviceMode) == 'viaje' ||
      _normalized(serviceMode) == 'viajes';
  final isCargo = _normalized(transport) == 'camion' ||
      _normalized(serviceMode) == 'carga';
  final baseLabel = isTrip
      ? 'Tarifa base de viaje'
      : isCargo
          ? 'Tarifa base de carga'
          : 'Tarifa base de envío';

  final lines = <InvoiceBreakdownLine>[];
  if (!isTrip) {
    lines.add(InvoiceBreakdownLine(
      label: 'Factura',
      amountCs: invoiceAmountCs,
      suffix: invoiceAlreadyPaid ? 'Pagado' : null,
    ));
  }
  lines.add(InvoiceBreakdownLine(label: baseLabel, amountCs: baseCs));
  lines.add(InvoiceBreakdownLine(
    label: 'Servicio y gestión logística',
    amountCs: serviceCs,
  ));
  if (!isTrip) {
    lines.add(InvoiceBreakdownLine(
      label: isCargo
          ? 'Carga adicional ($weight $weightUnit)'
          : 'Distancia adicional',
      amountCs: additionalCs,
    ));
  }

  var optionsTotalCs = 0.0;
  for (final option in options) {
    final amountCs = option.currency.toUpperCase() == 'USD'
        ? option.priceCs * dollarRate
        : option.priceCs;
    final quantity = option.quantity < 1 ? 1 : option.quantity;
    final totalOptionCs = amountCs * quantity;
    optionsTotalCs += totalOptionCs;
    lines.add(InvoiceBreakdownLine(
      label: quantity == 1 ? option.title : '${option.title} (x$quantity)',
      amountCs: totalOptionCs,
    ));
  }

  final shippingSubtotalCs = shippingCs + optionsTotalCs;
  final productToCollect = isTrip || invoiceAlreadyPaid ? 0 : invoiceAmountCs;
  return InvoiceBreakdown(
    baseLabel: baseLabel,
    lines: lines,
    shippingSubtotalCs: shippingSubtotalCs,
    totalCs: shippingSubtotalCs + productToCollect,
  );
}

String _normalized(String value) =>
    value.trim().toLowerCase().replaceAll('á', 'a').replaceAll('ó', 'o');
