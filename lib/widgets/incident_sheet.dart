import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../core/theme.dart';
import 'glass.dart';

Future<IncidentResult?> showIncidentSheet(
  BuildContext context, {
  required String tripId,
  required String driverName,
  required String clientName,
}) {
  return showModalBottomSheet<IncidentResult>(
    context: context,
    backgroundColor: const Color(0xFF0B1D4D),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _IncidentSheet(
      tripId: tripId,
      driverName: driverName,
      clientName: clientName,
    ),
  );
}

class IncidentResult {
  const IncidentResult({required this.id});
  final String id;
}

class _IncidentSheet extends StatefulWidget {
  const _IncidentSheet({
    required this.tripId,
    required this.driverName,
    required this.clientName,
  });

  final String tripId;
  final String driverName;
  final String clientName;

  @override
  State<_IncidentSheet> createState() => _IncidentSheetState();
}

class _IncidentSheetState extends State<_IncidentSheet> {
  static const priorities = ['Baja', 'Media', 'Alta', 'Crítica'];
  static const types = [
    'Cliente ausente',
    'Problema con dirección',
    'Retraso',
    'Paquete dañado',
    'Falla de vehículo',
    'Trafico / ruta bloqueada',
    'Otro',
  ];

  String type = 'Cliente ausente';
  String priority = 'Media';
  final description = TextEditingController();
  double? latitude;
  double? longitude;
  String? evidenceUrl;
  String? evidenceFile;
  Uint8List? evidenceBytes;
  bool locating = false;
  bool uploading = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _locate();
    description.text = 'Vestíbulo cerrado, no está el encargado. No se pudo entregar el paquete ${widget.tripId}.';
  }

  Future<void> _locate() async {
    setState(() => locating = true);
    final loc = await requestCurrentLocation();
    if (!mounted) return;
    setState(() {
      latitude = loc?.latitude;
      longitude = loc?.longitude;
      locating = false;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        evidenceBytes = bytes;
        evidenceFile = image.name;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No se pudo tomar la foto.',
              style: TextStyle(fontFamily: 'Acumin Pro'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (sending) return;
    setState(() => sending = true);
    try {
      if (evidenceBytes != null) {
        final uploaded = await apiClient.uploadEvidence(
          evidenceBytes!,
          evidenceFile ?? 'evidencia.jpg',
        );
        evidenceFile = uploaded['evidence']?.toString();
        evidenceUrl = uploaded['url']?.toString();
      }
      await apiClient.reportIncident(
        type: type,
        client: widget.clientName,
        trip: widget.tripId,
        driver: widget.driverName,
        priority: priority,
        description: description.text.trim(),
        latitude: latitude,
        longitude: longitude,
        evidence: evidenceFile,
      );
      if (!mounted) return;
      Navigator.of(context).pop(const IncidentResult(id: ''));
    } catch (_) {
      if (mounted) {
        setState(() => sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No se pudo reportar. Verifica tu conexión.',
              style: TextStyle(fontFamily: 'Acumin Pro'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        decoration: const BoxDecoration(
          color: Color(0xFF0B1D4D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.report_problem_rounded,
                      color: Color(0xFFFFB4B4), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Reportar incidencia',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Viaje ${widget.tripId} · ${widget.driverName}',
                style: const TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 11.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: glassBorder),
                ),
                child: DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF111230),
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontFamily: 'Acumin Pro',
                  ),
                  items: [
                    for (final t in types)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
              ),
              const SizedBox(height: 11),
              GlassField(
                label: 'Descripción del problema',
                icon: Icons.notes_rounded,
                controller: description,
                maxLines: 3,
              ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                      color: Colors.white.withValues(alpha: .08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'UBICACIÓN GPS',
                            style: TextStyle(
                              color: Color(0xFF8FA0C4),
                              fontSize: 9,
                              letterSpacing: .8,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed_rounded,
                                  color: cyan, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  locating
                                      ? 'Obteniendo…'
                                      : latitude != null
                                          ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                                          : 'No disponible',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Acumin Pro',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          InkWell(
                            onTap: _locate,
                            child: const Text(
                              'Actualizar desde GPS',
                              style: TextStyle(
                                color: cyan,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                      color: Colors.white.withValues(alpha: .08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRIORIDAD',
                            style: TextStyle(
                              color: Color(0xFF8FA0C4),
                              fontSize: 9,
                              letterSpacing: .8,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final p in priorities)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => priority = p),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: priority == p
                                          ? const Color(0xFFE5484D)
                                              .withValues(alpha: .25)
                                          : Colors.white.withValues(alpha: .07),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: priority == p
                                            ? const Color(0xFFE5484D)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        color: priority == p
                                            ? const Color(0xFFFFD2D2)
                                            : Colors.white70,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Acumin Pro',
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              // Evidencia
              InkWell(
                onTap: _pickPhoto,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: figmaBlue.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: evidenceBytes == null
                            ? const Icon(Icons.add_a_photo_outlined,
                                color: Colors.white, size: 22)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  evidenceBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evidenceBytes == null
                                  ? 'Subir evidencia (foto)'
                                  : 'Evidencia lista para envío',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                            const Text(
                              'Toma una foto con la cámara del problema',
                              style: TextStyle(
                                color: Color(0xFFB9D4FF),
                                fontSize: 10.5,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (evidenceBytes != null)
                        InkWell(
                          onTap: () => setState(() {
                            evidenceBytes = null;
                            evidenceFile = null;
                          }),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: Material(
                  color: sending ? const Color(0xFF8A4B4B) : const Color(0xFFD14343),
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _submit,
                    child: Center(
                      child: sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Reportar incidencia',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'El reporte incluye la ubicación GPS y se envía al operador.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8FA0C4),
                  fontSize: 10.5,
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
