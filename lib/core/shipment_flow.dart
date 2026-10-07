enum ShipmentCompletionRoute {
  tracking,
  assignment,
}

ShipmentCompletionRoute completionRouteForShipment({
  required bool isScheduled,
}) {
  return isScheduled
      ? ShipmentCompletionRoute.assignment
      : ShipmentCompletionRoute.tracking;
}
