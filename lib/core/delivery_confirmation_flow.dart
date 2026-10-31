String deliveryConfirmationButtonLabel({
  required bool codeValidated,
  required bool evidenceUploaded,
}) {
  if (!codeValidated) return 'Validar código';
  if (!evidenceUploaded) return 'Agregar foto del paquete';
  return 'Registrar entrega';
}
