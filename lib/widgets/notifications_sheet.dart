import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/api_models.dart';
import '../screens/seguimiento_pedido.dart';
import 'glass.dart';

Future<void> showAppNotifications(BuildContext context) async {
  final user = apiClient.currentUser;
  final companyName = user?.companyName?.trim();
  final client = user != null &&
          (user.role == 'corporate' || user.role == 'company')
      ? (companyName?.isNotEmpty == true ? companyName : user.displayName.trim())
      : null;

  List<Trip> trips = const [];
  String? error;
  try {
    trips = await apiClient.getTrips(client: client);
  } catch (_) {
    error = 'No se pudieron consultar las novedades.';
  }
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _NotificationsSheet(
      trips: trips.take(8).toList(growable: false),
      error: error,
      onTripTap: (trip) {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SeguimientoPedido(trip: trip)),
        );
      },
    ),
  );
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({
    required this.trips,
    required this.onTripTap,
    this.error,
  });

  final List<Trip> trips;
  final String? error;
  final ValueChanged<Trip> onTripTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 520),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xEE34578F), Color(0xE9162C64)],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: .28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          color: Colors.white, size: 22),
                      SizedBox(width: 9),
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Actualizaciones de tus envíos',
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 12,
                      fontFamily: 'Acumin Pro',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (error != null)
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    )
                  else if (trips.isEmpty)
                    const GlassCard(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No tienes novedades por ahora.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Acumin Pro',
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: trips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _NotificationRow(
                          trip: trips[index],
                          onTap: () => onTripTap(trips[index]),
                        ),
                      ),
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = trip.status == 'Completado';
    final color = completed ? mint : cyan;
    final message = switch (trip.status) {
      'Completado' => 'La entrega fue confirmada.',
      'En entrega' => 'El conductor está llegando al destino.',
      'En camino' => 'El conductor está trasladando tu envío.',
      'Asignado' => 'Ya hay un conductor asignado.',
      'Cancelado' || 'Anulado' => 'El envío fue cancelado.',
      _ => 'La solicitud está pendiente de asignación.',
    };
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: .42)),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.local_shipping_outlined,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viaje ${trip.id}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 11,
                    fontFamily: 'Acumin Pro',
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: .8), size: 20),
        ],
      ),
    );
  }
}
