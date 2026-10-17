const shipmentCashStatus = 'Contado';
const shipmentCreditStatus = 'Crédito';

List<String> shipmentPaymentMethodsFor(String status) {
  if (status.trim().toLowerCase() == shipmentCashStatus.toLowerCase()) {
    return const ['Tarjeta'];
  }
  return const ['Efectivo', 'Transferencia'];
}

bool shipmentPaymentIsImmediate(String status) =>
    status.trim().toLowerCase() == shipmentCashStatus.toLowerCase();
