import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/invoice_selection.dart';

void main() {
  test('selects all pending invoices and allows individual deselection', () {
    const pending = ['#4810', '#4812'];

    expect(selectAllPendingInvoiceIds(pending), equals({'#4810', '#4812'}));

    final updated = togglePendingInvoiceSelection(
      {'#4810', '#4812'},
      '#4812',
    );
    expect(updated, equals({'#4810'}));
  });
}
