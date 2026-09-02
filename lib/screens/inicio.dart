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
  final email =
      TextEditingController(text: 'mario.martinez@incoex.com.ni');
  final password = TextEditingController(text: 'demo.incoex');
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
      await apiClient.login(
        email: email.text.trim(),
        password: password.text,
        role: role,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              role == 'driver' ? const HomeConductor() : const HomeCliente(),
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Capa 4 (fondo): paisaje con máscara
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
          // Capa 2: rectángulo azul degradado (tapa al pájaro)
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: .64,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF003EC7),
                      Color(0xFF111230),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
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
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * .47),
                  const Text(
                    'Inicia Sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(height: 14),
                  GlassField(
                    label: 'Usuario/Correo electrónico',
                    icon: Icons.person_outline_rounded,
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Registro(),
                      ),
                    ),
                    child: const Text(
                      '¿No tienes cuenta? Regístrate aquí',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  GlassButton(
                    label: loading ? 'Accediendo…' : 'Acceder',
                    filled: true,
                    textColor: Colors.white,
                    onPressed: loading ? () {} : _login,
                  ),
                  const SizedBox(height: 34),
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
