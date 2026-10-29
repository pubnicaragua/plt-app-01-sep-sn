# Home Conductor Vehicle Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the conductor home screen to match the requested structure while showing the conductor's saved vehicle, icon, label, and plate from connected profile data.

**Architecture:** Keep `HomeConductor` as the single screen and preserve its existing polling, trip loading, counters, actions, and navigation. Add a small profile-first vehicle resolver in the same screen file, with trip data as fallback only when the profile has no vehicle.

**Tech Stack:** Flutter/Dart, existing `SessionUser`, `Trip`, `GlassCard`, current theme and vehicle assets.

**Spec:** `docs/superpowers/specs/2026-10-28-home-conductor-vehicle-dashboard-design.md`

## Global Constraints

- Preserve the current colors and background treatment.
- Use the saved conductor profile vehicle as the primary source.
- Keep existing trip polling and navigation behavior unchanged.
- Do not change endpoints or invent vehicle, plate, or trip data.

## Review Focus

- Profile has a vehicle and plate: icon, label, and plate must come from the same profile source.
- Profile vehicle changes after refresh: the header must update without restarting the screen.
- Profile has no vehicle: use the first assigned trip only as a fallback.
- No assigned trips: show the empty assigned-trips state without inventing a vehicle.
- Existing trip actions: opening assigned or in-progress trips must continue to use the current navigation.

### Task 1: Add profile-first vehicle presentation

**Files:**
- Modify: `lib/screens/home_conductor.dart`
- Test/verification: `flutter analyze lib/screens/home_conductor.dart --no-pub` and `git diff --check`

**Interfaces:**
- Consumes: `apiClient.currentUser`, `Trip.vehicleVariant`, `Trip.truckType`, `Trip.transport`, existing vehicle asset helpers.
- Produces: a profile-first vehicle label, plate, and asset used by the HomeConductor header.

- [ ] Add a resolver that derives one consistent vehicle label and asset from the profile vehicle first, then the first assigned/upcoming trip as fallback.
- [ ] Add the assigned vehicle presentation near the top of `HomeConductor`, showing the resolved image/icon, label, and plate.
- [ ] Ensure `_load` and `_refresh` rebuild the presentation from the current profile and trip data.

### Task 2: Reorganize the home content without changing behavior

**Files:**
- Modify: `lib/screens/home_conductor.dart`

**Interfaces:**
- Consumes: existing `assigned`, `upcoming`, `history`, `_OperationalSummary`, quick actions, and trip cards.
- Produces: the requested order: greeting/profile, vehicle block, counters, shipment/trip tabs or section, and assigned items.

- [ ] Keep current colors, gradients, glass borders, typography family, and background assets.
- [ ] Place the vehicle block above the operational counters.
- [ ] Keep assigned, in-progress, completed counts connected to the existing filtered trip lists.
- [ ] Present assigned deliveries below the summary while retaining `_openTrip`, refresh, fuel, and activity actions.
- [ ] Preserve the existing empty, loading, and error states.

### Task 3: Verify the connected behavior

**Files:**
- Verify: `lib/screens/home_conductor.dart`, `lib/models/api_models.dart`, `lib/core/api_client.dart`

- [ ] Run `flutter analyze lib/screens/home_conductor.dart --no-pub`.
- [ ] Run `git diff --check`.
- [ ] Confirm by code inspection that no endpoint or trip navigation was changed.
- [ ] Confirm profile vehicle changes are picked up by the existing refresh path.
