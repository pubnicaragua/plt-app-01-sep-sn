import 'dart:ui';

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final navWidth = screenWidth > 384 ? 360.0 : screenWidth - 24;
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 10 + bottom),
      child: Center(
        child: SizedBox(
          width: navWidth,
          height: 76,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 16)),
                BoxShadow(color: Color(0x120066FF), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xB2141A2A),
                    borderRadius: BorderRadius.circular(38),
                    border: const Border(
                      top: BorderSide(color: Color(0x66FFFFFF), width: 1.5),
                      right: BorderSide(color: Color(0x33FFFFFF), width: 1),
                      bottom: BorderSide(color: Color(0x1FFFFFFF), width: .5),
                      left: BorderSide(color: Color(0x33FFFFFF), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _item(0, items[0].icon, items[0].label),
                      _item(1, items[1].icon, items[1].label),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 54,
                          height: 58,
                          child: Image.asset('assets/img/brand-x.png', fit: BoxFit.contain, semanticLabel: 'INCOEX'),
                        ),
                      ),
                      _item(2, items[2].icon, items[2].label),
                      _item(3, items[3].icon, items[3].label),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
              size: 20,
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
