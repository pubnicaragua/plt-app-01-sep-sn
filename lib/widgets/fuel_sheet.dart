import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/theme.dart';

Future<bool?> showFuelSheet(
  BuildContext context, {
  required String driverName,
  String? initialPlate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: const Color(0xFF0B1D4D),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _FuelSheet(
      driverName: driverName,
      initialPlate: initialPlate,
    ),
  );
}

class _FuelSheet extends StatefulWidget {
  const _FuelSheet({required this.driverName, this.initialPlate});

  final String driverName;
  final String? initialPlate;

  @override
  State<_FuelSheet> createState() => _FuelSheetState();
}

class _FuelSheetState extends State<_FuelSheet> {
  final plate = TextEditingController();
  final liters = TextEditingController();
  final price = TextEditingController();
  final odometer = TextEditingController();
  final note = TextEditingController();
  Uint8List? odometerPhoto;
  Uint8List? receiptPhoto;
  String odometerName = 'No tomada';
  String receiptName = 'No tomada';
  bool sending = false;

  @override
  void initState() {
    super.initState();
    plate.text = widget.initialPlate ?? apiClient.currentUser?.plate ?? '';
  }

  @override
  void dispose() {
    plate.dispose();
    liters.dispose();
    price.dispose();
    odometer.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _takePhoto({required bool isOdometer}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 72,
        maxWidth: 1400,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (isOdometer) {
          odometerPhoto = bytes;
          odometerName = image.name;
        } else {
          receiptPhoto = bytes;
          receiptName = image.name;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la cámara.')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final litersValue = double.tryParse(liters.text.replaceAll(',', '.'));
    final odometerValue = double.tryParse(odometer.text.replaceAll(',', '.'));
    if (plate.text.trim().isEmpty || litersValue == null || litersValue <= 0 || odometerValue == null || odometerValue < 0) {
      _showError('Completa placa, litros y kilometraje válido.');
      return;
    }
    if (odometerPhoto == null || receiptPhoto == null) {
      _showError('Toma la foto del odómetro y la foto de la factura.');
      return;
    }
    setState(() => sending = true);
    try {
      final uploads = await Future.wait([
        apiClient.uploadEvidence(odometerPhoto!, odometerName),
        apiClient.uploadEvidence(receiptPhoto!, receiptName),
      ]);
      await apiClient.addFuelRecord(
        plate: plate.text.trim(),
        liters: litersValue,
        pricePerLiterCs: double.tryParse(price.text.replaceAll(',', '.')),
        odometerKm: odometerValue,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        driver: widget.driverName,
        evidence: jsonEncode({
          'odometer': uploads[0]['evidence'],
          'receipt': uploads[1]['evidence'],
        }),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => sending = false);
        _showError('No se pudo guardar la recarga. Verifica la conexión.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withValues(alpha: .1),
        hintStyle: const TextStyle(color: Color(0xFF9EB9E2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .16)),
        ),
      );

  Widget _photoButton({required bool isOdometer, required String title, required String fileName}) {
    final selected = isOdometer ? odometerPhoto != null : receiptPhoto != null;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: sending ? null : () => _takePhoto(isOdometer: isOdometer),
        icon: Icon(selected ? Icons.check_circle_rounded : Icons.camera_alt_rounded, size: 18),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? const Color(0xFF5DE4B1) : Colors.white,
          side: BorderSide(color: selected ? const Color(0xFF5DE4B1) : glassBorder),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .25), borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 16),
            const Text('Registrar combustible', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Acumin Pro')),
            const SizedBox(height: 4),
            const Text('La evidencia del odómetro y la factura es obligatoria.', style: TextStyle(color: Color(0xFFB9D4FF), fontFamily: 'Acumin Pro')),
            const SizedBox(height: 16),
            TextField(controller: plate, style: const TextStyle(color: Colors.white), decoration: _decoration('Placa del vehículo')),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: TextField(controller: liters, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: _decoration('Litros'))), const SizedBox(width: 10), Expanded(child: TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: _decoration('Precio C\$/L')))]),
            const SizedBox(height: 10),
            TextField(controller: odometer, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white), decoration: _decoration('Kilometraje actual')),
            const SizedBox(height: 10),
            Row(children: [_photoButton(isOdometer: true, title: 'Odómetro *', fileName: odometerName), const SizedBox(width: 10), _photoButton(isOdometer: false, title: 'Factura *', fileName: receiptName)]),
            const SizedBox(height: 10),
            TextField(controller: note, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: _decoration('Nota opcional')),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: OutlinedButton(onPressed: sending ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: sending ? null : _submit, icon: const Icon(Icons.save_rounded), label: Text(sending ? 'Guardando…' : 'Guardar recarga')))]),
          ],
        ),
      ),
    );
  }
}
