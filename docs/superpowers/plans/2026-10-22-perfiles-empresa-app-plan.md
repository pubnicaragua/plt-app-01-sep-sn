# Perfiles empresariales en la app Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir perfiles empresariales en la app móvil con login propio, aislamiento de datos y acceso total para el supervisor, sin romper las cuentas ni los registros existentes.

**Architecture:** El API será la autoridad para resolver la cuenta, el perfil activo y los permisos. Se añadirá una entidad de perfiles vinculada a cada usuario empresarial y se incorporarán `accountId`/`profileId` a los registros operativos con migración compatible para datos antiguos. La app mostrará gestión de perfiles al supervisor y enviará/consumirá el perfil activo desde la sesión; la web queda fuera de esta implementación.

**Tech Stack:** Flutter/Dart en `plt-app-01-sep-sn`, NestJS/TypeScript con SQLite en `plt-api-01-sep-sn`, pruebas Dart y Jest existentes.

**Spec:** `docs/superpowers/specs/2026-10-22-perfiles-empresa-app-design.md`

## Global Constraints

- La web queda fuera de esta primera etapa.
- Las contraseñas se almacenan únicamente como hash.
- Los registros existentes se asignan al perfil supervisor y no se eliminan.
- El API debe aplicar `accountId` y `profileId`; la app no puede proteger datos solo ocultando widgets.
- Las cuentas actuales deben seguir entrando con su correo y contraseña.
- No se modificará la lógica de estados, historial ni facturación salvo para añadir el alcance del perfil.

## Review Focus

- Una cuenta existente sin perfil explícito debe seguir viendo todos sus registros después de la migración; prueba de fallback al supervisor.
- Un perfil operativo no debe leer registros de otro perfil cambiando parámetros del cliente; prueba de autorización en API.
- El login por correo empresarial debe resolver exactamente un perfil; prueba de contraseñas duplicadas y de contraseña incorrecta.
- Desactivar un perfil debe impedir nuevos logins e invalidar sesiones; prueba de estado y sesión.
- Un supervisor debe consultar todos los perfiles sin convertir esa vista en acceso permanente a otro perfil; prueba de alcance supervisor vs. perfil activo.

---

### Task 1: Modelo de perfiles y migración SQLite del API

**Files:**
- Modify: `plt-api-01-sep-sn/src/users.store.ts`
- Modify: `plt-api-01-sep-sn/src/operations.store.ts`
- Modify: `plt-api-01-sep-sn/src/domain.ts`
- Create: `plt-api-01-sep-sn/src/profiles.store.ts` (si la separación mantiene el patrón de stores actual)
- Test: `plt-api-01-sep-sn/test/profiles.store.spec.ts` o el directorio de pruebas equivalente existente

**Interfaces:**
- Produces `ProfileRecord` con `id`, `accountId`, `username`, `displayName`, `role`, `status`, `passwordHash`, `createdAt` y `updatedAt`.
- Produces `listProfiles(accountId)`, `createProfile(accountId, input)`, `updateProfile(id, input)`, `setProfileStatus(id, status)` y `findProfileForLogin(identifier, password)`.
- La migración debe asignar registros sin `profileId` al perfil supervisor de su cuenta.

- [ ] **Step 1: Write the failing tests** para crear perfil, impedir usuarios duplicados dentro de una cuenta, guardar hash y migrar registros existentes al supervisor.
- [ ] **Step 2: Run the API tests** y confirmar que fallan por ausencia de tabla, store o columnas.
- [ ] **Step 3: Add the schema migration** para perfiles y columnas `account_id`/`profile_id` en viajes, envíos, facturas o tablas operativas equivalentes, usando migraciones idempotentes.
- [ ] **Step 4: Implement the profile store** usando el hash/verificador de `users.store.ts`; no devolver `passwordHash` en respuestas API.
- [ ] **Step 5: Implement supervisor backfill** para crear o localizar el perfil supervisor y asociar datos antiguos sin perfil.
- [ ] **Step 6: Run the focused API tests** y confirmar creación, hash, aislamiento de unicidad y backfill.
- [ ] **Step 7: Run the API build** con `npm run build`.
- [ ] **Step 8: Commit** con `feat: add company profile persistence`.

### Task 2: Autenticación y sesiones con perfil activo

**Files:**
- Modify: `plt-api-01-sep-sn/src/operations.store.ts`
- Modify: `plt-api-01-sep-sn/src/auth.controller.ts`
- Modify: `plt-api-01-sep-sn/src/dto/login.dto.ts`
- Modify: `plt-api-01-sep-sn/src/domain.ts`
- Test: `plt-api-01-sep-sn/test/auth-profiles.spec.ts`

**Interfaces:**
- Login input conserva `email` como identificador compatible y añade la interpretación de usuario de perfil.
- Login response produce `user`, `profile`, `accountId`, `profileId`, `role` y `accessToken` sin hashes.
- Session resolution devuelve el mismo alcance para que cada request pueda autorizarse.

- [ ] **Step 1: Write failing auth tests** para supervisor existente, usuario+contraseña de perfil, correo empresarial+contraseña única, perfil inactivo y contraseña incorrecta.
- [ ] **Step 2: Run the focused auth tests** y confirmar fallos por falta de resolución de perfiles.
- [ ] **Step 3: Implement login resolution** con prioridad segura: cuenta principal existente, usuario de perfil y correo empresarial con contraseña única; rechazar resultados ambiguos.
- [ ] **Step 4: Extend session records** para conservar `accountId`, `profileId` y rol, invalidando sesiones de perfiles inactivos.
- [ ] **Step 5: Run focused auth tests** y luego `npm run build`.
- [ ] **Step 6: Commit** con `feat: authenticate company profiles`.

### Task 3: Autorización y alcance de operaciones

**Files:**
- Modify: `plt-api-01-sep-sn/src/operations.store.ts`
- Modify: `plt-api-01-sep-sn/src/trips.controller.ts`
- Modify: controllers de facturas, notificaciones y resúmenes que consulten datos operativos
- Test: `plt-api-01-sep-sn/test/profile-scope.spec.ts`

**Interfaces:**
- Introduce un `SessionScope` con `accountId`, `profileId` y `isSupervisor`.
- Introduce una regla de consulta: supervisor filtra por `accountId`; perfil operativo filtra por `accountId` y `profileId`.
- Las mutaciones asignan `profileId` desde la sesión y rechazan un perfil enviado por el cliente que no corresponda.

- [ ] **Step 1: Write failing scope tests** para listar, crear y consultar viajes/envíos, además de resumen e historial, desde dos perfiles distintos.
- [ ] **Step 2: Run scope tests** y confirmar que un perfil todavía puede leer datos ajenos.
- [ ] **Step 3: Implement shared scope helpers** y aplicarlos a cada lectura operativa.
- [ ] **Step 4: Assign profile ownership on create/update** para que el API tome el perfil desde la sesión.
- [ ] **Step 5: Add supervisor all-profiles queries** sin cambiar el estado ni duplicar registros.
- [ ] **Step 6: Run scope tests and full API tests**, then `npm run build`.
- [ ] **Step 7: Commit** con `feat: enforce profile data isolation`.

### Task 4: API client y modelos de sesión en Flutter

**Files:**
- Modify: `plt-app-01-sep-sn/lib/models/api_models.dart`
- Modify: `plt-app-01-sep-sn/lib/core/api_client.dart`
- Modify: `plt-app-01-sep-sn/lib/screens/inicio.dart`
- Modify: `plt-app-01-sep-sn/lib/screens/registro.dart` only if registration response handling requires it
- Test: `plt-app-01-sep-sn/test/profile_session_test.dart`

**Interfaces:**
- `SessionUser` exposes `accountId`, `profileId`, `profileRole`, `isSupervisor` and display information while preserving existing fields.
- `ApiClient.login` keeps its public call shape compatible or adds an optional identifier field without breaking callers.
- New client methods: `getProfiles`, `createProfile`, `updateProfile`, `setProfileStatus` and `switchProfile` if token refresh is needed.

- [ ] **Step 1: Write failing model/client tests** for parsing supervisor/profile login responses and profile management responses.
- [ ] **Step 2: Run focused Flutter tests** and confirm the new fields/methods are absent.
- [ ] **Step 3: Implement response models and API methods** with no password retention in memory beyond the login request.
- [ ] **Step 4: Update login UI** so the existing field accepts email or profile username and preserves current validation/error behavior.
- [ ] **Step 5: Run focused Flutter tests** and format the changed Dart files.
- [ ] **Step 6: Commit** con `feat: support profile sessions in app`.

### Task 5: Gestión de perfiles desde “Tú”

**Files:**
- Modify: `plt-app-01-sep-sn/lib/screens/mi_perfil_cliente.dart`
- Create: `plt-app-01-sep-sn/lib/screens/perfiles_empresa.dart`
- Modify: `plt-app-01-sep-sn/lib/screens/inicio.dart` only for logout/profile entry flow
- Test: `plt-app-01-sep-sn/test/perfiles_empresa_test.dart`

**Interfaces:**
- Supervisor-only screen consumes `ApiClient.getProfiles()` and profile mutation methods.
- The screen displays name, username and status, never the password.
- Inactive profiles can be reactivated; deleting a profile is not allowed in this first version to preserve historical ownership.

- [ ] **Step 1: Write failing widget tests** for supervisor visibility, create validation, inactive state and hidden profile management for operators.
- [ ] **Step 2: Run widget tests** and confirm the route/widget is missing.
- [ ] **Step 3: Implement the “Perfiles de empresa” entry** in “Tú” and the management screen using existing visual components.
- [ ] **Step 4: Implement create/edit/status dialogs** with unique username and password validation.
- [ ] **Step 5: Run widget tests** and verify loading, empty, error and success states.
- [ ] **Step 6: Commit** con `feat: manage company profiles in app`.

### Task 6: Perfil activo, filtrado de UI y supervisor switch

**Files:**
- Modify: `plt-app-01-sep-sn/lib/screens/home_cliente.dart`
- Modify: `plt-app-01-sep-sn/lib/screens/envios.dart`
- Modify: `plt-app-01-sep-sn/lib/screens/resumen_cliente.dart`
- Modify: screens and widgets that display current user or fetch operational records
- Test: `plt-app-01-sep-sn/test/profile_visibility_test.dart`

**Interfaces:**
- All existing app reads continue using API responses already scoped to the session.
- Supervisor profile switch refreshes the active session/data and clears stale screen futures/caches.
- The active profile name is visible in the app’s account area so the user knows where they are operating.

- [ ] **Step 1: Write failing integration/widget tests** for profile-only data, supervisor all-data view, switch refresh and no stale records after logout.
- [ ] **Step 2: Run the tests** and confirm current app has no profile-aware state.
- [ ] **Step 3: Add active-profile state and refresh boundaries** without duplicating trips or altering status transitions.
- [ ] **Step 4: Add supervisor switch control** and keep operators restricted to their own profile.
- [ ] **Step 5: Run Flutter tests and static analysis** for the changed app surfaces.
- [ ] **Step 6: Commit** con `feat: isolate app data by company profile`.

### Task 7: End-to-end regression and handoff

**Files:**
- Modify: existing API/app test files only where regression coverage is needed
- Test: API and Flutter suites

- [ ] **Step 1: Run API tests and `npm run build`.**
- [ ] **Step 2: Run Flutter tests for login, profile management, visibility, existing trips, invoice history and summary dates.**
- [ ] **Step 3: Verify `git diff --check` and inspect migration SQL for idempotence.**
- [ ] **Step 4: Manually verify the four critical paths:** existing supervisor login, profile login by username, profile login by company email, and supervisor visibility of all profiles.
- [ ] **Step 5: Commit any final regression fixes** with a focused message and report any environment-limited checks honestly.
