# INCOEX Logistics · Mobile

Base Flutter para los roles **Empresa** y **Conductor**. La primera iteración contiene el flujo navegable de onboarding, login, registro, solicitud de envío, tracking, comprobante, historial y perfil. El cliente HTTP está centralizado en `lib/core/api_client.dart` y los contratos en `lib/models/api_models.dart`.

## Ejecutar

```powershell
flutter pub get
flutter run
```

Para apuntar a la API local desde un emulador Android:

```powershell
flutter run --dart-define=INCOEX_API_URL=http://10.0.2.2:3000/api
```

El punto de entrada está en `lib/main.dart`. El flujo completo está descrito en [FLUJO_NAVEGACION.md](FLUJO_NAVEGACION.md). No se incluyen todavía llaves de Google Maps ni datos productivos; el mapa actual es una presentación visual que consume las posiciones entregadas por el contrato inicial.
