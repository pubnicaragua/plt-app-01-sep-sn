import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';

void main() {
  test('parsea el perfil activo del supervisor sin exponer contraseña', () {
    final response = LoginResponse.fromJson({
      'accessToken': 'token',
      'user': {
        'id': 'account-1',
        'email': 'empresa@example.com',
        'role': 'corporate',
        'displayName': 'Supervisor',
        'accountId': 'account-1',
        'profileId': 'profile-supervisor-account-1',
        'profileRole': 'supervisor',
      },
      'profile': {
        'id': 'profile-supervisor-account-1',
        'accountId': 'account-1',
        'username': 'supervisor',
        'displayName': 'Supervisor',
        'role': 'supervisor',
        'status': 'Activo',
        'passwordHash': 'no debe aparecer',
      },
    });

    expect(response.user.isSupervisor, isTrue);
    expect(response.user.profileId, 'profile-supervisor-account-1');
    expect(CompanyProfile.fromJson(response.profile).isSupervisor, isTrue);
  });
}
