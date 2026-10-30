bool canPayInvoicesForSession({
  required bool isSupervisor,
  required bool profilePermission,
}) {
  return isSupervisor || profilePermission;
}
