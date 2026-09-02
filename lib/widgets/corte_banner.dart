import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import 'glass.dart';

/// Aviso de corte de pago pendiente: aparece en la home del cliente cuando la
/// API tiene recibos (cortes) pendientes, con su detalle expandible.
class CorteBanner extends StatefulWidget {
  const CorteBanner({super.key});

  @override
  State<CorteBanner> createState() => _CorteBannerState();
}

class _CorteBannerState extends State<CorteBanner> {
  List<Map<String, dynamic>> cortes = [];
  bool loading = true;
  String? expandedId;
  Timer? timer;

  String get _client => apiClient.currentUser?.displayName ?? '';

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final name = _client.trim().toLowerCase();
    if (name.isEmpty) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final all = await apiClient.getPendingCortes();
      final mine = all
          .where((corte) =>
              (corte['client']?.toString().trim().toLowerCase() ?? '') == name)
          .toList();
      if (mounted) {
        setState(() {
          cortes = mine;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || cortes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        onTap: () => setState(() {
          expandedId = expandedId == null
              ? cortes.first['id']?.toString()
              : null;
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cyan.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: cyan, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cortes.length > 1
                            ? 'Tienes ${cortes.length} cortes de pago pendientes'
                            : 'Tienes 1 corte de pago pendiente',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toca para ver el detalle de tu recibo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expandedId == null
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TotalBadge(cortes: cortes),
            if (expandedId != null) ...[
              const SizedBox(height: 10),
              for (final corte in cortes) _CorteDetail(corte: corte),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.cortes});

  final List<Map<String, dynamic>> cortes;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final corte in cortes) {
      total += (corte['grandTotalCs'] as num?)?.toDouble() ?? 0;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: mint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: mint.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total a pagar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          Text(
            'C\$ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: mint,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorteDetail extends StatelessWidget {
  const _CorteDetail({required this.corte});

  final Map<String, dynamic> corte;

  @override
  Widget build(BuildContext context) {
    final items = (corte['items'] as List?) ?? const [];
    final total = (corte['totalCs'] as num?)?.toDouble() ?? 0;
    final prev = (corte['previousDebtCs'] as num?)?.toDouble() ?? 0;
    final grand = (corte['grandTotalCs'] as num?)?.toDouble() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 18, color: glassBorder),
        for (final any in items) _ItemRow(item: (any as Map).cast<String, dynamic>()),
        const SizedBox(height: 6),
        _SummaryRow(title: 'Corte', value: '${corte['periodLabel'] ?? ''}'),
        if (prev > 0)
          _SummaryRow(title: 'Saldo anterior', value: 'C\$ ${prev.toStringAsFixed(2)}'),
        _SummaryRow(title: 'Total del periodo', value: 'C\$ ${total.toStringAsFixed(2)}'),
        _SummaryRow(
          title: 'Total a pagar',
          value: 'C\$ ${grand.toStringAsFixed(2)}',
          bold: true,
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              item['date']?.toString() ?? '',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${item['origin']} → ${item['destination']}',
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
          Text(
            'C\$ ${((item['priceCs'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.value,
    this.bold = false,
  });

  final String title;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: bold ? mint : Colors.white,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 14 : 12.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
