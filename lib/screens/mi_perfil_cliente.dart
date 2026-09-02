import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/glass.dart';
import 'inicio.dart';

class MiPerfilCliente extends StatefulWidget {
  const MiPerfilCliente({super.key});

  @override
  State<MiPerfilCliente> createState() => _MiPerfilClienteState();
}

class _MiPerfilClienteState extends State<MiPerfilCliente> {
  @override
  Widget build(BuildContext context) {
    final name = apiClient.currentUser?.displayName ?? 'Incoex Logistics';
    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          children: [
            const Center(child: BrandLockup()),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      shape: BoxShape.circle,
                      border: Border.all(color: glassBorder, width: 1.4),
                    ),
                    child: Center(
                      child: Text(
                        initials(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Perfil de Empresa',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: mint.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: mint.withValues(alpha: .4)),
                    ),
                    child: const Text(
                      '✦ 1,240 Envíos Realizados',
                      style: TextStyle(
                        color: mint,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassButton(
              label: 'Editar Perfil',
              icon: Icons.edit_outlined,
              onPressed: () {},
              height: 50,
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Completa los pasos de tu perfil que no has completado',
                    style: TextStyle(
                      color: Color(0xFFB9D4FF),
                      fontSize: 12.5,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(height: 13),
                  _step(
                    done: true,
                    icon: Icons.apartment_rounded,
                    label: 'Sucursales y Direcciones',
                  ),
                  const SizedBox(height: 11),
                  _step(
                    done: false,
                    icon: Icons.payment_rounded,
                    label: 'Método de pago',
                  ),
                  const SizedBox(height: 11),
                  _step(
                    done: false,
                    icon: Icons.contact_phone_outlined,
                    label: 'Contactos autorizados',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: cyan, size: 20),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soporte INCOEX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                        Text(
                          'helpdesk@incoex.com · 505 8888-0000',
                          style: TextStyle(
                            color: Color(0xFFB9D4FF),
                            fontSize: 11,
                            fontFamily: 'Acumin Pro',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white54),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: () {
                  apiClient.accessToken = null;
                  apiClient.currentUser = null;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const Inicio()),
                    (_) => false,
                  );
                },
                child: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step({
    required bool done,
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (done ? mint : cyan).withValues(alpha: .14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            color: done ? mint : cyan,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Acumin Pro',
            ),
          ),
        ),
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.chevron_right_rounded,
          color: done ? mint : Colors.white38,
          size: 19,
        ),
      ],
    );
  }
}
