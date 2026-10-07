# Plan de implementación: asignación y seguimiento de envíos

> **Para agentes de implementación:** usar `superpowers:executing-plans` para ejecutar este plan tarea por tarea.

**Objetivo:** Implementar el flujo aprobado después del seguro: sprite animado real, búsqueda de conductor, pantalla de envío asignado y continuidad del seguimiento programado, conservando el flujo de Viajes.

**Arquitectura:** `Confirmarpedido` seguirá siendo el punto de envío. Después de crear la solicitud, los envíos/cargas pasarán por una pantalla de asignación que consultará el estado del viaje. La animación usará los 36 cuadros del sprite entregado y el mapa seguirá reutilizando `SeguimientoPedido`.

**Tecnología:** Flutter/Dart, `apiClient`, modelos `Trip`/`TripOptionSelection`, `AppGlassSurface`, `GlassButton` y la pantalla de seguimiento existente.

**Diseño:** `docs/superpowers/specs/2026-10-05-asignacion-envio-programado-design.md`

## Restricciones globales

- Usar el sprite entregado en formato 6×6; no inventar otra animación.
- Viajes/Taxi conserva su flujo actual y no muestra seguro ni asignación de carga.
- Mantener fecha, hora programada, tipo de servicio, seguro y opciones seleccionadas.
- Reutilizar la lógica del mapa en `SeguimientoPedido`.
- Verificar manualmente y con comprobaciones del repositorio, sin crear archivos de pruebas automatizadas.

## Puntos de revisión

- El sprite muestra un cuadro individual por vez y no la hoja completa.
- Un estado pendiente no se muestra como asignado antes de tiempo.
- Los errores permiten reintentar sin crear solicitudes duplicadas.
- Los programados conservan fecha/hora y llegan al mapa existente.
- Viajes/Taxi nunca entra en las pantallas nuevas de seguro/asignación.

---

### Tarea 1: Preparar el sprite del camión

**Archivos:**
- Crear: `assets/img/EstadosCrearEnvio/camion_asignacion_sprite.png`
- Modificar: `pubspec.yaml` solo si la carpeta no está incluida.

- [ ] Extraer del SVG la imagen PNG embebida de 720×430 sin alterar sus píxeles.
- [ ] Guardar el sprite en la carpeta de assets de estados y verificar que Flutter pueda cargarlo.
- [ ] Confirmar la geometría de 36 cuadros: 6 columnas × 6 filas.

### Tarea 2: Crear el widget de animación

**Archivos:**
- Crear: `lib/widgets/sprite_truck_animation.dart`

**Interfaz:**
`SpriteTruckAnimation({required String asset, int rows = 6, int columns = 6, Duration frameDuration = const Duration(milliseconds: 90), BoxFit fit = BoxFit.contain})`.

- [ ] Crear un widget que recorra los cuadros del 0 al 35 y repita la animación.
- [ ] Dibujar únicamente la celda actual mediante recorte, conservando la proporción.
- [ ] Liberar correctamente el controlador o temporizador al destruir el widget.
- [ ] Mostrar un fallback si el asset no carga.

### Tarea 3: Integrar la asignación después de crear el envío

**Archivos:**
- Crear: `lib/screens/asignando_envio.dart`
- Modificar: `lib/screens/crear_envio3.dart`

**Interfaz:**
`AsignandoEnvioScreen({required String tripId, required Trip initialTrip, required bool isScheduled})`.

- [ ] Mostrar el sprite y el estado “Asignando conductor”.
- [ ] Consultar el viaje usando la API existente hasta recibir estado `Asignado`.
- [ ] Detener la consulta al asignar, fallar o salir de la pantalla.
- [ ] Permitir reintentar sin duplicar la solicitud.
- [ ] Mantener las opciones del viaje, incluido el seguro.
- [ ] Mantener Viajes/Taxi fuera de este flujo.

### Tarea 4: Crear la pantalla de envío asignado

**Archivos:**
- Crear: `lib/screens/envio_asignado.dart`
- Modificar: `lib/screens/asignando_envio.dart`

**Interfaz:**
`EnvioAsignadoScreen({required Trip trip})`.

- [ ] Mostrar camión, confirmación, título de envío asignado, fecha, hora, ticket y servicio.
- [ ] Usar los datos reales del objeto `Trip` con valores alternativos seguros.
- [ ] Diferenciar “Envío asignado” y “Viaje asignado” según corresponda.
- [ ] Llevar el botón principal a `SeguimientoPedido(trip: trip)`.
- [ ] Mantener el comportamiento de regresar sin crear otra solicitud.

### Tarea 5: Verificar programados e integración

**Archivos:**
- Modificar solo si es necesario: `lib/screens/seguimiento_pedido.dart`.

- [ ] Revisar los flujos Express, Programado, Camión y Viajes desde sus puntos de entrada.
- [ ] Confirmar que fecha, hora y tipo programado sobreviven a la asignación.
- [ ] Confirmar que el mapa existente recibe el `Trip` completo.
- [ ] Ejecutar `git diff --check` y comprobar assets.
- [ ] Intentar el análisis de Flutter; si vuelve a bloquearse, reportarlo sin alterar el código.
