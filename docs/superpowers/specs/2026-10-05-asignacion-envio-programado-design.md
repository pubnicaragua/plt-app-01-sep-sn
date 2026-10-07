# Asignación y seguimiento de envíos — Diseño

## Objetivo

Después de confirmar la cobertura del seguro, los envíos de carga/entrega deben mostrar una pantalla de búsqueda de conductor, pasar a una pantalla de envío asignado cuando la API confirme la asignación y conservar el seguimiento del envío programado hasta su fecha. El flujo de Viajes/Taxi no debe mostrar seguro ni esta pantalla adicional.

## Alcance

- Reutilizar la creación real de envío y el seguimiento existentes.
- Añadir una vista de asignación para cliente con el camión animado del diseño.
- Añadir una vista de envío/viaje asignado con fecha, ticket y servicio.
- Mantener el flujo Taxi/Viajes sin seguro y sin la pantalla de seguro.
- Para programados, abrir el seguimiento/mapa después de la asignación y mantener visible el estado hasta la fecha programada.

## Animación

El archivo `sprite-max-px-frames-36-rows-6-cols-6 (38) 2.svg` contiene una imagen embebida de 720×430 organizada como sprite de 6 columnas por 6 filas. No es un GIF autónomo. Se conservará el movimiento original mostrando sus 36 cuadros en secuencia mediante un widget de sprite; no se redibujará ni se inventará una animación nueva.

## Flujo y estados

1. `SeguroEnvioScreen` devuelve la opción elegida.
2. `Confirmarpedido` crea el envío y pasa a `AsignandoEnvioScreen` en lugar de abrir directamente el seguimiento.
3. `AsignandoEnvioScreen` consulta el envío hasta que el estado sea `Asignado`, mostrando el sprite y un estado de búsqueda.
4. Cuando se asigna, `EnvioAsignadoScreen` muestra el camión, el estado, la fecha programada, el ticket y el tipo de servicio. El texto usa “Envío asignado” para carga/envío y “Viaje asignado” para viajes si el flujo lo reutiliza en el futuro.
5. El botón principal lleva a `SeguimientoPedido`. Para programados se conserva `scheduledDate`, `scheduledTime` e `isScheduled`; el mapa queda disponible y muestra el estado pendiente hasta que empiece el servicio.
6. Si la creación o consulta falla, la pantalla de asignación muestra error y permite reintentar sin duplicar la solicitud.

## Contratos

- La navegación de asignación recibe el `tripId` creado y el `Trip` inicial cuando esté disponible.
- La selección del seguro continúa llegando como `TripOptionSelection` dentro de `options`.
- `SeguimientoPedido` sigue siendo la fuente de mapa/estado; no se duplica su lógica geográfica.
- Viajes/Taxi conserva su navegación directa actual.

## Criterios de aceptación

- El sprite muestra el movimiento del asset entregado, no un icono estático.
- Tras confirmar un envío, nunca se salta directamente al mapa sin pasar por asignación.
- Un estado `Asignado` muestra la tarjeta de asignación con información dinámica del envío.
- Un envío programado conserva la fecha/hora y puede entrar al seguimiento sin perder esos datos.
- Un fallo de API permite reintentar y no crea otra solicitud automáticamente.
- El flujo Taxi/Viajes no muestra seguro ni altera su navegación actual.
