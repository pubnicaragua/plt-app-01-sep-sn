import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/profile_mutation.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'home_cliente.dart';

class PerfilesEmpresaScreen extends StatefulWidget {
  const PerfilesEmpresaScreen({super.key});

  @override
  State<PerfilesEmpresaScreen> createState() => _PerfilesEmpresaScreenState();
}

class _PerfilesEmpresaScreenState extends State<PerfilesEmpresaScreen> {
  late Future<List<CompanyProfile>> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = apiClient.getCompanyProfiles();
  }

  Future<List<CompanyProfile>?> _reload() async {
    try {
      final profiles = await apiClient.getCompanyProfiles();
      if (mounted) {
        setState(() {
          _profiles = Future.value(profiles);
        });
      }
      return profiles;
    } catch (_) {
      return null;
    }
  }

  Future<void> _createProfile() async {
    final result = await _profileDialog();
    if (!mounted || result == null) return;
    try {
      final created = await apiClient.createCompanyProfile(
        username: result.username,
        displayName: result.displayName,
        password: result.password,
      );
      if (!mounted) return;
      setState(() {
        _profiles = _profiles.then((profiles) {
          final index =
              profiles.indexWhere((profile) => profile.id == created.id);
          if (index >= 0) {
            return [...profiles]..[index] = created;
          }
          return [...profiles, created];
        });
      });
      _message('Perfil creado correctamente.');
    } on ApiException catch (error) {
      await _recoverCreate(result, error.message);
    } catch (_) {
      await _recoverCreate(result, 'No se pudo crear el perfil.');
    }
  }

  Future<void> _recoverCreate(
    _ProfileFormResult result,
    String errorMessage,
  ) async {
    try {
      final profiles = await _reload();
      if (profiles != null &&
          profileMutationReflected(
            profiles: profiles,
            username: result.username,
            displayName: result.displayName,
            expectedStatus: 'Activo',
          )) {
        _message('Perfil creado correctamente.');
        return;
      }
    } catch (_) {
      // Keep the original error when the verification request also fails.
    }
    _message(errorMessage);
  }

  Future<void> _toggleProfile(CompanyProfile profile) async {
    final nextStatus = profile.status == 'Activo' ? 'Inactivo' : 'Activo';
    try {
      final updated = await apiClient.updateCompanyProfile(
        profile.id,
        status: nextStatus,
      );
      if (!mounted) return;
      setState(() {
        _profiles = _profiles.then((profiles) {
          final index = profiles.indexWhere((item) => item.id == updated.id);
          if (index < 0) return profiles;
          return [...profiles]..[index] = updated;
        });
      });
      _message(
          nextStatus == 'Activo' ? 'Perfil activado.' : 'Perfil desactivado.');
    } on ApiException catch (error) {
      await _recoverToggle(profile, nextStatus, error.message);
    } catch (_) {
      await _recoverToggle(
        profile,
        nextStatus,
        'No se pudo actualizar el perfil.',
      );
    }
  }

  Future<void> _toggleInvoicePermission(CompanyProfile profile) async {
    final nextPermission = !profile.canPayInvoices;
    try {
      final updated = await apiClient.updateCompanyProfile(
        profile.id,
        canPayInvoices: nextPermission,
      );
      if (!mounted) return;
      setState(() {
        _profiles = _profiles.then((profiles) {
          final index = profiles.indexWhere((item) => item.id == updated.id);
          if (index < 0) return profiles;
          return [...profiles]..[index] = updated;
        });
      });
      _message(nextPermission
          ? 'El perfil puede pagar facturas.'
          : 'El perfil ya no puede pagar facturas.');
    } on ApiException catch (error) {
      await _recoverInvoicePermission(profile, nextPermission, error.message);
    } catch (_) {
      await _recoverInvoicePermission(
        profile,
        nextPermission,
        'No se pudo actualizar el permiso de facturas.',
      );
    }
  }

  Future<void> _handleProfileAction(
    CompanyProfile profile,
    String action,
  ) async {
    if (action == 'status') {
      await _toggleProfile(profile);
    } else if (action == 'invoices') {
      await _toggleInvoicePermission(profile);
    }
  }

  Future<void> _recoverInvoicePermission(
    CompanyProfile profile,
    bool expectedPermission,
    String errorMessage,
  ) async {
    try {
      final profiles = await _reload();
      if (profiles != null &&
          profileMutationReflected(
            profiles: profiles,
            profileId: profile.id,
            expectedCanPayInvoices: expectedPermission,
          )) {
        _message(expectedPermission
            ? 'El perfil puede pagar facturas.'
            : 'El perfil ya no puede pagar facturas.');
        return;
      }
    } catch (_) {
      // Keep the original error when the verification request also fails.
    }
    _message(errorMessage);
  }

  Future<void> _recoverToggle(
    CompanyProfile profile,
    String expectedStatus,
    String errorMessage,
  ) async {
    try {
      final profiles = await _reload();
      if (profiles != null &&
          profileMutationReflected(
            profiles: profiles,
            profileId: profile.id,
            expectedStatus: expectedStatus,
          )) {
        _message(expectedStatus == 'Activo'
            ? 'Perfil activado.'
            : 'Perfil desactivado.');
        return;
      }
    } catch (_) {
      // Keep the original error when the verification request also fails.
    }
    _message(errorMessage);
  }

  Future<void> _enterProfile(CompanyProfile profile) async {
    final password = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF102965),
        title: Text(
          'Entrar como ${profile.displayName}',
          style: const TextStyle(color: Colors.white, fontFamily: 'Figtree'),
        ),
        content: _ProfileTextField(
          controller: password,
          label: 'Contraseña del perfil',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
    final value = password.text;
    password.dispose();
    if (!mounted || accepted != true || value.isEmpty) return;
    try {
      await apiClient.login(
        email: apiClient.currentUser?.email ?? '',
        password: value,
        role: 'company',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeCliente()),
        (_) => false,
      );
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('No se pudo abrir el perfil.');
    }
  }

  Future<_ProfileFormResult?> _profileDialog() {
    final username = TextEditingController();
    final displayName = TextEditingController();
    final password = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<_ProfileFormResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF102965),
        title: const Text(
          'Crear perfil',
          style: TextStyle(color: Colors.white, fontFamily: 'Figtree'),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileTextField(
                  controller: displayName,
                  label: 'Nombre del perfil',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                _ProfileTextField(
                  controller: username,
                  label: 'Nombre de usuario',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 10),
                _ProfileTextField(
                  controller: password,
                  label: 'Contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'La contraseña debe tener al menos 8 caracteres y ser única para este perfil.',
                  style: TextStyle(
                    color: Color(0xBFFFFFFF),
                    fontSize: 11,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (displayName.text.trim().isEmpty ||
                  username.text.trim().isEmpty ||
                  password.text.length < 8) {
                return;
              }
              Navigator.of(dialogContext).pop(
                _ProfileFormResult(
                  username: username.text.trim(),
                  displayName: displayName.text.trim(),
                  password: password.text,
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Perfiles de empresa',
          style: TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w800),
        ),
      ),
      body: AppBackground(
        child: FutureBuilder<List<CompanyProfile>>(
          future: _profiles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'No se pudieron cargar los perfiles.',
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'Figtree'),
                ),
              );
            }
            final profiles = snapshot.data ?? const <CompanyProfile>[];
            return RefreshIndicator(
              onRefresh: () async {
                await _reload();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 68, 18, 32),
                children: [
                  const Text(
                    'Administra quién puede operar esta cuenta.',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF), fontFamily: 'Figtree'),
                  ),
                  const SizedBox(height: 16),
                  for (final profile in profiles) ...[
                    _ProfileCard(
                      profile: profile,
                      onToggle: profile.isSupervisor
                          ? null
                          : () => _toggleProfile(profile),
                      onAction: profile.isSupervisor
                          ? null
                          : (action) => _handleProfileAction(profile, action),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 8),
                  GlassButton(
                    label: 'Crear perfil',
                    filled: true,
                    onPressed: _createProfile,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileFormResult {
  const _ProfileFormResult({
    required this.username,
    required this.displayName,
    required this.password,
  });

  final String username;
  final String displayName;
  final String password;
}

class _ProfileTextField extends StatefulWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;

  @override
  State<_ProfileTextField> createState() => _ProfileTextFieldState();
}

class _ProfileTextFieldState extends State<_ProfileTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      style: const TextStyle(color: Colors.white, fontFamily: 'Figtree'),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: Color(0xD9FFFFFF)),
        prefixIcon: Icon(widget.icon, color: Colors.white70),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip:
                    _obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentBlue),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    this.onToggle,
    this.onAction,
  });

  final CompanyProfile profile;
  final VoidCallback? onToggle;
  final void Function(String action)? onAction;

  @override
  Widget build(BuildContext context) {
    final active = profile.status == 'Activo';
    return AppGlassSurface(
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: active ? accentBlue : Colors.white24,
              child:
                  const Icon(Icons.person_outline_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Figtree'),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '@${profile.username} · ${profile.isSupervisor ? 'Supervisor' : profile.status}',
                    style: const TextStyle(
                        color: Color(0xBFFFFFFF), fontFamily: 'Figtree'),
                  ),
                ],
              ),
            ),
            if (onToggle == null)
              const Icon(Icons.verified_rounded, color: Color(0xFF1CDB83))
            else
              PopupMenuButton<String>(
                tooltip: 'Acciones del perfil',
                onSelected: onAction,
                color: const Color(0xFF102965),
                position: PopupMenuPosition.under,
                offset: const Offset(-80, 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.more_vert_rounded,
                    color: Colors.white, size: 24),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'status',
                    child: _ProfileActionItem(
                      label: 'Perfil activo',
                      value: active,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'invoices',
                    child: _ProfileActionItem(
                      label: 'Permitir pagar facturas',
                      value: profile.canPayInvoices,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  const _ProfileActionItem({
    required this.label,
    required this.value,
  });

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 190),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          IgnorePointer(
            child: Transform.scale(
              scale: .84,
              child: Switch(
                value: value,
                onChanged: (_) {},
                activeTrackColor: const Color(0xFF19D27D),
                activeThumbColor: Colors.white,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white38,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
