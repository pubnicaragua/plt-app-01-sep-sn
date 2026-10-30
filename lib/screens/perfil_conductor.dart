import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';

String _profileDisplayValue(String? value, {bool feminine = false}) {
  final normalized = value?.trim() ?? '';
  if (normalized.isNotEmpty) return normalized;
  return feminine ? 'No registrada' : 'No registrado';
}

class PerfilConductorScreen extends StatefulWidget {
  const PerfilConductorScreen({super.key});

  @override
  State<PerfilConductorScreen> createState() => _PerfilConductorScreenState();
}

class _PerfilConductorScreenState extends State<PerfilConductorScreen> {
  SessionUser? get user => apiClient.currentUser;

  @override
  void initState() {
    super.initState();
    apiClient.refreshCurrentDriver(silent: true).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _editPersonalField({
    required String label,
    required String value,
    required Future<SessionUser> Function(String value) save,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(
        text:
            value == 'No registrado' || value == 'No registrada' ? '' : value);
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF102B6B),
        title: Text('Editar $label',
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontFamily: 'Figtree'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFFB9D4FF)),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x6687B7FF))),
            focusedBorder:
                const UnderlineInputBorder(borderSide: BorderSide(color: cyan)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFFB9D4FF))),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: accentBlue),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || edited == null || edited == value) return;
    if (label != 'Vencimiento' && edited.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa el valor antes de guardar.')));
      return;
    }
    try {
      await save(edited);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label actualizado.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final vehicleLabel = user?.vehicle?.trim().isNotEmpty == true
        ? user!.vehicle!
        : 'Vehículo no asignado';
    final vehiclePlate = user?.plate?.trim().isNotEmpty == true
        ? user!.plate!
        : 'Placa pendiente';
    return ColoredBox(
      color: const Color(0xFF0D1F52),
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('Mi perfil',
                style: TextStyle(
                    fontFamily: 'Figtree', fontWeight: FontWeight.w800)),
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _ProfileHeader(name: currentUser?.displayName ?? 'Conductor'),
                const SizedBox(height: 16),
                _ProfileSection(title: 'Información personal', rows: [
                  _ProfileRow(
                    Icons.person_outline_rounded,
                    'Nombre',
                    _profileDisplayValue(currentUser?.displayName),
                    onEdit: () => _editPersonalField(
                      label: 'Nombre',
                      value: currentUser?.displayName ?? '',
                      save: (value) =>
                          apiClient.updateCurrentDriver(name: value),
                    ),
                  ),
                  _ProfileRow(
                    Icons.phone_outlined,
                    'Teléfono',
                    _profileDisplayValue(currentUser?.phone),
                    onEdit: () => _editPersonalField(
                      label: 'Teléfono',
                      value: currentUser?.phone ?? '',
                      keyboardType: TextInputType.phone,
                      save: (value) =>
                          apiClient.updateCurrentDriver(phone: value),
                    ),
                  ),
                  _ProfileRow(
                    Icons.badge_outlined,
                    'Licencia',
                    _profileDisplayValue(currentUser?.licenseNumber,
                        feminine: true),
                    onEdit: () => _editPersonalField(
                      label: 'Licencia',
                      value: currentUser?.licenseNumber ?? '',
                      save: (value) =>
                          apiClient.updateCurrentDriver(licenseNo: value),
                    ),
                  ),
                  _ProfileRow(
                    Icons.event_outlined,
                    'Vencimiento',
                    _profileDisplayValue(currentUser?.licenseExpiry),
                    onEdit: () => _editPersonalField(
                      label: 'Vencimiento',
                      value: currentUser?.licenseExpiry ?? '',
                      keyboardType: TextInputType.datetime,
                      save: (value) =>
                          apiClient.updateCurrentDriver(licenseExp: value),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _ProfileSection(title: 'Vehículo asignado', rows: [
                  _ProfileRow(Icons.directions_car_outlined, 'Tipo',
                      user?.vehicleType ?? vehicleLabel),
                  _ProfileRow(Icons.confirmation_number_outlined, 'Placa',
                      vehiclePlate),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => ShowcaseGlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Row(children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0D47D9),
            child: Text(initials(name),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree')),
        ]),
      );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.rows});
  final String title;
  final List<_ProfileRow> rows;

  @override
  Widget build(BuildContext context) => ShowcaseGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        borderRadius: 18,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree')),
          const SizedBox(height: 8),
          ...rows,
        ]),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(this.icon, this.label, this.value, {this.onEdit});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'No registrado' || value == 'No registrada';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB9D4FF),
                fontFamily: 'Figtree',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isPlaceholder
                          ? Colors.white.withValues(alpha: .48)
                          : Colors.white,
                      fontWeight:
                          isPlaceholder ? FontWeight.w500 : FontWeight.w700,
                      fontFamily: 'Figtree',
                    ),
                  ),
                ),
                if (onEdit != null)
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      onPressed: onEdit,
                      tooltip: 'Editar $label',
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined,
                          color: cyan, size: 17),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
