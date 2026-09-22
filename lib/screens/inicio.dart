import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/glass.dart';
import 'home_cliente.dart';
import 'home_conductor.dart';
import 'registro.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  // Cuenta de prueba corporativa creada por la API local.
  final email =
      TextEditingController(text: 'contacto@logisticanica.com.ni');
  final password = TextEditingController(text: 'Admin@2026');
  bool obscure = true;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String _detectRole(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('carlos') ||
        normalized.contains('jose') ||
        normalized.contains('conductor') ||
        normalized.contains('driver')) {
      return 'driver';
    }
    return 'company';
  }

  Future<void> _login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => errorMessage = 'Ingresa tu correo y contraseña.');
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    final role = _detectRole(email.text);
    try {
      final response = await apiClient.login(
        email: email.text.trim(),
        password: password.text,
        role: role,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              response.user.role == 'driver'
                  ? const HomeConductor()
                  : const HomeCliente(),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              errorMessage = 'No se pudo conectar. Verifica que la API esté activa.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rectTop = size.height * .36;
    final formInset = size.width * .105;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Capa 4 (fondo): paisaje original de la mascota
          Image.asset(
            'assets/img/PantallaInicio/Maskgroup.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E4FA0), Color(0xFF0B1D4D)],
                ),
              ),
            ),
          ),
          // Capa 3: pájaro GRANDE a la derecha, detrás del rectángulo
          Positioned(
            right: -size.width * .10 - 92,
            top: size.height * .075,
            width: size.width * 1.04 + 70,
            height: rectTop + size.height * .58,
            child: Image.asset(
              'assets/img/PantallaInicio/pajaro1.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // Capa 2: panel de acceso con el logotipo geométrico de fondo
          Positioned(
            top: rectTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF003EC7),
                          Color(0xFF111230),
                        ],
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: .36,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF83A9F5),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/img/fondoapps.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Capa 1: mano pegada al brazo del pájaro sobre el borde
          Positioned(
            left: size.width * .24 - 35,
            top: rectTop - size.height * .089,
            width: size.width * .52 + 26,
            height: size.height * .19 + 36,
            child: Image.asset(
              'assets/img/PantallaInicio/mano.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // Logo INCOEX (esquina superior izquierda)
          const Positioned(
            top: 50,
            left: 20,
            child: Image(
              image: AssetImage(
                'assets/img/PantallaInicio/cropped-LOGO-INCOEX-9-1.png',
              ),
              width: 158,
              height: 43,
              fit: BoxFit.contain,
            ),
          ),
          // Contenido interactivo
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(formInset, 0, formInset, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Acerca el título y los campos al panel superior sin mover
                  // el fondo ni alterar las proporciones del formulario.
                  SizedBox(height: size.height * .535 - 50),
                  const Text(
                    'Iniciar sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LoginField(
                    label: 'Correo',
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  _LoginField(
                    key: ValueKey(obscure),
                    label: 'Contraseña',
                    controller: password,
                    obscureText: obscure,
                    onToggleObscure: () => setState(() => obscure = !obscure),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
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
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Registro(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '¿No tienes cuenta? ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                          TextSpan(
                            text: 'Regístrate aquí',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Acumin Pro',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    label: loading ? 'Accediendo…' : 'Iniciar sesión',
                    filled: true,
                    height: 36,
                    textColor: Colors.white,
                    onPressed: loading ? () {} : _login,
                  ),
                  const SizedBox(height: 58),
                  const Center(
                    child: Text(
                      'Uso de Términos y Condiciónes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37,
      padding: const EdgeInsets.only(left: 18, right: 4),
      decoration: BoxDecoration(
        color: const Color(0x3D9AB0DF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'Acumin Pro',
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 11,
                  fontFamily: 'Acumin Pro',
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onToggleObscure != null)
            IconButton(
              onPressed: onToggleObscure,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 22, height: 28),
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xD9FFFFFF),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
