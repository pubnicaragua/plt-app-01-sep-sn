import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/glass.dart';
import 'home_cliente.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final name = TextEditingController();
  final company = TextEditingController();
  final identification = TextEditingController();
  final taxId = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  Uint8List? municipalDocument;
  String? municipalDocumentName;
  bool obscure = true;
  bool termsAccepted = false;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    name.dispose();
    company.dispose();
    identification.dispose();
    taxId.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _pickMunicipalDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || file.bytes == null || !mounted) return;
      if (file.bytes!.length > 5 * 1024 * 1024) {
        setState(() => errorMessage = 'El archivo no puede superar 5 MB.');
        return;
      }
      setState(() {
        municipalDocument = file.bytes;
        municipalDocumentName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = 'No se pudo adjuntar la matrícula.');
    }
  }

  Future<void> _register() async {
    final requiredFields = [name, company, identification, taxId, phone, email, password];
    if (requiredFields.any((controller) => controller.text.trim().isEmpty)) {
      setState(() => errorMessage = 'Completa todos los campos.');
      return;
    }
    if (password.text.length < 8) {
      setState(() => errorMessage = 'La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (!termsAccepted) {
      setState(() => errorMessage = 'Acepta los términos y la política de privacidad.');
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await apiClient.register(
        name: name.text.trim(),
        companyName: company.text.trim(),
        email: email.text.trim(),
        password: password.text,
        role: 'company',
        phone: phone.text.trim(),
        identification: identification.text.trim(),
        taxId: taxId.text.trim(),
        documentName: municipalDocumentName,
      );
      if (municipalDocument != null && municipalDocumentName != null) {
        try {
          await apiClient.uploadEvidence(municipalDocument!, municipalDocumentName!);
        } catch (_) {
          // La cuenta ya fue creada; el documento puede adjuntarse desde Perfil.
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeCliente()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => errorMessage = 'No se pudo crear la cuenta.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1C53),
      body: AppBackground(
        darken: 0,
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 24),
              _field('Nombre completo', Icons.person_outline_rounded, name),
              const SizedBox(height: 11),
              _field('Nombre de la Empresa', Icons.business_outlined, company),
              const SizedBox(height: 11),
              _field('Número de Cédula', Icons.badge_outlined, identification),
              const SizedBox(height: 11),
              _field('Número RUC', Icons.receipt_long_outlined, taxId),
              const SizedBox(height: 11),
              _field(
                'Celular / WhatsApp',
                Icons.phone_outlined,
                phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 11),
              _field(
                'Correo Electrónico',
                Icons.mail_outline_rounded,
                email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 11),
              GlassField(
                key: ValueKey(obscure),
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                controller: password,
                obscure: obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Documentos Requeridos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Formatos aceptados: JPG, PNG o PDF (Máx. 5MB)',
                style: TextStyle(
                  color: Color(0xFFD2E0FF),
                  fontSize: 12,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 12),
              _DocumentUpload(
                fileName: municipalDocumentName,
                onTap: _pickMunicipalDocument,
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: termsAccepted,
                    onChanged: (value) =>
                        setState(() => termsAccepted = value ?? false),
                    activeColor: accentBlue,
                    side: const BorderSide(color: Colors.white54),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text.rich(
                        TextSpan(
                          text: 'Acepto los ',
                          children: [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: TextStyle(decoration: TextDecoration.underline),
                            ),
                            TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(decoration: TextDecoration.underline),
                            ),
                            TextSpan(text: ' de INCOEX.'),
                          ],
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.15,
                          fontFamily: 'Figtree',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD2D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
              const SizedBox(height: 13),
              GlassButton(
                label: loading ? 'Creando cuenta…' : 'Crear cuenta empresa',
                filled: true,
                textColor: Colors.white,
                onPressed: loading ? () {} : _register,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return GlassField(
      label: label,
      icon: icon,
      controller: controller,
      keyboardType: keyboardType,
      showFloatingLabel: false,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .12),
            shape: const CircleBorder(),
            side: BorderSide(color: Colors.white.withValues(alpha: .28)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registro de Empresa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Crea tu cuenta corporativa para continuar',
                style: TextStyle(
                  color: Color(0xFFD2E0FF),
                  fontSize: 12.5,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentUpload extends StatelessWidget {
  const _DocumentUpload({required this.fileName, required this.onTap});

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            color: figmaBlue.withValues(alpha: .84),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cyan.withValues(alpha: .50)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: .35)),
                ),
                child: const Icon(Icons.file_upload_outlined,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 9),
              Text(
                fileName ?? 'Adjuntar Matrícula de la Alcaldía',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Figtree',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fileName == null
                    ? 'Sube la patente comercial municipal'
                    : 'Documento adjunto correctamente',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Figtree',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
