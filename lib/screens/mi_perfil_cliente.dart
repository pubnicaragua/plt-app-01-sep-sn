import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/notifications_sheet.dart';
import 'inicio.dart';
import 'pedido.dart';

class MiPerfilCliente extends StatefulWidget {
  const MiPerfilCliente({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MiPerfilCliente> createState() => _MiPerfilClienteState();
}

class _MiPerfilClienteState extends State<MiPerfilCliente> {
  late Future<_ProfileData> profile;

  @override
  void initState() {
    super.initState();
    profile = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final user = apiClient.currentUser;
    final clients = await apiClient.getClients();
    final email = user?.email.trim().toLowerCase() ?? '';
    final displayName = user?.companyName?.trim().isNotEmpty == true
        ? user!.companyName!.trim()
        : user?.displayName.trim() ?? 'INCOEX Logistics';
    Map<String, dynamic>? client;
    for (final candidate in clients) {
      final candidateEmail = candidate['email']?.toString().trim().toLowerCase();
      final candidateName = candidate['name']?.toString().trim().toLowerCase();
      if (candidateEmail == email || candidateName == displayName.toLowerCase()) {
        client = candidate;
        break;
      }
    }
    final companyName = client?['name']?.toString().trim().isNotEmpty == true
        ? client!['name'].toString().trim()
        : displayName;
    final trips = await apiClient.getTrips(client: companyName);
    return _ProfileData(
      clientId: client?['id']?.toString() ?? '',
      companyName: companyName,
      contactName: client?['contact']?.toString() ?? user?.displayName ?? '',
      email: client?['email']?.toString() ?? user?.email ?? '',
      phone: client?['phone']?.toString() ?? user?.phone ?? '',
      address: client?['address']?.toString() ?? '',
      taxId: client?['taxId']?.toString() ?? '',
      trips: trips,
    );
  }

  Future<void> _editProfile(_ProfileData data) async {
    if (data.clientId.isEmpty) {
      _showMessage('No hay una empresa asociada a esta cuenta todavía.');
      return;
    }
    final name = TextEditingController(text: data.companyName);
    final email = TextEditingController(text: data.email);
    final phone = TextEditingController(text: data.phone);
    var saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132D70).withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: .3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          'Editar perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        const SizedBox(height: 14),
                        GlassField(
                          label: 'Nombre de la empresa',
                          icon: Icons.business_outlined,
                          controller: name,
                          showFloatingLabel: false,
                        ),
                        const SizedBox(height: 10),
                        GlassField(
                          label: 'Correo electrónico',
                          icon: Icons.mail_outline_rounded,
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          showFloatingLabel: false,
                        ),
                        const SizedBox(height: 10),
                        GlassField(
                          label: 'Celular / WhatsApp',
                          icon: Icons.phone_outlined,
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          showFloatingLabel: false,
                        ),
                        const SizedBox(height: 14),
                        GlassButton(
                          label: saving ? 'Guardando…' : 'Guardar cambios',
                          filled: true,
                          onPressed: saving
                              ? () {}
                              : () async {
                                  if (name.text.trim().isEmpty ||
                                      email.text.trim().isEmpty) {
                                    _showMessage('Completa nombre y correo.');
                                    return;
                                  }
                                  setSheetState(() => saving = true);
                                  try {
                                    await apiClient.updateClient(
                                      data.clientId,
                                      name: name.text.trim(),
                                      email: email.text.trim(),
                                      phone: phone.text.trim(),
                                    );
                                    final current = apiClient.currentUser;
                                    if (current != null) {
                                      apiClient.currentUser = SessionUser(
                                        id: current.id,
                                        email: email.text.trim(),
                                        role: current.role,
                                        displayName: name.text.trim(),
                                        vehicle: current.vehicle,
                                        plate: current.plate,
                                        phone: phone.text.trim(),
                                        companyName: name.text.trim(),
                                      );
                                    }
                                    if (!mounted) return;
                                    Navigator.of(sheetContext).pop();
                                    setState(() => profile = _loadProfile());
                                  } on ApiException catch (error) {
                                    setSheetState(() => saving = false);
                                    _showMessage(error.message);
                                  } catch (_) {
                                    setSheetState(() => saving = false);
                                    _showMessage('No se pudieron guardar los cambios.');
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    name.dispose();
    email.dispose();
    phone.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() {
    apiClient.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Inicio()),
      (_) => false,
    );
  }

  Future<void> _openSupport() async {
    const phone = '50584205489';
    const message =
        'Hola, necesito soporte empresarial para mi cuenta de INCOEX.';
    final encoded = Uri.encodeComponent(message);
    final whatsapp = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    final web = Uri.parse('https://wa.me/$phone?text=$encoded');
    if (await launchUrl(whatsapp, mode: LaunchMode.externalApplication)) return;
    if (await launchUrl(web, mode: LaunchMode.externalApplication)) return;
    _showMessage('No se pudo abrir WhatsApp en este dispositivo.');
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      bottom: false,
      child: FutureBuilder<_ProfileData>(
        future: profile,
        builder: (context, snapshot) {
          final data = snapshot.data ?? _ProfileData.empty(apiClient.currentUser);
          final loading = snapshot.connectionState == ConnectionState.waiting;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _ProfileHeader(
                embedded: widget.embedded,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 22),
              _HeroCard(
                data: data,
                loading: loading,
                onEdit: () => _editProfile(data),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ProfileShortcut(
                      icon: Icons.credit_card_outlined,
                      label: 'Métodos de\nPago\nCorporativos',
                      onTap: () => _showMessage('Métodos de pago corporativos.'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProfileShortcut(
                      icon: Icons.description_outlined,
                      label: 'Historial de\nEnvíos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MisEnvios()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsCard(onLogout: _logout, onSupport: _openSupport),
            ],
          );
        },
      ),
    );
    return widget.embedded ? content : Scaffold(body: AppBackground(child: content));
  }
}

class _ProfileData {
  const _ProfileData({
    required this.clientId,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.trips,
  });

  final String clientId;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final String taxId;
  final List<Trip> trips;

  List<String> get missingSteps {
    final missing = <String>[];
    if (clientId.isEmpty) missing.add('vinculación de empresa');
    if (contactName.trim().isEmpty) missing.add('persona de contacto');
    if (phone.trim().isEmpty) missing.add('celular / WhatsApp');
    if (email.trim().isEmpty) missing.add('correo electrónico');
    if (address.trim().isEmpty) missing.add('dirección');
    if (taxId.trim().isEmpty) missing.add('RUC');
    return missing;
  }

  factory _ProfileData.empty(SessionUser? user) => _ProfileData(
        clientId: '',
        companyName: user?.companyName ?? user?.displayName ?? 'INCOEX Logistics',
        contactName: user?.displayName ?? '',
        email: user?.email ?? '',
        phone: user?.phone ?? '',
        address: '',
        taxId: '',
        trips: const [],
      );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.embedded, required this.onBack});

  final bool embedded;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 42, height: 42),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .06),
            shape: const CircleBorder(),
            side: BorderSide(color: Colors.white.withValues(alpha: .24)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Perfil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
        InkWell(
          onTap: () => showAppNotifications(context),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Image.asset(
              'assets/img/HomeCliente/notificaciones.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data, required this.loading, required this.onEdit});

  final _ProfileData data;
  final bool loading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final missing = data.missingSteps;
    final completionText = loading
        ? 'Consultando información del perfil…'
        : missing.isEmpty
            ? 'Perfil empresarial completo'
            : 'Te falta completar: ${missing.take(2).join(' y ')}${missing.length > 2 ? '…' : ''}';
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 10),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const BrandLockup(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            data.companyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 9),
          const _ProfilePill(
            icon: Icons.business_outlined,
            text: 'Perfil de Empresa',
          ),
          const SizedBox(height: 18),
          Text(
            loading
                ? 'Consultando envíos…'
                : '(${_formatNumber(data.trips.length)} Envíos Realizados)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 9),
          _ProfilePill(
            icon: Icons.edit_outlined,
            text: 'Editar Perfil',
            onTap: onEdit,
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: accentBlue,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: cyan.withValues(alpha: .38)),
              ),
              child: Text(
                completionText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .27)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 7),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileShortcut extends StatelessWidget {
  const _ProfileShortcut({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(15, 14, 10, 15),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: accentBlue.withValues(alpha: .38),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .3)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 13),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.08,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onLogout, required this.onSupport});

  final VoidCallback onLogout;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 6),
      child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: appDarkMode,
            builder: (context, dark, _) => Row(
              children: [
                const _SettingsIcon(icon: Icons.dark_mode_outlined),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo Oscuro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                      Text(
                        'Cambiar la apariencia visual de la app',
                        style: TextStyle(
                          color: Color(0xFFB9D4FF),
                          fontSize: 11,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: dark,
                  activeTrackColor: accentBlue,
                  activeThumbColor: Colors.white,
                  onChanged: (value) => appDarkMode.value = value,
                ),
              ],
            ),
          ),
          const Divider(color: Color(0x66FFFFFF), height: 22),
          _SettingsRow(
            icon: Icons.help_outline_rounded,
            title: 'Soporte Empresarial',
            onTap: onSupport,
          ),
          const Divider(color: Color(0x66FFFFFF), height: 22),
          _SettingsRow(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            danger: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .3)),
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: danger ? const Color(0xFFFF5C63) : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: danger ? const Color(0xFFFF5C63) : Colors.white70),
        ],
      ),
    );
  }
}

String _formatNumber(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
