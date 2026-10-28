import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/screens/mi_perfil_cliente.dart';

void main() {
  test('valida los tres campos antes de cambiar la contraseña', () {
    expect(
      passwordChangeValidationError(
        currentPassword: '',
        newPassword: 'NuevaClave123',
        confirmation: 'NuevaClave123',
      ),
      'Ingresa tu contraseña actual.',
    );
    expect(
      passwordChangeValidationError(
        currentPassword: 'Actual123',
        newPassword: 'corta',
        confirmation: 'corta',
      ),
      'La nueva contraseña debe tener al menos 8 caracteres.',
    );
    expect(
      passwordChangeValidationError(
        currentPassword: 'Actual123',
        newPassword: 'NuevaClave123',
        confirmation: 'OtraClave123',
      ),
      'Las contraseñas nuevas no coinciden.',
    );
  });

  test('acepta una contraseña nueva válida', () {
    expect(
      passwordChangeValidationError(
        currentPassword: 'Actual123',
        newPassword: 'NuevaClave123',
        confirmation: 'NuevaClave123',
      ),
      isNull,
    );
  });
}
