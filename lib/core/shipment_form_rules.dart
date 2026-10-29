const cargoHelperNotice =
    'El conductor no se hace cargo de descargar. Se recomienda pedir un ayudante.';

bool requiresFirstPickupReference({
  required bool isShipping,
  required bool hasSavedReference,
  required String reference,
}) {
  return isShipping && !hasSavedReference && reference.trim().isEmpty;
}

String initialPickupName({
  required bool isSupervisor,
  required String? username,
  required String? savedName,
}) {
  final saved = savedName?.trim() ?? '';
  if (saved.isNotEmpty) return saved;
  if (isSupervisor) return '';
  return username?.trim() ?? '';
}

String? cargoHelperNoticeFor(String transport, String code) {
  if (transport != 'Camión' || code != 'cargo-helper') return null;
  return cargoHelperNotice;
}

String? cargoHelperCardMessage(String transport) {
  return cargoHelperNoticeFor(transport, 'cargo-helper');
}
