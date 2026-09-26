import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppNavBarItem {
  const AppNavBarItem(this.icon, this.label, {this.assetPath});
  final IconData icon;
  final String label;
  final String? assetPath;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.current,
    required this.onChanged,
    this.items = const [
      AppNavBarItem(Icons.home_rounded, 'Inicio',
          assetPath: 'assets/img/HomeCliente/home_x.png'),
      AppNavBarItem(Icons.inventory_2_outlined, 'Envíos',
          assetPath: 'assets/img/HomeCliente/EnviosNavbar.png'),
      AppNavBarItem(Icons.history_rounded, 'Resumen',
          assetPath: 'assets/img/HomeCliente/HistorialNavbar.png'),
      AppNavBarItem(Icons.person_outline_rounded, 'Tú'),
    ],
  });

  final int current;
  final ValueChanged<int> onChanged;
  final List<AppNavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final navWidth = screenWidth > 384 ? 360.0 : screenWidth - 24;
    return Center(
      child: SizedBox(
        width: navWidth,
        height: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x3D4B5563),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white.withValues(alpha: .28)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _item(0, items[0]),
                    _item(1, items[1]),
                    _item(2, items[2]),
                    _item(3, items[3]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int index, AppNavBarItem item) {
    final active = current == index;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(index),
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.white.withValues(alpha: .10),
        splashColor: Colors.white.withValues(alpha: .18),
        highlightColor: Colors.white.withValues(alpha: .08),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 62 : 56,
            height: 56,
            decoration: active
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: .24)),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 27,
                  height: 27,
                  child: item.assetPath == null
                      ? Icon(item.icon, color: Colors.white, size: 22)
                      : Image.asset(
                          item.assetPath!,
                          fit: BoxFit.contain,
                          semanticLabel: item.label,
                          errorBuilder: (_, __, ___) => Icon(
                            item.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                ),
                const SizedBox(height: 0),
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBorderPainter extends CustomPainter {
  const _NavBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.75),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x33FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _NavBorderPainter oldDelegate) => false;
}
