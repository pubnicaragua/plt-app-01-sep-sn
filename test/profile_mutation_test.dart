import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/core/profile_mutation.dart';
import 'package:incoex_logistics_app/models/api_models.dart';

CompanyProfile profile({
  String id = 'profile-1',
  String username = 'ventas',
  String displayName = 'Ventas',
  String status = 'Activo',
}) {
  return CompanyProfile(
    id: id,
    accountId: 'account-1',
    username: username,
    displayName: displayName,
    role: 'operator',
    status: status,
  );
}

void main() {
  test('reconoce una creación que sí quedó guardada aunque falle la respuesta', () {
    expect(
      profileMutationReflected(
        profiles: [profile()],
        username: 'ventas',
        displayName: 'Ventas',
        expectedStatus: 'Activo',
      ),
      isTrue,
    );
  });

  test('reconoce el estado final de un perfil actualizado', () {
    expect(
      profileMutationReflected(
        profiles: [profile(status: 'Inactivo')],
        profileId: 'profile-1',
        expectedStatus: 'Inactivo',
      ),
      isTrue,
    );
  });
}
