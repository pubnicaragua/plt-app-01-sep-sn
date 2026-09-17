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
          assetPath: 'assets/img/HomeCliente/HomeNavbar.png'),
      AppNavBarItem(Icons.inventory_2_outlined, 'Envíos',
          assetPath: 'assets/img/HomeCliente/EnviosNavbar.png'),
      AppNavBarItem(Icons.history_rounded, 'Historial',
          assetPath: 'assets/img/HomeCliente/HistorialNavbar.png'),
      AppNavBarItem(Icons.person_outline_rounded, 'Perfil'),
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
          height: 76,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              boxShadow: const [
                BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x180066FF), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: CustomPaint(
                  painter: const _NavBorderPainter(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Row(
                      children: [
                        _item(0, items[0]),
                        _item(1, items[1]),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 54,
                            height: 58,
                            child: Image.asset(
                              'assets/img/HomeCliente/Frame_LogoNavbar.png',
                              fit: BoxFit.contain,
                              semanticLabel: 'INCOEX',
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        _item(2, items[2]),
                        _item(3, items[3]),
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

  Widget _item(int index, AppNavBarItem item) {
    final active = current == index;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(index),
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 70 : 62,
            height: 68,
            decoration: active
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: .24)),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: item.assetPath == null
                      ? Icon(item.icon, color: Colors.white, size: 25)
                      : Image.asset(
                          item.assetPath!,
                          fit: BoxFit.contain,
                          semanticLabel: item.label,
                          errorBuilder: (_, __, ___) => Icon(
                            item.icon,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
                  color: active ? Colors.white : Colors.transparent,
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
    canvas.drawLine(
      Offset(size.height / 2, .9),
      Offset(size.width - size.height / 2, .9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x66FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _NavBorderPainter oldDelegate) => false;
}
