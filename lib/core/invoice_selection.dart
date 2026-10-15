Set<String> selectAllPendingInvoiceIds(Iterable<String> ids) => ids.toSet();

Set<String> togglePendingInvoiceSelection(Set<String> selected, String id) {
  final next = {...selected};
  if (!next.add(id)) next.remove(id);
  return next;
}
