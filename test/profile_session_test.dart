import 'package:flutter_test/flutter_test.dart';

import 'package:incoex_logistics_app/models/api_models.dart';
import 'package:incoex_logistics_app/screens/home_cliente.dart';

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
    expect(response.user.username, 'supervisor');
    expect(CompanyProfile.fromJson(response.profile).isSupervisor, isTrue);
  });

  test('conserva el username del perfil operativo para mostrarlo en el saludo',
      () {
    final response = LoginResponse.fromJson({
      'accessToken': 'token',
      'user': {
        'id': 'profile-user-1',
        'email': 'empresa@example.com',
        'role': 'corporate',
        'displayName': 'Ventas',
        'accountId': 'account-1',
        'profileId': 'profile-ventas-1',
        'profileRole': 'operator',
      },
      'profile': {
        'id': 'profile-ventas-1',
        'accountId': 'account-1',
        'username': 'leonel saravia',
        'displayName': 'Ventas',
        'role': 'operator',
        'status': 'Activo',
      },
    });

    expect(response.user.isSupervisor, isFalse);
    expect(response.user.username, 'leonel saravia');
  });

  test('el saludo usa username en perfiles y displayName en supervisor', () {
    const supervisor = SessionUser(
      id: '1',
      email: 'empresa@example.com',
      role: 'corporate',
      displayName: 'Logística Nica SA',
      username: 'supervisor',
      profileRole: 'supervisor',
    );
    const profile = SessionUser(
      id: '2',
      email: 'empresa@example.com',
      role: 'corporate',
      displayName: 'Ventas',
      username: 'leonel saravia',
      profileRole: 'operator',
    );

    expect(homeGreetingName(supervisor), 'Logística Nica SA');
    expect(homeGreetingName(profile), 'leonel saravia');
  });
}
