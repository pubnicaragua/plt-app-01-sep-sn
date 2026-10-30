# Historial único y total recaudado

## Intención

Evitar que el conductor vea dos historiales y concentrar el historial en la pantalla `Historial de viajes`, agregando el acumulado de servicios completados.

## Alcance

- Quitar del home el bloque duplicado `Mi historial`.
- Mantener la pantalla `Historial de viajes` accesible desde el menú del conductor.
- Mostrar `Total recaudado` con la suma de `estimatedCostCs` de los viajes completados cargados para el conductor.
- No cambiar tarifas, estados, API ni el diseño general del historial.

## Enfoque

Se calculará el total a partir de la misma lista filtrada de viajes completados que alimenta la pantalla de historial. Esto evita valores fijos y mantiene el importe alineado con la API. La alternativa de duplicar el cálculo en el home se descarta porque conserva la duplicación que se quiere eliminar.

## Criterios de aceptación

- El home no muestra `Mi historial` ni una tarjeta de historial.
- Historial muestra `Total recaudado`.
- El total suma solo viajes completados y tolera viajes sin tarifa como cero.
- La lista de viajes y su estado siguen funcionando igual.
