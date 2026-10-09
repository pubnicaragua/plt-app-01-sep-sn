const shipmentCashStatus = 'Contado';
const shipmentCreditStatus = 'Crédito';

List<String> shipmentPaymentMethodsFor(String status) {
  if (status.trim().toLowerCase() == shipmentCashStatus.toLowerCase()) {
    return const ['Efectivo', 'Transferencia', 'Tarjeta'];
  }
  return const ['Transferencia', 'Tarjeta'];
}

bool shipmentPaymentIsImmediate(String status) =>
    status.trim().toLowerCase() == shipmentCashStatus.toLowerCase();
