# SDD ledger — plan: docs/superpowers/plans/2026-10-29-permiso-pago-facturas-perfil-plan.md

Ruling: Mantener la implementación en el workspace compartido sobre `main` — el usuario autorizó explícitamente modificar el código y ya existen cambios previos sin commit que deben preservarse; crear un worktree separado no copiaría esos cambios.

Pre-flight: Task 1 API produce `canPayInvoices` y autorización de pago; Task 2 Flutter consume el campo y produce la regla de autorización visual; Task 3 consume el cliente de perfiles; Task 4 consume la regla y el estado de sesión. No hay conflicto de interfaces detectado.

Task 1: complete — API guard, persistence/migration, profile response, supervisor-only update permission; focused Jest test and `npm run build` pass.
Task 2: complete — Flutter model/client field plus pure session authorization rule and focused test added. Flutter analysis/test commands were attempted but remained blocked by the local Dart/Flutter tool startup; no diagnostic was emitted.
Task 3: complete — supervisor profile screen now exposes an independent “Facturas” switch for operator profiles and persists it through the API.
Task 4: complete — invoice history hides payment selection/actions for unauthorized profiles while preserving invoice visibility; API enforcement also covers completed-trip payment updates.
Task 5: complete — API full Jest suite, focused Jest suite, Nest build, and `git diff --check` pass; Flutter verification remains environment-blocked as noted in Task 2.
