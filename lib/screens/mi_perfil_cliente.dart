import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/notifications_sheet.dart';
import 'inicio.dart';

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
      final candidateEmail =
          candidate['email']?.toString().trim().toLowerCase();
      final candidateName = candidate['name']?.toString().trim().toLowerCase();
      if (candidateEmail == email ||
          candidateName == displayName.toLowerCase()) {
        client = candidate;
        break;
      }
    }
    final companyName = client?['name']?.toString().trim().isNotEmpty == true
        ? client!['name'].toString().trim()
        : displayName;
    return _ProfileData(
      clientId: client?['id']?.toString() ?? '',
      companyName: companyName,
      contactName: client?['contact']?.toString() ?? user?.displayName ?? '',
      email: client?['email']?.toString() ?? user?.email ?? '',
      phone: client?['phone']?.toString() ?? user?.phone ?? '',
      address: client?['address']?.toString() ?? '',
      taxId: client?['taxId']?.toString() ?? '',
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
                      border:
                          Border.all(color: Colors.white.withValues(alpha: .3)),
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
                            fontFamily: 'Figtree',
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
                                    _showMessage(
                                        'No se pudieron guardar los cambios.');
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          final data =
              snapshot.data ?? _ProfileData.empty(apiClient.currentUser);
          final loading = snapshot.connectionState == ConnectionState.waiting;
          return ListView(
            padding: const EdgeInsets.fromLTRB(17, 14, 17, 104),
            children: [
              _HeroCard(
                data: data,
                loading: loading,
                onEdit: () => _editProfile(data),
              ),
              const SizedBox(height: 12),
              _ProfileActionsCard(
                onPayments: () => _showMessage('Métodos de pago corporativos.'),
                onNotifications: () => showAppNotifications(context),
                onSupport: _openSupport,
              ),
              const SizedBox(height: 10),
              _LogoutCard(onTap: _logout),
            ],
          );
        },
      ),
    );
    return widget.embedded
        ? content
        : Scaffold(body: AppBackground(child: content));
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
  });

  final String clientId;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final String taxId;
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
        companyName:
            user?.companyName ?? user?.displayName ?? 'INCOEX Logistics',
        contactName: user?.displayName ?? '',
        email: user?.email ?? '',
        phone: user?.phone ?? '',
        address: '',
        taxId: '',
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.data,
    required this.loading,
    required this.onEdit,
  });

  final _ProfileData data;
  final bool loading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final missing = data.missingSteps;
    final name = data.contactName.trim().isNotEmpty
        ? data.contactName.trim()
        : data.companyName;
    final completionText = loading
        ? 'Consultando información del perfil…'
        : missing.isEmpty
            ? 'Perfil empresarial completo'
            : 'Te falta completar: ${missing.take(2).join(' y ')}'
                '${missing.length > 2 ? '…' : ''}';
    return _ProfileGlassPanel(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 16),
      borderRadius: 24,
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentBlue.withValues(alpha: .72),
              border: Border.all(color: Colors.white.withValues(alpha: .38)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 29,
                fontWeight: FontWeight.w700,
                fontFamily: 'Figtree',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFamily: 'Figtree',
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: const [
              _ProfileBadge(text: 'Perfil de Empresa'),
              _ProfileBadge(text: 'Cliente VIP'),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0x99101D4C),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Colors.white.withValues(alpha: .13)),
              ),
              child: Text(
                completionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x99101D4C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Figtree',
        ),
      ),
    );
  }
}

class _ProfileActionsCard extends StatelessWidget {
  const _ProfileActionsCard({
    required this.onPayments,
    required this.onNotifications,
    required this.onSupport,
  });

  final VoidCallback onPayments;
  final VoidCallback onNotifications;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return _ProfileGlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      borderRadius: 23,
      child: Column(
        children: [
          _ProfileActionRow(
            iconAsset: 'assets/img/HomeCliente/perfil_pago.png',
            title: 'Métodos de pago',
            onTap: onPayments,
          ),
          const _ProfileActionDivider(),
          _ProfileActionRow(
            iconAsset: 'assets/img/HomeCliente/perfil_notificaciones.png',
            title: 'Notificaciones',
            onTap: onNotifications,
          ),
          const _ProfileActionDivider(),
          _ProfileActionRow(
            iconAsset: 'assets/img/HomeCliente/perfil_soporte.png',
            title: 'Soporte empresarial',
            onTap: onSupport,
          ),
        ],
      ),
    );
  }
}

class _ProfileActionDivider extends StatelessWidget {
  const _ProfileActionDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: .38),
      );
}

class _ProfileActionRow extends StatelessWidget {
  const _ProfileActionRow({
    required this.iconAsset,
    required this.title,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 55,
        child: Row(
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: 33,
                  height: 33,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0863D7).withValues(alpha: .82),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .32)),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    iconAsset,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Figtree',
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 25),
          ],
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF9F2449),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5E8ED),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/img/HomeCliente/perfil_logout.png',
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGlassPanel extends StatelessWidget {
  const _ProfileGlassPanel({
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        foregroundPainter: _ProfileGlassEdgePainter(radius: borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                offset: Offset(1, 5),
                blurRadius: 4.7,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ProfileGlassEdgePainter extends CustomPainter {
  const _ProfileGlassEdgePainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x7AFFFFFF),
          Color(0x1AFFFFFF),
          Color(0x667EA5D8),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(.6), Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileGlassEdgePainter oldDelegate) =>
      oldDelegate.radius != radius;
}
