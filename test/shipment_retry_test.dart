import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/shipment_retry.dart';

void main() {
  test('a retry reuses an already-created trip instead of creating another', () {
    expect(shouldCreateShipmentTrip(null), isTrue);
    expect(shouldCreateShipmentTrip(''), isTrue);
    expect(shouldCreateShipmentTrip('#4810'), isFalse);
  });
}
