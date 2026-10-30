# Permiso de pago de facturas por perfil

## Intención

Permitir que el supervisor decida, perfil por perfil, quién puede pagar facturas pendientes. Un perfil sin permiso seguirá viendo el historial y el detalle de las facturas, pero no verá acciones de pago y el API rechazará cualquier intento de registrar uno.

## Objetivos

- Agregar un permiso independiente `Puede pagar facturas` a cada perfil operativo.
- Mostrar y editar ese permiso desde “Perfiles de empresa”, solo para el supervisor.
- Mostrar los botones de pago únicamente al supervisor o a perfiles con el permiso activo.
- Validar la autorización en el backend para que ocultar el botón no sea la única protección.
- Mantener intacta la visualización del historial y de las facturas pendientes.

## Fuera de alcance

- No se agregan permisos para otros módulos.
- No se cambia quién puede ver facturas.
- No se modifica el flujo de creación de perfiles ni el cambio de contraseña.
- No se cambia el cálculo, método o estado de los pagos.

## Enfoque elegido

Se agregará una columna persistente `can_pay_invoices` en `company_profiles`. El supervisor podrá actualizarla mediante el endpoint existente de perfiles. La respuesta de perfiles y la sesión incluirán `canPayInvoices`.

El API de pago de facturas resolverá la sesión activa: el supervisor siempre podrá pagar; un perfil operativo solo podrá hacerlo cuando `can_pay_invoices = 1`; de lo contrario responderá con `Forbidden` y no cambiará el estado de la factura. La consulta de facturas continuará disponible para todos los perfiles que ya puedan verla.

En Flutter, cada tarjeta de perfil operativo tendrá un interruptor secundario “Pagar facturas”. En el resumen de facturas se ocultarán los botones “Pagar” y “Pagar todas las facturas pendientes” cuando el permiso del perfil activo esté apagado. El supervisor conservará siempre esas acciones.

## Datos y compatibilidad

- La columna nueva tendrá valor predeterminado `0` para perfiles operativos existentes.
- El supervisor se tratará como autorizado aunque su columna no exista o tenga valor falso, evitando bloquear la cuenta principal.
- Las respuestas antiguas sin `canPayInvoices` se interpretarán como `false` para perfiles operativos.

## Archivos previstos

- API: esquema/migración de `company_profiles`, `operations.store.ts`, `profiles.controller.ts`, `cortes.controller.ts` y pruebas de autorización.
- Flutter: `CompanyProfile`, `ApiClient`, `perfiles_empresa.dart`, `resumen_cliente.dart` y una regla pequeña testeable para decidir si se muestran acciones de pago.

## Verificación

- Un perfil nuevo inicia sin permiso para pagar.
- El supervisor puede activar y desactivar el permiso y al recargar se conserva.
- Un perfil sin permiso puede consultar facturas, pero el API rechaza pagar.
- Un perfil con permiso puede pagar y el estado de la factura cambia como antes.
- El supervisor puede pagar aunque el permiso almacenado no esté activo.
- La app oculta las acciones solo cuando corresponde y no oculta la factura.
