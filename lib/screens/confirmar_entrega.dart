import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../widgets/glass.dart';
import 'home_conductor.dart';

class ConfirmarEntrega extends StatefulWidget {
  const ConfirmarEntrega({super.key, required this.trip});

  final Trip trip;

  @override
  State<ConfirmarEntrega> createState() => _ConfirmarEntregaState();
}

class _ConfirmarEntregaState extends State<ConfirmarEntrega> {
  String picked = 'Entregado con éxito';
  bool updating = false;

  Future<void> _submit() async {
    if (updating) return;
    setState(() => updating = true);
    try {
      await apiClient.updateTripStatus(
        widget.trip.id,
        picked == 'Entregado con éxito' ? 'Completado' : 'Cancelado',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeConductor()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'No se pudo registrar. Verifica tu conexión.',
              style: TextStyle(fontFamily: 'Acumin Pro'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F52),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          shape: BoxShape.circle,
                          border: Border.all(color: glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Confirmar Entrega',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B6DF5).withValues(alpha: .30),
                            const Color(0xFF3B6DF5).withValues(alpha: .12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0x553B6DF5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B6DF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Llegaste al destino de entrega',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Acumin Pro',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFDFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Detalles del envío',
                                  style: TextStyle(
                                    color: Color(0xFF10224A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Acumin Pro',
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFFE7EEFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Viaje ${trip.id}',
                                  style: const TextStyle(
                                    color: Color(0xFF0D47D9),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Acumin Pro',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(color: Color(0x2210224A), height: 1),
                          const SizedBox(height: 13),
                          _DetailRow(
                            icon: Icons.person_rounded,
                            label: 'Cliente',
                            value:
                                trip.recipientName ?? trip.contactName ?? 'Cliente',
                          ),
                          const SizedBox(height: 15),
                          _DetailRow(
                            icon: Icons.near_me_rounded,
                            label: 'Dirección de entrega',
                            value: trip.destination,
                          ),
                          const SizedBox(height: 15),
                          _DetailRow(
                            icon: Icons.inventory_2_rounded,
                            label: 'Paquetes',
                            value: '${trip.packages} unidad${trip.packages == 1 ? '' : 'es'} certificada${trip.packages == 1 ? '' : 's'}',
                          ),
                          if (trip.estimatedCostCs != null) ...[
                            const SizedBox(height: 15),
                            _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Precio del viaje',
                              value:
                                  'C\$${trip.estimatedCostCs!.toStringAsFixed(2)}',
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '¿Se realizó la entrega?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Acumin Pro',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _OptionButton(
                            label: 'Entregado con éxito',
                            picked: picked == 'Entregado con éxito',
                            filled: true,
                            onTap: () => setState(
                                () => picked = 'Entregado con éxito'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OptionButton(
                            label: 'No entregado',
                            picked: picked == 'No entregado',
                            filled: false,
                            onTap: () =>
                                setState(() => picked = 'No entregado'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 54,
                      child: Material(
                        color: updating
                            ? const Color(0xFF0B3DBB)
                            : const Color(0xFF0D47D9),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _submit,
                          child: Center(
                            child: updating
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Registrar entrega',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Acumin Pro',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        picked == 'Entregado con éxito'
                            ? 'El viaje pasará a tu historial de completados.'
                            : 'El viaje se marcará como cancelado.',
                        style: const TextStyle(
                          color: Color(0xFFB9D4FF),
                          fontSize: 11,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D47D9), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A87A8),
                  fontSize: 10.5,
                  fontFamily: 'Acumin Pro',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF10224A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.picked,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool picked;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = picked
        ? const Color(0xFF0D47D9)
        : const Color(0xFFD7DCE8);
    final bg = picked
        ? filled
            ? const Color(0xFFE7EEFF)
            : const Color(0xFFEFEFF3)
        : const Color(0xFFF5F6F9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filled ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: const Color(0xFF0D47D9),
              size: 17,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0D47D9),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Acumin Pro',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
