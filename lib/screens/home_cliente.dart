import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import '../widgets/place_field.dart';
import 'crear_envio1.dart';
import 'pedido.dart';
import 'mi_perfil_cliente.dart';
import 'resumen_cliente.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final views = <Widget>[
      const _HomeTab(),
      Pedido(),
      const ResumenCliente(),
      const MiPerfilCliente(),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: tab,
            children: views,
          ),
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        current: tab,
        onChanged: (index) => setState(() => tab = index),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  static const items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.inventory_2_outlined, 'Envíos'),
    (Icons.history_rounded, 'Historial'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 8 + bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C1B3E), Color(0xFF080F26)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x2EFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(0, items[0].$1, items[0].$2),
            _item(1, items[1].$1, items[1].$2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 50,
                height: 32,
                child: Image.asset(
                  'assets/img/brand-x.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            _item(2, items[2].$1, items[2].$2),
            _item(3, items[3].$1, items[3].$2),
          ],
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final active = current == index;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(index),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  active ? Colors.white : const Color(0xFF8FA0C4),
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? Colors.white : const Color(0xFF8FA0C4),
                fontSize: 9.5,
                fontWeight:
                    active ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'Acumin Pro',
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? cyan : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.close_rounded, color: cyan, size: 26),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool programado = true;
  final origin = TextEditingController();
  final destination = TextEditingController();
  PlaceSuggestion? originPlace;
  PlaceSuggestion? destinationPlace;

  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = apiClient.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?.displayName ?? 'Mario Belfort'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const Text(
                    '¿Qué vas a enviar hoy?',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .16),
                border: Border.all(color: glassBorder),
              ),
              child: Center(
                child: Text(
                  initials(user?.displayName ?? 'Incoex'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D4DCC), Color(0xFF0034A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: glassBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0034A6).withValues(alpha: .45),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Envía hoy en Managua',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Crea tu envío en 3 pasos y mira el precio\nantes de confirmar.',
                      style: TextStyle(
                        color: Color(0xFFC9DCFF),
                        fontSize: 11.5,
                        height: 1.4,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .14),
                  border: Border.all(color: glassBorder),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _StepBanner(),
        const SizedBox(height: 22),
        const Text(
          'Selecciona el transporte',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontFamily: 'Acumin Pro',
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _TransportTile(
                icon: Icons.two_wheeler,
                label: 'Moto',
                eta: '15-30 min',
                badge: 'Más rápido',
              ),
            ),
            SizedBox(width: 9),
            Expanded(
              child: _TransportTile(
                icon: Icons.directions_car_filled,
                label: 'Vehículo',
                eta: '1-2 hrs',
                badge: 'Versátil',
              ),
            ),
            SizedBox(width: 9),
            Expanded(
              child: _TransportTile(
                icon: Icons.local_shipping_outlined,
                label: 'Camión',
                eta: '2-4 hrs',
                badge: 'Carga grande',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _EditableRouteCard(
          origin: origin,
          destination: destination,
          onOriginSelected: (place) => setState(() => originPlace = place),
          onDestinationSelected: (place) =>
              setState(() => destinationPlace = place),
        ),
        const SizedBox(height: 14),
        const _ReferencesCard(),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: _RecipientCard(label: 'Destinatario', hint: 'Nombre completo')),
            SizedBox(width: 10),
            Expanded(child: _RecipientCard(label: 'Teléfono', hint: '+505 …', icon: Icons.call_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _PriorityBar(
          programado: programado,
          onChanged: (value) => setState(() => programado = value),
        ),
        const SizedBox(height: 18),
        GlassButton(
          label: 'Solicitar nuevo envío',
          filled: true,
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CrearEnvio1(
                startOrigin: origin.text.trim(),
                startDestination: destination.text.trim(),
                startOriginPlace: originPlace,
                startDestinationPlace: destinationPlace,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBanner extends StatelessWidget {
  const _StepBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paso 1 de 2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const Text(
                'Información del envío',
                style: TextStyle(
                  color: Color(0xFFB9D4FF),
                  fontSize: 10,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: .5,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .16),
              color: cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportTile extends StatelessWidget {
  const _TransportTile({
    required this.icon,
    required this.label,
    required this.eta,
    required this.badge,
  });

  final IconData icon;
  final String label;
  final String eta;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 12, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D4DCC),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            eta,
            style: const TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 10,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: figmaBlue,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Acumin Pro',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableRouteCard extends StatelessWidget {
  const _EditableRouteCard({
    required this.origin,
    required this.destination,
    required this.onOriginSelected,
    required this.onDestinationSelected,
  });

  final TextEditingController origin;
  final TextEditingController destination;
  final ValueChanged<PlaceSuggestion> onOriginSelected;
  final ValueChanged<PlaceSuggestion> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESDE',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 7),
          GlassField(
            label: 'Desde',
            hint: 'Busca un lugar de Managua…',
            icon: Icons.radio_button_checked,
            controller: origin,
            readOnly: true,
            suffix: IconButton(
              onPressed: () => origin.clear(),
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'HACIA',
            style: TextStyle(
              color: Color(0xFFB9D4FF),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
          const SizedBox(height: 7),
          PlaceAutocompleteField(
            label: 'Hacia',
            hint: 'Busca un lugar de Managua…',
            icon: Icons.place_rounded,
            controller: destination,
            onSelected: onDestinationSelected,
          ),
        ],
      ),
    );
  }
}

class _ReferencesCard extends StatelessWidget {
  const _ReferencesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_location_alt_outlined,
              color: Colors.white70, size: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Referencias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ej. Casa verde frente al parque…',
                  style: TextStyle(
                    color: const Color(0xFFB9D4FF)
                        .withValues(alpha: .85),
                    fontSize: 10.5,
                    fontFamily: 'Acumin Pro',
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

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.label, required this.hint, this.icon});

  final String label;
  final String hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.person_outline_rounded,
              color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: TextStyle(
                    color: const Color(0xFFB9D4FF)
                        .withValues(alpha: .8),
                    fontSize: 10,
                    fontFamily: 'Acumin Pro',
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

class _PriorityBar extends StatelessWidget {
  const _PriorityBar({required this.programado, required this.onChanged});

  final bool programado;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          _option('Prioritario', !programado, () => onChanged(false)),
          _option('Programado', programado, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _option(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? figmaBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
      ),
    );
  }
}
