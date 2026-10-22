# Perfiles empresariales en la app

## Objetivo

Permitir que una cuenta empresarial tenga varios perfiles de trabajo dentro de la aplicación móvil. Cada perfil podrá iniciar sesión con sus propias credenciales y verá únicamente sus viajes, envíos e historial de facturas. El perfil supervisor conservará el acceso principal y podrá consultar toda la operación de la empresa.

La web queda fuera de esta primera etapa, pero el modelo de datos debe dejar preparada la relación entre empresa, perfiles y registros para incorporarla después.

## Alcance de esta etapa

- Mantener la cuenta empresarial existente.
- Convertir el usuario actual de la cuenta en el perfil supervisor sin perder sus datos ni su acceso.
- Permitir al supervisor crear, editar, desactivar y restablecer la contraseña de perfiles.
- Permitir acceso con nombre de usuario del perfil y contraseña.
- Permitir acceso con correo empresarial y la contraseña única del perfil.
- Asociar cada viaje, envío y factura nueva con el perfil que la creó.
- Filtrar la app automáticamente según el perfil autenticado.
- Permitir al supervisor cambiar entre sus perfiles y consultar todos los registros.
- Mantener la lógica actual de creación de viajes, envíos, facturas y seguimiento.

Fuera de alcance: panel web, permisos avanzados por módulo, invitaciones por correo, recuperación de contraseña por correo y reportes nuevos.

## Roles y comportamiento

### Supervisor

El supervisor corresponde a la cuenta principal creada durante el registro. Puede:

- ver sus propios registros;
- ver todos los registros de la empresa;
- crear, editar, desactivar y reactivar perfiles;
- asignar o restablecer credenciales de perfiles;
- cambiar el perfil activo dentro de la app.

### Perfil operativo

Un perfil operativo pertenece a una única cuenta empresarial. Puede:

- iniciar sesión con su usuario o con el correo empresarial y su contraseña propia;
- crear y consultar sus viajes y envíos;
- consultar sus facturas e historial;
- ver únicamente los datos asociados a su `profileId`.

Un perfil operativo no puede consultar ni cambiar otros perfiles.

## Modelo de datos

Se añadirá una entidad de perfil empresarial vinculada a la cuenta principal:

- `id`: identificador estable del perfil.
- `accountId`: identificador de la cuenta empresarial.
- `username`: nombre de usuario único dentro de la cuenta.
- `displayName`: nombre visible que el supervisor asigna al perfil.
- `passwordHash`: contraseña almacenada únicamente como hash.
- `role`: `supervisor` u `operator`.
- `status`: activo o inactivo.
- `createdAt` y `updatedAt`.

Los registros operativos deberán incorporar `profileId` y conservar `accountId` para separar por empresa. Los registros existentes se migrarán al perfil supervisor para que ningún viaje, envío o factura desaparezca.

## Inicio de sesión

El formulario actual seguirá aceptando un identificador y una contraseña.

- Si el identificador coincide con un usuario de perfil, se valida la contraseña contra ese perfil.
- Si coincide con el correo empresarial, se busca el perfil activo de esa empresa cuya contraseña única coincida.
- Si corresponde a la cuenta principal, se inicia sesión como supervisor.
- Una contraseña no podrá reutilizarse entre perfiles de la misma empresa cuando se use el correo empresarial como identificador; de lo contrario el sistema no podría determinar qué perfil abrir.
- El token de sesión debe incluir o resolver el `accountId`, `profileId` y rol para que el API aplique autorización en cada consulta.

## Flujo de la app

1. El supervisor entra a “Tú” y abre “Perfiles de empresa”.
2. Crea un perfil con nombre de usuario, nombre visible y contraseña.
3. El perfil aparece en la lista con estado activo.
4. El usuario puede cerrar sesión y entrar con las credenciales del perfil.
5. La app carga el perfil activo y filtra sus viajes, envíos, facturas, notificaciones y resumen.
6. El supervisor puede cambiar de perfil desde la app sin crear otra cuenta empresarial.
7. Al crear un registro nuevo, el API asigna el `profileId` de la sesión; el cliente no debe poder elegir otro perfil arbitrariamente.

## API y seguridad

- Los endpoints de autenticación deberán resolver supervisor y perfiles.
- Los endpoints de viajes, envíos, facturas y resúmenes deben filtrar por `accountId` y, salvo para supervisor, por `profileId`.
- La autorización debe vivir en el API, no únicamente en la interfaz móvil.
- Un perfil inactivo no podrá iniciar sesión y sus sesiones deberán invalidarse al desactivarlo.
- La app recibirá el perfil activo en la respuesta de login y lo conservará en la sesión actual.
- Las contraseñas existentes y nuevas se almacenarán con el mecanismo de hash ya utilizado por el API.

## Compatibilidad y migración

- Las cuentas actuales seguirán funcionando con su correo y contraseña.
- Cada cuenta existente recibirá un perfil supervisor basado en su usuario actual.
- Los registros existentes se asociarán al supervisor.
- Mientras se completa la migración, el API podrá usar el supervisor como fallback para registros sin `profileId`, evitando que queden invisibles.
- No se cambiará la lógica de estados, historial ni facturación; solo se añadirá el alcance del perfil.

## Criterios de aceptación

- Un supervisor puede crear un perfil y volver a verlo en la sección de perfiles.
- El perfil puede iniciar sesión con usuario y contraseña.
- El perfil puede iniciar sesión con el correo empresarial y su contraseña única.
- Dos perfiles de la misma empresa no pueden acceder a los registros del otro.
- Un supervisor puede consultar todos los registros de su empresa.
- Un registro creado desde un perfil aparece en el historial y resumen de ese perfil.
- Los datos actuales continúan visibles después de la migración.
- Desactivar un perfil impide nuevos accesos y no elimina sus registros históricos.
- Una cuenta empresarial no puede acceder a perfiles ni registros de otra cuenta.

## Verificación

Se cubrirán con pruebas:

- resolución de login de supervisor;
- login por usuario de perfil;
- login por correo empresarial y contraseña de perfil;
- rechazo de perfil inactivo o contraseña incorrecta;
- filtros por `accountId` y `profileId`;
- visibilidad total para supervisor;
- migración de registros existentes al supervisor;
- aislamiento de viajes, envíos, facturas y resúmenes entre perfiles.
