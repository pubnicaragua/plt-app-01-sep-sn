import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'models/api_models.dart';

const ink = Color(0xFF10224A);
const navy = Color(0xFF071B53);
const cobalt = Color(0xFF0755E8);
const cyan = Color(0xFF3EC8F4);
const mint = Color(0xFF21C88A);
const mist = Color(0xFFF4F7FC);

final apiClient = ApiClient();

void main() => runApp(const IncoexApp());

class IncoexApp extends StatelessWidget {
  const IncoexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: cobalt,
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INCOEX Logistics',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: mist,
        fontFamily: 'Acumin Pro',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: ink,
          ),
          headlineMedium: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
            color: ink,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Color(0xFF71809A),
            height: 1.35,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: cobalt, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 16,
          ),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.caption,
  });

  final String title;
  final String description;
  final IconData icon;
  final String caption;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int page = 0;

  static const slides = [
    OnboardingSlide(
      title: 'Gestiona la recolección',
      description:
          'Entrega tus paquetes de forma rápida y segura desde un solo lugar.',
      icon: Icons.inventory_2_outlined,
      caption: 'Recolecta',
    ),
    OnboardingSlide(
      title: 'Monitorea cada pedido',
      description:
          'En tiempo real y recibe asistencia profesional cuando lo necesites.',
      icon: Icons.radar_outlined,
      caption: 'Conecta',
    ),
    OnboardingSlide(
      title: 'Disfruta de entregas express',
      description:
          'Sin complicaciones y llega a cualquier lugar con la máxima eficiencia.',
      icon: Icons.local_shipping_outlined,
      caption: 'Entrega',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = slides[page];
    final contentWidth =
        (MediaQuery.sizeOf(context).width - 48).clamp(0.0, 330.0).toDouble();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A3BC0), navy],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 15, 24, 23),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    slides.length,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index == slides.length - 1 ? 0 : 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: index <= page
                              ? Colors.white
                              : const Color(0xFF5474C4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const BrandLockup(light: true),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MascotCard(icon: slide.icon, caption: slide.caption),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: contentWidth,
                            child: Column(
                              children: [
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFE0E9FF),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFF131D59),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFF4961AA)),
                    ),
                  ),
                  onPressed: page == slides.length - 1
                      ? _openAuth
                      : () => setState(() => page += 1),
                  child: Text(
                    page == slides.length - 1 ? 'Comenzar' : 'Continuar',
                  ),
                ),
                TextButton(
                  onPressed: _openAuth,
                  child: const Text(
                    'Omitir',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    if (light) {
      return SizedBox(
        width: 178,
        height: 48,
        child: Image.asset(
          'assets/brand/incoex-logo.png',
          fit: BoxFit.contain,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: cyan,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Center(
            child: Text(
              'X',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.w900,
                fontSize: 21,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'INCOEX',
          style: TextStyle(
            color: light ? Colors.white : ink,
            fontWeight: FontWeight.w900,
            fontSize: 19,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Logistics',
          style: TextStyle(
            color: light ? const Color(0xFFB9D5FF) : const Color(0xFF7483A0),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class BrandMarkOnly extends StatelessWidget {
  const BrandMarkOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: cyan,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Center(
        child: Text(
          'X',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class MascotCard extends StatelessWidget {
  const MascotCard({
    super.key,
    required this.icon,
    required this.caption,
  });

  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      height: 222,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1986FF), Color(0xFF0B318F)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 30,
            offset: Offset(0, 17),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -25,
            right: -15,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.12),
                    border: Border.all(
                      color: Colors.white.withOpacity(.35),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 62,
                        child: Image.asset(
                          'assets/brand/incoex-logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 14,
            left: 18,
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: cyan,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isCompany = true;
  bool obscure = true;
  bool loading = false;
  String? errorMessage;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Ingresa tu correo y contraseña.');
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await apiClient.login(
        email: email,
        password: password,
        role: isCompany ? 'company' : 'driver',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              isCompany ? const CompanyShell() : const DriverShell(),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => errorMessage =
              'No se pudo conectar con INCOEX. Verifica que la API esté activa.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldDecoration = (String label, IconData icon) => InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFD9E6FF)),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: const Color(0x2BFFFFFF),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0x668CB6FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Colors.white, width: 1.4),
          ),
        );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3DB9), navy],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 25),
            children: [
              const BrandLockup(light: true),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D4DCC),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0x447EA8FF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x35000000),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Inicia sesión',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      isCompany
                          ? 'Accede al portal de tu empresa.'
                          : 'Accede a tu jornada como conductor.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD2E0FF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? const Color(0xFF0755E8)
                              : const Color(0x1FFFFFFF),
                        ),
                        side: WidgetStateProperty.all(
                          const BorderSide(color: Color(0x668CB6FF)),
                        ),
                      ),
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Empresa'),
                          icon: Icon(Icons.business_outlined),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Conductor'),
                          icon: Icon(Icons.local_shipping_outlined),
                        ),
                      ],
                      selected: {isCompany},
                      onSelectionChanged: (value) =>
                          setState(() => isCompany = value.first),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: fieldDecoration(
                        'Usuario / correo electrónico',
                        Icons.mail_outline,
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: obscure,
                      decoration:
                          fieldDecoration('Contraseña', Icons.lock_outline)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showRecoveryDialog(context),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: Color(0xFFE5EEFF)),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFD2D2),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Colors.white,
                        foregroundColor: cobalt,
                      ),
                      onPressed: loading ? null : _login,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Acceder'),
                    ),
                    const SizedBox(height: 17),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(color: Color(0xFFD2E0FF)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text(
                              'Regístrate aquí',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Al continuar aceptas los Términos y condiciones',
                  style: TextStyle(color: Color(0xFFC3D4FF), fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecoveryDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar acceso'),
        content: const Text(
          'La recuperación se habilitará cuando conectemos el proveedor de identidad productivo. Para esta revisión local, solicita al administrador un acceso de prueba.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isCompany = true;
  bool loading = false;
  bool obscure = true;
  String? errorMessage;
  final nameController = TextEditingController();
  final companyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    companyController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if ([
      nameController,
      companyController,
      emailController,
      passwordController,
    ].any((controller) => controller.text.trim().isEmpty)) {
      setState(() => errorMessage = 'Completa todos los campos.');
      return;
    }
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      await apiClient.register(
        name: nameController.text.trim(),
        companyName: companyController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: isCompany ? 'company' : 'driver',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              isCompany ? const CompanyShell() : const DriverShell(),
        ),
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
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          children: [
            const BrandLockup(light: true),
            const SizedBox(height: 25),
            Text(
              isCompany ? 'Registro de empresa' : 'Registro de conductor',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu acceso para comenzar a operar en INCOEX.',
              style: const TextStyle(
                color: Color(0xFFD2E0FF),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Empresa'),
                  icon: Icon(Icons.business_outlined),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Conductor'),
                  icon: Icon(Icons.local_shipping_outlined),
                ),
              ],
              selected: {isCompany},
              onSelectionChanged: (value) =>
                  setState(() => isCompany = value.first),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: companyController,
              decoration: InputDecoration(
                labelText:
                    isCompany ? 'Nombre de la empresa' : 'Empresa afiliada',
                prefixIcon: const Icon(Icons.apartment_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD64545),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: loading ? null : _register,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyShell extends StatefulWidget {
  const CompanyShell({super.key});

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    const views = [CompanyHome(), ShipmentHistory(), CompanyProfile()];
    return Scaffold(
      body: views[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Envíos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    const views = [DriverHome(), DriverTrips(), DriverProfile()];
    return Scaffold(
      body: views[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [child],
      ),
    );
  }
}

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4EAF3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF7B899D))),
        ],
      ),
    );
  }
}

class ApiErrorCard extends StatelessWidget {
  const ApiErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFFD7D1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFD64545)),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9D4037),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4EAF3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF8EA0B7), size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Color(0xFF7B899D))),
        ],
      ),
    );
  }
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'IX';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

class TopGreeting extends StatelessWidget {
  const TopGreeting({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE2ECFF),
          child: Text(
            initials(name),
            style: const TextStyle(
              color: cobalt,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $name',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7C8BA1),
                ),
              ),
              const Text(
                '¿Qué vas a enviar hoy?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: ink),
        ),
        const BrandMarkOnly(),
      ],
    );
  }
}

class CompanyHome extends StatefulWidget {
  const CompanyHome({super.key});

  @override
  State<CompanyHome> createState() => _CompanyHomeState();
}

class _CompanyHomeState extends State<CompanyHome> {
  late Future<List<Trip>> tripsFuture;

  @override
  void initState() {
    super.initState();
    tripsFuture = apiClient.getTrips();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopGreeting(name: apiClient.currentUser?.displayName ?? 'empresa'),
          const SizedBox(height: 22),
          const ProgressBanner(),
          const SizedBox(height: 24),
          const SectionLabel(text: 'Selecciona el transporte'),
          const SizedBox(height: 11),
          const Row(
            children: [
              Expanded(
                child: TransportCard(
                  icon: Icons.two_wheeler,
                  label: 'Moto',
                  eta: '15–30 min',
                  active: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TransportCard(
                  icon: Icons.directions_car,
                  label: 'Vehículo',
                  eta: '1–2 horas',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TransportCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Camión',
                  eta: '2–4 horas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel(text: 'Envío activo'),
          const SizedBox(height: 11),
          FutureBuilder<List<Trip>>(
            future: tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingCard(label: 'Consultando tus envíos…');
              }
              if (snapshot.hasError) {
                return ApiErrorCard(
                  message: 'No pudimos cargar los envíos desde la API.',
                  onRetry: () =>
                      setState(() => tripsFuture = apiClient.getTrips()),
                );
              }
              final activeTrips =
                  (snapshot.data ?? []).where((trip) => trip.isActive).toList();
              if (activeTrips.isEmpty) {
                return const EmptyCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'No tienes envíos activos.',
                );
              }
              return ShipmentStatusCard(trip: activeTrips.first);
            },
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RequestFlow()),
            ),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Solicitar nuevo envío'),
          ),
        ],
      ),
    );
  }
}

class ProgressBanner extends StatelessWidget {
  const ProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3DB9), Color(0xFF0A5BE6)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso 1 de 2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Información del envío',
                style: TextStyle(color: Color(0xFFB9D4FF), fontSize: 10),
              ),
            ],
          ),
          SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: .5,
              minHeight: 5,
              backgroundColor: Color(0x557DA5EC),
              color: cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class TransportCard extends StatelessWidget {
  const TransportCard({
    super.key,
    required this.icon,
    required this.label,
    required this.eta,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String eta;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 13, 10, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: active ? const Color(0xFFE8F0FF) : Colors.white,
          border: Border.all(
            color: active ? cobalt : const Color(0xFFE5EAF2),
            width: active ? 1.3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: active ? cobalt : const Color(0xFF70809C),
              size: 22,
            ),
            const SizedBox(height: 9),
            Text(
              label,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              eta,
              style: const TextStyle(color: Color(0xFF8492A7), fontSize: 10),
            ),
            if (active) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: cobalt,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Más rápido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class ShipmentStatusCard extends StatelessWidget {
  const ShipmentStatusCard({super.key, required this.trip});

  final Trip trip;

  double get progress {
    switch (trip.status) {
      case 'Completado':
        return 1;
      case 'En entrega':
        return .82;
      case 'En camino':
        return .62;
      case 'Asignado':
        return .35;
      default:
        return .12;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE4EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.status,
                style: const TextStyle(
                  color: cobalt,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                trip.id,
                style: const TextStyle(
                  color: Color(0xFF8A98AC),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            '${trip.origin} → ${trip.destination}',
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEAF0FF),
              color: cobalt,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% del flujo',
                style: const TextStyle(
                  color: cobalt,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              Text(
                '${trip.packages} paquete${trip.packages == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: mint,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFFE8F0FF),
                child: Text(
                  'CM',
                  style: TextStyle(
                    color: cobalt,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driver,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Conductor asignado por INCOEX',
                      style: const TextStyle(
                        color: Color(0xFF8996A8),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: cobalt,
                  size: 19,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RequestFlow extends StatefulWidget {
  const RequestFlow({super.key});

  @override
  State<RequestFlow> createState() => _RequestFlowState();
}

class _RequestFlowState extends State<RequestFlow> {
  int step = 0;
  int packages = 1;
  String transport = 'Moto';
  bool fragile = true;
  bool submitting = false;
  final origin = TextEditingController();
  final destination = TextEditingController();
  final description = TextEditingController();
  final recipient = TextEditingController();
  final recipientPhone = TextEditingController();

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    description.dispose();
    recipient.dispose();
    recipientPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de carga')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: cobalt,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: step == 1 ? cobalt : const Color(0xFFDDE5F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            Text(
              '¿Qué tipo de carga enviarás?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              step == 0
                  ? 'Indica las características de tu carga y elegiremos el transporte adecuado.'
                  : 'Completa los datos para que el conductor reciba instrucciones claras.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 23),
            if (step == 0) ...[
              TextField(
                controller: origin,
                decoration: const InputDecoration(
                  labelText: 'Desde',
                  hintText: 'Dirección de recogida',
                  prefixIcon: Icon(Icons.radio_button_checked, color: cobalt),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destination,
                decoration: const InputDecoration(
                  labelText: 'Hacia',
                  hintText: 'Dirección de entrega',
                  prefixIcon: Icon(Icons.location_on_outlined, color: cobalt),
                ),
              ),
              const SizedBox(height: 23),
              const Text(
                'Selecciona el transporte',
                style: TextStyle(color: ink, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TransportCard(
                      icon: Icons.two_wheeler,
                      label: 'Moto',
                      eta: '15–30 min',
                      active: transport == 'Moto',
                      onTap: () => setState(() => transport = 'Moto'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TransportCard(
                      icon: Icons.directions_car,
                      label: 'Vehículo',
                      eta: '1–2 horas',
                      active: transport == 'Vehículo',
                      onTap: () => setState(() => transport = 'Vehículo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              LoadQuantityCard(
                packages: packages,
                onChanged: (value) => setState(() => packages = value),
              ),
              const SizedBox(height: 25),
            ] else ...[
              TextField(
                controller: description,
                decoration: InputDecoration(
                  labelText: 'Descripción del paquete',
                  hintText: 'Ej.: Electrónicos, ropa, documentos...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: recipient,
                      decoration: InputDecoration(labelText: 'Destinatario'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: recipientPhone,
                      decoration: InputDecoration(labelText: 'Teléfono'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E8F2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Carga frágil?',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 7),
                    const Text(
                      'Requiere manejo especial',
                      style: TextStyle(
                        color: Color(0xFF8996A8),
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 3),
                    Switch(
                      value: fragile,
                      onChanged: (value) => setState(() => fragile = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: cobalt,
              ),
              onPressed: submitting
                  ? null
                  : step == 0
                      ? () => setState(() => step = 1)
                      : _finish,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(step == 0 ? 'Continuar' : 'Solicitar conductor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    if (origin.text.trim().isEmpty || destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa la recogida y el destino.')),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      final trip = await apiClient.createTrip(
        client: apiClient.currentUser?.displayName ?? 'Cuenta INCOEX',
        origin: origin.text.trim(),
        destination: destination.text.trim(),
        packages: packages,
        description: description.text.trim(),
        recipientName: recipient.text.trim(),
        recipientPhone: recipientPhone.text.trim(),
        fragile: fragile,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => SearchingDriverScreen(trip: trip)),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la solicitud.')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

class LoadQuantityCard extends StatelessWidget {
  const LoadQuantityCard({
    super.key,
    required this.packages,
    required this.onChanged,
  });

  final int packages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECF3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peso aproximado',
                style: TextStyle(color: Color(0xFF6C7C97), fontSize: 10),
              ),
              SizedBox(height: 5),
              Text(
                '10 kg',
                style: TextStyle(
                  color: ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: packages > 1 ? () => onChanged(packages - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: cobalt,
              ),
              Text(
                '$packages bulto${packages == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: cobalt,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => onChanged(packages + 1),
                icon: const Icon(Icons.add_circle_outline),
                color: cobalt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchingDriverScreen extends StatelessWidget {
  const SearchingDriverScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1639AA), navy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLockup(light: true),
                  const SizedBox(height: 74),
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.08),
                      border: Border.all(
                        color: Colors.white.withOpacity(.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.radar_outlined,
                      color: cyan,
                      size: 92,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Asignando conductor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Solicitud ${trip.id}: buscando disponibilidad para ${trip.origin} → ${trip.destination}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFC8D7FF), fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  const LinearProgressIndicator(
                    color: cyan,
                    backgroundColor: Color(0x446B86CA),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            TrackingScreen(tripId: trip.id, trip: trip),
                      ),
                    ),
                    child: const Text('Ver seguimiento'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShipmentHistory extends StatefulWidget {
  const ShipmentHistory({super.key});

  @override
  State<ShipmentHistory> createState() => _ShipmentHistoryState();
}

class _ShipmentHistoryState extends State<ShipmentHistory> {
  late Future<List<Trip>> tripsFuture;

  @override
  void initState() {
    super.initState();
    tripsFuture = apiClient.getTrips();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Historial de envíos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Consulta estados, recibos y evidencias de entrega.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          FutureBuilder<List<Trip>>(
            future: tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingCard(label: 'Consultando historial…');
              }
              if (snapshot.hasError) {
                return ApiErrorCard(
                  message: 'No pudimos cargar el historial.',
                  onRetry: () =>
                      setState(() => tripsFuture = apiClient.getTrips()),
                );
              }
              final trips = snapshot.data ?? const <Trip>[];
              if (trips.isEmpty) {
                return const EmptyCard(
                  icon: Icons.history,
                  label: 'Aún no hay viajes registrados.',
                );
              }
              return Column(
                children: trips
                    .map(
                      (trip) => HistoryTripTile(
                        trip: trip,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(
                              tripId: trip.id,
                              trip: trip,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HistoryTripTile extends StatelessWidget {
  const HistoryTripTile({
    super.key,
    required this.trip,
    required this.onTap,
  });

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3EAF3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: cobalt),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.id} · ${trip.status}',
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.origin} → ${trip.destination}',
                    style: const TextStyle(
                      color: Color(0xFF8795A9),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA7B8)),
          ],
        ),
      ),
    );
  }
}

class CompanyProfile extends StatelessWidget {
  const CompanyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopGreeting(name: apiClient.currentUser?.displayName ?? 'empresa'),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                BrandMarkOnly(),
                SizedBox(height: 14),
                Text(
                  'INCOEX Logistics',
                  style: TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Perfil de Empresa',
                  style: TextStyle(
                    color: cobalt,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.location_on_outlined, color: cobalt),
                  title: Text('Sucursales y direcciones'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.credit_card_outlined, color: cobalt),
                  title: Text('Métodos de pago corporativos'),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.support_agent_outlined, color: cobalt),
                  title: Text('Soporte empresarial'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({
    super.key,
    required this.tripId,
    this.trip,
  });

  final String tripId;
  final Trip? trip;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late Future<TrackingData> trackingFuture;

  @override
  void initState() {
    super.initState();
    trackingFuture = apiClient.getTracking(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento en vivo'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FAF1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '● API conectada',
              style: TextStyle(
                color: Color(0xFF159664),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<TrackingData>(
        future: trackingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ApiErrorCard(
              message: 'No pudimos consultar el tracking de ${widget.tripId}.',
              onRetry: () => setState(
                () => trackingFuture = apiClient.getTracking(widget.tripId),
              ),
            );
          }
          final tracking = snapshot.data!;
          final source = widget.trip?.origin ??
              (tracking.route.isNotEmpty
                  ? tracking.route.first.label
                  : 'Recogida');
          final destination = widget.trip?.destination ??
              (tracking.route.isNotEmpty
                  ? tracking.route.last.label
                  : 'Destino');
          final progress = trackingProgress(tracking.status);
          return ListView(
            padding: const EdgeInsets.all(17),
            children: [
              MapMock(startLabel: source, endLabel: destination),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.status,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$source → $destination',
                      style: const TextStyle(
                        color: Color(0xFF78869D),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 17),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(8),
                      color: cobalt,
                      backgroundColor: const Color(0xFFEAF0FF),
                    ),
                    const SizedBox(height: 13),
                    TrackingStep(
                      label: 'Asignado',
                      done: progress >= .35,
                    ),
                    TrackingStep(
                      label: 'Recogida',
                      done: progress >= .62,
                    ),
                    TrackingStep(
                      label: 'Entrega',
                      done: progress >= 1,
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFE8F0FF),
                          child: Icon(Icons.local_shipping_outlined,
                              color: cobalt),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tracking.driver,
                                style: const TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Última actualización: ${tracking.lastUpdate}',
                                style: const TextStyle(
                                  color: Color(0xFF8996A8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (tracking.status == 'Completado') ...[
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeliveredScreen(
                              trip: widget.trip,
                              tracking: tracking,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Ver comprobante'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

double trackingProgress(String status) {
  switch (status) {
    case 'Completado':
      return 1;
    case 'En entrega':
      return .82;
    case 'En camino':
      return .62;
    case 'Asignado':
      return .35;
    default:
      return .12;
  }
}

class DeliveredScreen extends StatelessWidget {
  const DeliveredScreen({
    super.key,
    required this.trip,
    required this.tracking,
  });

  final Trip? trip;
  final TrackingData tracking;

  @override
  Widget build(BuildContext context) {
    final route = trip == null
        ? tracking.tripId
        : '${trip!.origin} → ${trip!.destination}';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 52, 22, 24),
          children: [
            const BrandLockup(),
            const SizedBox(height: 58),
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE7FAF1),
                border: Border.all(color: mint, width: 3),
              ),
              child: const Icon(Icons.check, color: mint, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Paquete entregado!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La operación fue cerrada por INCOEX.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7B899D), fontSize: 13),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4EAF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalle de la entrega',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    route,
                    style: const TextStyle(color: ink, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conductor: ${tracking.driver}',
                    style: const TextStyle(
                      color: Color(0xFF7B899D),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Actualizado: ${tracking.lastUpdate}',
                    style: const TextStyle(
                      color: Color(0xFF7B899D),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Cómo fue tu experiencia?',
              textAlign: TextAlign.center,
              style: TextStyle(color: ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.star_border, color: Color(0xFF8FA1BB)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil(
                (route) => route.isFirst,
              ),
              child: const Text('Regresar al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class MapMock extends StatelessWidget {
  const MapMock({
    super.key,
    this.startLabel = 'Centro INCOEX',
    this.endLabel = 'Destino',
  });

  final String startLabel;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F4F6), Color(0xFFE9EEFA)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: MapLinesPainter())),
          const Positioned(left: 52, top: 151, child: Dot(color: mint)),
          const Positioned(left: 172, top: 78, child: Dot(color: cobalt)),
          const Positioned(
            right: 45,
            top: 50,
            child: Dot(color: Color(0xFFE9AA39)),
          ),
          Positioned(
            left: 78,
            top: 177,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                boxShadow: const [
                  BoxShadow(color: Color(0x18000000), blurRadius: 8),
                ],
              ),
              child: Text(
                startLabel,
                style: const TextStyle(
                  color: ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 13,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                endLabel,
                style: const TextStyle(
                  color: Color(0xFF71809A),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.35),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}

class MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x558BB6D0)
      ..strokeWidth = 1.5;
    for (var x = -size.height; x < size.width; x += 48) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    final route = Paint()
      ..color = cobalt
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(58, 160)
        ..quadraticBezierTo(110, 145, 160, 100)
        ..quadraticBezierTo(210, 55, 310, 58),
      route,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrackingStep extends StatelessWidget {
  const TrackingStep({super.key, required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? cobalt : const Color(0xFFE5EAF2),
          ),
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : null,
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            color: done ? ink : const Color(0xFF96A2B2),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Expanded(
          child: Divider(
            indent: 12,
            endIndent: 12,
            color: Color(0xFFE2E8F1),
          ),
        ),
      ],
    );
  }
}

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  late Future<List<Trip>> tripsFuture;

  @override
  void initState() {
    super.initState();
    tripsFuture = apiClient.getTrips();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopGreeting(name: apiClient.currentUser?.displayName ?? 'conductor'),
          const SizedBox(height: 22),
          FutureBuilder<List<Trip>>(
            future: tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingCard(label: 'Cargando jornada…');
              }
              if (snapshot.hasError) {
                return ApiErrorCard(
                  message: 'No pudimos cargar la jornada del conductor.',
                  onRetry: () =>
                      setState(() => tripsFuture = apiClient.getTrips()),
                );
              }
              final trips = snapshot.data ?? const <Trip>[];
              final activeTrips = trips.where((trip) => trip.isActive).toList();
              final nextTrip = activeTrips.isEmpty ? null : activeTrips.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DriverStatsCard(
                    activeTrips: activeTrips.length,
                    totalTrips: trips.length,
                  ),
                  const SizedBox(height: 25),
                  const SectionLabel(text: 'Próxima entrega'),
                  const SizedBox(height: 11),
                  if (nextTrip == null)
                    const EmptyCard(
                      icon: Icons.route_outlined,
                      label: 'No tienes entregas activas.',
                    )
                  else ...[
                    ShipmentStatusCard(trip: nextTrip),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TrackingScreen(
                            tripId: nextTrip.id,
                            trip: nextTrip,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Abrir ruta'),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DriverStatsCard extends StatelessWidget {
  const DriverStatsCard({
    super.key,
    required this.activeTrips,
    required this.totalTrips,
  });

  final int activeTrips;
  final int totalTrips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF0A3CB5), navy]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu jornada de hoy',
            style: TextStyle(color: Color(0xFFBBD1FF), fontSize: 11),
          ),
          const SizedBox(height: 7),
          Text(
            '$activeTrips entregas activas',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Stat(label: 'Viajes API', value: '$totalTrips')),
              const Expanded(child: Stat(label: 'Estado', value: 'Activo')),
              const Expanded(child: Stat(label: 'Operación', value: 'INCOEX')),
            ],
          ),
        ],
      ),
    );
  }
}

class Stat extends StatelessWidget {
  const Stat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9AB8F2), fontSize: 9),
        ),
      ],
    );
  }
}

class DriverTrips extends StatefulWidget {
  const DriverTrips({super.key});

  @override
  State<DriverTrips> createState() => _DriverTripsState();
}

class _DriverTripsState extends State<DriverTrips> {
  late Future<List<Trip>> tripsFuture;

  @override
  void initState() {
    super.initState();
    tripsFuture = apiClient.getTrips();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mis viajes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Trip>>(
            future: tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingCard(label: 'Consultando viajes…');
              }
              if (snapshot.hasError) {
                return ApiErrorCard(
                  message: 'No pudimos cargar tus viajes.',
                  onRetry: () =>
                      setState(() => tripsFuture = apiClient.getTrips()),
                );
              }
              final trips = snapshot.data ?? const <Trip>[];
              if (trips.isEmpty) {
                return const EmptyCard(
                  icon: Icons.route_outlined,
                  label: 'No hay viajes asignados.',
                );
              }
              return Column(
                children: trips
                    .map(
                      (trip) => HistoryTripTile(
                        trip: trip,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(
                              tripId: trip.id,
                              trip: trip,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DriverProfile extends StatelessWidget {
  const DriverProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = apiClient.currentUser;
    final name = user?.displayName ?? 'Conductor INCOEX';
    final vehicle = user?.vehicle ?? 'Vehículo pendiente de validar';
    final plate = user?.plate ?? 'Placa pendiente de validar';
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopGreeting(name: name),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: const Color(0xFFE8F0FF),
                  child: Text(
                    initials(name),
                    style: const TextStyle(
                      color: cobalt,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  name,
                  style: TextStyle(
                    color: ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Conductor INCOEX',
                  style: TextStyle(
                    color: cobalt,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.directions_car_outlined, color: cobalt),
                  title: Text(vehicle),
                  subtitle: Text(plate),
                  trailing: Icon(Icons.chevron_right),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.verified_user_outlined, color: cobalt),
                  title: Text('Documentos y validación'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
