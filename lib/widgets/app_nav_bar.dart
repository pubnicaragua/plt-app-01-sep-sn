import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppNavBarItem {
  const AppNavBarItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.current,
    required this.onChanged,
    this.items = const [
      AppNavBarItem(Icons.home_rounded, 'Inicio'),
      AppNavBarItem(Icons.inventory_2_outlined, 'Envíos'),
      AppNavBarItem(Icons.history_rounded, 'Historial'),
      AppNavBarItem(Icons.person_outline_rounded, 'Perfil'),
    ],
  });

  final int current;
  final ValueChanged<int> onChanged;
  final List<AppNavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0135A7), Color(0xFF111230)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x4DFFFFFF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .45),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF0106A7).withValues(alpha: .35),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _item(0, items[0].icon, items[0].label),
            _item(1, items[1].icon, items[1].label),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 54,
                height: 54,
                child: Image.asset(
                  'assets/img/brand-x.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'INCOEX',
                ),
              ),
            ),
            _item(2, items[2].icon, items[2].label),
            _item(3, items[3].icon, items[3].label),
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
              color: active ? cyan : const Color(0xFF8FA0C4),
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF8FA0C4),
                fontSize: 9.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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
