import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/glass.dart';
import 'home_cliente.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final name = TextEditingController();
  final lastName = TextEditingController();
  final company = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    name.dispose();
    lastName.dispose();
    company.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if ([name, lastName, company, email, password]
        .any((c) => c.text.trim().isEmpty)) {
      setState(() => errorMessage = 'Completa todos los campos.');
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final fullName = '${name.text.trim()} ${lastName.text.trim()}';
      await apiClient.register(
        name: fullName,
        companyName: company.text.trim(),
        email: email.text.trim(),
        password: password.text,
        role: 'company',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeCliente()),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(fontFamily: 'Acumin Pro', fontWeight: FontWeight.w700),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 74, 24, 28),
            children: [
              const Center(child: BrandLockup()),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'Registro de empresa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Crea tu acceso para comenzar a operar en INCOEX.',
                style: TextStyle(
                  color: Color(0xFFD2E0FF),
                  fontSize: 13,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 23),
              GlassField(label: 'Nombre', icon: Icons.person_outline, controller: name),
              const SizedBox(height: 11),
              GlassField(label: 'Apellido', icon: Icons.person_outline, controller: lastName),
              const SizedBox(height: 11),
              GlassField(
                label: 'Nombre de la Empresa',
                icon: Icons.apartment_rounded,
                controller: company,
              ),
              const SizedBox(height: 11),
              GlassField(
                label: 'Correo electrónico',
                icon: Icons.alternate_email_rounded,
                controller: email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 11),
              GlassField(
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                controller: password,
                obscure: true,
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
              if (errorMessage != null) ...[
                const SizedBox(height: 13),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD2D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GlassButton(
                label: loading ? 'Creando cuenta…' : 'Crear cuenta',
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
}
