# Historial único y total recaudado Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Eliminar el historial duplicado del home y mostrar el total recaudado en la pantalla única de historial.

**Architecture:** El home deja de construir su tarjeta de historial. `HistorialConductorScreen` seguirá cargando viajes del conductor y calculará el acumulado desde los viajes completados.

**Tech Stack:** Flutter/Dart, modelo `Trip`, `ApiClient` existente y widgets glass existentes.

**Spec:** `docs/superpowers/specs/2026-10-29-historial-total-recaudado-design.md`

## Global Constraints

- No modificar endpoints ni contratos de API.
- Usar la etiqueta exacta `Total recaudado`.
- Mantener el diseño glass y los colores actuales.

## Review Focus

- Viajes completados sin tarifa deben sumar cero.
- Viajes cancelados no deben entrar al total.
- La lista vacía debe seguir mostrando el estado vacío sin errores.

### Task 1: Cálculo y pantalla única de historial

**Files:**
- Modify: `lib/screens/historial_conductor.dart`
- Modify: `lib/screens/home_conductor.dart`
- Test: `test/historial_conductor_test.dart`

**Interfaces:**
- Produce una función testeable `totalRecaudado(List<Trip> trips) -> double`.

- [ ] Escribir la prueba que incluya completados con tarifa, un completado sin tarifa y un cancelado.
- [ ] Ejecutar la prueba y confirmar que falla porque la función no existe.
- [ ] Implementar el cálculo, mostrar `Total recaudado` en la pantalla y retirar del home el bloque `Mi historial`.
- [ ] Ejecutar la prueba y confirmar que pasa.
- [ ] Ejecutar formato, análisis y pruebas del archivo modificado.
