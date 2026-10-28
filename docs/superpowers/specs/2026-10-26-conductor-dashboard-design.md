# Diseño: dashboard operativo compacto para conductor

## Intención

Actualizar la pantalla inicial de `HomeConductor` para que comparta el lenguaje visual de la vista cliente, pero mantenga la lectura rápida y las acciones propias del conductor. La pantalla debe dejar claro qué viaje requiere atención, cuál es el siguiente paso y si la ubicación está activa.

## Alcance

- Conservar el fondo, tipografía Figtree, colores azules y superficies glass del resto de la app.
- Reordenar la pantalla alrededor de un bloque principal de estado operativo y del viaje asignado más próximo.
- Mostrar de forma visible el estado de GPS/conexión usando el estado que ya obtiene la app.
- Mantener el acceso a notificaciones, combustible, viajes asignados, próximos viajes e historial.
- Añadir accesos rápidos visuales para combustible, incidencias y actividad/historial sin crear nuevos flujos de negocio.
- Mantener intactas las rutas existentes: `ViajeAsignado`, `ViajeEnCurso`, confirmación de entrega y cierre de sesión.

## Fuera de alcance

- No cambiar la asignación de viajes ni la máquina de estados.
- No crear un WebSocket ni reemplazar el polling actual.
- No agregar todavía un interruptor que modifique la disponibilidad del conductor en la API.
- No alterar permisos, autenticación ni la relación de datos entre cliente y conductor.

## Dirección elegida

### Dashboard operativo compacto

Se eligió esta opción porque aprovecha la pantalla actual, conserva sus funciones y permite acercarla visualmente a clientes sin convertirla en una pantalla de mapa ni esconder viajes detrás de pestañas.

## Estructura propuesta

1. **Encabezado:** avatar/nombre, campana de notificaciones y una cápsula de estado con “GPS activo” o estado de ubicación disponible.
2. **Saludo breve:** conservar el saludo, con el texto secundario adaptado al estado de ubicación.
3. **Resumen operativo:** una tarjeta glass compacta con viajes asignados, viajes en curso y viajes completados del conjunto ya cargado.
4. **Viaje principal:** conservar la tarjeta clara de alto contraste, pero darle más jerarquía al estado, ruta origen-destino, paquetes, hora/fecha y acción “Ver viaje”.
5. **Acciones rápidas:** tres accesos consistentes con el diseño cliente: registrar combustible, reportar incidencia y ver actividad/historial. El segundo y tercero reutilizarán los flujos existentes o navegación disponible.
6. **Viajes restantes:** próximos viajes e historial se mantienen debajo, con tarjetas más compactas y el mismo tratamiento visual.

## Reglas visuales

- La tarjeta del viaje principal seguirá siendo clara/blanca para destacar sobre el fondo azul.
- Las tarjetas secundarias usarán glass azul con bordes suaves y estados en azul, verde o ámbar.
- Los botones principales conservarán el azul brillante y el radio de la vista cliente.
- La pantalla debe seguir funcionando en tamaños móviles estrechos sin desbordar; las acciones secundarias pueden desplazarse horizontalmente si hace falta.
- El estado GPS debe ser informativo y no prometer conexión en tiempo real: la app continúa usando sincronización periódica.

## Datos y comportamiento

- Se reutilizarán `trips`, `location`, `currentUser`, `_assigned`, `_upcoming` y `_history`.
- El polling de viajes cada 15 segundos y la sincronización de ubicación se conservan.
- La tarjeta principal seguirá abriendo `ViajeAsignado` y no iniciará acciones automáticamente.
- Los contadores serán derivados de la información ya cargada, sin nuevas consultas.

## Criterio de éxito

Al abrir la vista, el conductor debe identificar en pocos segundos su estado de conexión, el viaje prioritario, origen, destino, paquetes y siguiente acción; además, combustible, incidencias, notificaciones y actividad deben seguir siendo accesibles sin perder ninguna función existente.

