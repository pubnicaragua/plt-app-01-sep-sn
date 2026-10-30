# Permiso de pago de facturas por perfil Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir que el supervisor active o desactive por perfil la capacidad de pagar facturas, conservando la consulta de facturas para todos los perfiles autorizados.

**Architecture:** El permiso se guarda en `company_profiles` como `can_pay_invoices`. El API lo devuelve y lo actualiza junto con el perfil, y valida el permiso en el endpoint que registra pagos. Flutter usa el mismo dato para mostrar u ocultar las acciones de pago, sin sustituir la validación del servidor.

**Tech Stack:** NestJS, TypeScript, SQLite, Flutter/Dart, Jest y pruebas unitarias Dart.

**Spec:** `docs/superpowers/specs/2026-10-29-permiso-pago-facturas-perfil-design.md`

## Global Constraints

- El supervisor siempre puede pagar facturas.
- Un perfil operativo sin permiso puede ver facturas, pero no puede pagar.
- Los perfiles operativos existentes empiezan con el permiso apagado.
- El permiso solo lo puede modificar el supervisor.
- No se cambia el cálculo ni el estado normal de los pagos autorizados.

## Review Focus

- Perfil existente sin la nueva columna: debe interpretarse como no autorizado sin romper la carga.
- Perfil operativo intenta pagar directamente contra el API: debe recibir `403` y la factura debe permanecer pendiente.
- Supervisor paga con el permiso apagado: debe continuar autorizado.
- Permiso se activa y desactiva desde la pantalla de perfiles: la respuesta recargada debe reflejar ambos estados.
- Perfil sin permiso consulta facturas: debe conservar la visibilidad y perder únicamente las acciones de pago.

---

### Task 1: Persistencia y autorización de perfiles en API

**Files:**
- Modify: `plt-api-01-sep-sn/src/operations.store.ts`
- Modify: `plt-api-01-sep-sn/src/profiles.controller.ts`
- Modify: `plt-api-01-sep-sn/src/cortes.controller.ts`
- Test: `plt-api-01-sep-sn/test/profile-invoice-payment-permission.spec.ts`

**Interfaces:**
- Produces `canPayInvoices` en perfiles y un guard de pago que recibe el encabezado `Authorization`.
- `PATCH /profiles/:id` acepta `canPayInvoices` solo cuando la sesión es supervisor.
- `POST /cortes/:id/pay` rechaza perfiles operativos sin permiso.

- [ ] **Step 1: Write the failing API tests** para permiso predeterminado apagado, actualización por supervisor, pago permitido/rechazado y supervisor autorizado.
- [ ] **Step 2: Run the focused Jest test** y confirmar que falla por ausencia del campo y de la autorización.
- [ ] **Step 3: Add the SQLite column/migration**, include `canPayInvoices` in profile queries/responses, and enforce the permission in `cortes.controller.ts`/`OperationsStore`.
- [ ] **Step 4: Run the focused Jest test** and confirm all permission cases pass.
- [ ] **Step 5: Run the API test suite and build**.

### Task 2: Modelo Flutter y regla de visibilidad

**Files:**
- Modify: `plt-app-01-sep-sn/lib/models/api_models.dart`
- Modify: `plt-app-01-sep-sn/lib/core/api_client.dart`
- Create: `plt-app-01-sep-sn/lib/core/invoice_payment_permission.dart`
- Test: `plt-app-01-sep-sn/test/invoice_payment_permission_test.dart`

**Interfaces:**
- `CompanyProfile.canPayInvoices` será booleano.
- La regla `canPayInvoicesForSession({required bool isSupervisor, required bool permission})` devolverá autorización efectiva.
- `ApiClient.updateCompanyProfile` enviará opcionalmente `canPayInvoices`.

- [ ] **Step 1: Write the failing Dart tests** para supervisor, operador autorizado y operador no autorizado.
- [ ] **Step 2: Run the focused Dart test/analyzer** y confirmar la falla esperada.
- [ ] **Step 3: Implement the model, client field and pure permission rule**.
- [ ] **Step 4: Run the focused Dart test and analyzer**.

### Task 3: Interruptor del supervisor en perfiles

**Files:**
- Modify: `plt-app-01-sep-sn/lib/screens/perfiles_empresa.dart`
- Modify: `plt-api-01-sep-sn/src/profiles.controller.ts` if DTO validation needs the field.

**Interfaces:**
- La tarjeta de cada perfil operativo mostrará un segundo control “Pagar facturas”.
- El interruptor de estado seguirá funcionando por separado.
- El supervisor no mostrará un control editable para quitarse su autorización.

- [ ] **Step 1: Add the failing UI/state assertion** using the existing profile mutation test helpers or a focused model-level assertion.
- [ ] **Step 2: Run the focused test/analyzer** and confirm the missing permission state.
- [ ] **Step 3: Add the toggle, call `updateCompanyProfile`, update local state and show an error without losing the previous state if the request fails.**
- [ ] **Step 4: Run the focused test/analyzer and format the file.**

### Task 4: Ocultar acciones de pago sin ocultar facturas

**Files:**
- Modify: `plt-app-01-sep-sn/lib/screens/resumen_cliente.dart`
- Modify: related summary state loading only if the active session permission is not already available.

**Interfaces:**
- “Pagar” y “Pagar todas las facturas pendientes” se renderizan solo cuando `canPayInvoicesForSession` es verdadero.
- Las pestañas, facturas y detalles permanecen visibles para perfiles sin permiso.

- [ ] **Step 1: Write the failing permission visibility test** for the action predicate.
- [ ] **Step 2: Run it and confirm it fails before the gate is added.**
- [ ] **Step 3: Gate individual and bulk payment actions with the active session permission.**
- [ ] **Step 4: Run focused tests, analyzers and the full available verification suite.**

### Task 5: Revisión final

- [ ] Review the complete diff against the spec and confirm no existing profile filtering or payment calculation changed.
- [ ] Run API tests/build, focused Dart tests/analyzers, and `git diff --check`.
- [ ] Record any environment limitation, especially if Flutter package tests cannot run offline.
