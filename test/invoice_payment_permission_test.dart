import 'package:flutter_test/flutter_test.dart';
import 'package:incoex_logistics_app/core/invoice_payment_permission.dart';

void main() {
  test('el supervisor puede pagar aunque no tenga la bandera del perfil', () {
    expect(
      canPayInvoicesForSession(isSupervisor: true, profilePermission: false),
      isTrue,
    );
  });

  test('un perfil operativo solo puede pagar con permiso explícito', () {
    expect(
      canPayInvoicesForSession(isSupervisor: false, profilePermission: true),
      isTrue,
    );
    expect(
      canPayInvoicesForSession(isSupervisor: false, profilePermission: false),
      isFalse,
    );
  });
}
