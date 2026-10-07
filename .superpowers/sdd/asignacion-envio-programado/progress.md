# SDD ledger — plan: docs/superpowers/plans/2026-10-05-asignacion-envio-programado-plan.md

Ruling: execute in the shared `main` workspace — the user explicitly requested implementation in the current app and the workspace already contains related uncommitted UI work; no reset, checkout, or destructive cleanup.

Ruling: use repository/manual verification instead of automated test files — the user's established project preference is not to create tests, and this is a Flutter UI flow whose analyzer command previously hung in this environment.

Ruling: Python helper unavailable — `python` and `py` are not installed, so the SDD helper scripts cannot run; task progress is recorded manually here.

Implementation status: completed in the shared workspace. Added the cargo/delivery assignment flow, the assigned-shipment screen, and the 36-frame truck sprite extracted from the supplied SVG. Taxi/Viajes keeps its direct tracking navigation.

Verification:

- `git diff --check`: clean.
- Sprite verified at 720×430 with 36 frames.
- `flutter analyze --no-pub` and `flutter run -d web-server` produced no output within 60 seconds in this environment and were stopped; they are not reported as successful.

Follow-up fix: `EnvioAsignadoScreen` now uses `SpriteTruckAnimation` for cargo instead of the static `carga_grande.png`, so both assignment screens render the supplied moving truck sprite.

Follow-up fix: removed the 24-hour scheduling cap from the API and the client quick-scheduling validation. The creation and assignment screens now use the animated truck for cargo and the existing animated vehicle treatment for non-cargo trips.

Animation fix: the supplied SVG contains one 720×430 embedded image and no 6×6 frame grid or animation metadata. The renderer now displays the complete asset without cropping or invented motion; if the real animated GIF is supplied, Flutter's image widget can play it natively.

Visual update: added the supplied `fondo_estados.png` to the assigned-shipment and finalized-delivery screens only. The assigning-driver screen keeps its plain background. The assigned panel uses a stronger glass surface to separate it from the artwork.

Assigned-screen refinement: the header now identifies the section as `Camiones`/`Viajes`, the truck and card sit lower, the card content is larger and taller, the programmed-shipment details link is inside the glass card and opens `MisEnvios`, and the bottom action returns to the app start.
