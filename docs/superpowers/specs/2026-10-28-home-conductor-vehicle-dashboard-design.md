# Diseño: dashboard de Home Conductor conectado al vehículo del perfil

## Intención

Reorganizar `HomeConductor` para acercarlo a la estructura de la referencia: vehículo asignado arriba, resumen de viajes debajo y lista de envíos/viajes asignados al final. Se conservan los colores, el fondo, las acciones existentes y la lógica actual de actualización.

## Datos y regla de prioridad

- Fuente principal: `apiClient.currentUser.vehicle` y `apiClient.currentUser.plate`, porque representan el vehículo guardado para el conductor.
- La pantalla debe refrescar esos datos junto con la información del conductor cuando se actualice el perfil o se vuelva a cargar la pantalla.
- Respaldo: si el perfil no tiene vehículo, usar el vehículo del primer viaje asignado mediante `vehicleVariant`, `truckType` o `transport`.
- El icono, nombre del vehículo y placa deben derivarse de la misma fuente para no mostrar combinaciones inconsistentes.

## Alcance

- Cambiar únicamente la estructura visual de `HomeConductor`.
- Mantener los colores actuales del proyecto.
- Mantener los contadores de asignados, en camino y completados.
- Mostrar debajo los viajes/envíos asignados usando las tarjetas y acciones existentes.
- Mantener combustible, actividad, actualizar, navegación y polling actuales.

## No alcance

- No cambiar endpoints ni el modelo de viajes.
- No inventar vehículos, placas o viajes.
- No alterar el flujo de `ViajeAsignado` ni `ViajeEnCurso`.

## Enfoques considerados

1. Reestructurar directamente `HomeConductor` y reutilizar sus datos y widgets actuales. Elegido: minimiza riesgo y permite que los cambios del perfil se reflejen en la pantalla.
2. Crear un dashboard nuevo y reemplazar la pantalla actual. Se descarta porque duplicaría carga, navegación y estados.

## Resultado esperado

La pantalla conserva la identidad visual actual, pero muestra arriba el vehículo real del conductor con su imagen/icono y placa, después los contadores y finalmente los viajes asignados, en camino y completados.
