# Alcoholímetro — Runbook

[README raíz](README.md) · [API](API/README.md) · [App Flutter](APP/README.md)

Guía operativa para ejecutar la API, la app Flutter y el firmware en local, y
para desplegar el sistema. Para la visión general del proyecto, consulta el
[README raíz](README.md).

---

## 1. Requisitos

- **.NET 10 SDK**.
- **Flutter 3.32+** (Dart 3.8+).
- **ngrok** para exponer la API local por HTTPS.
- **PostgreSQL** local o un proyecto de **Supabase**.
- **Arduino IDE 2.x** con soporte para ESP32 (solo si vas a montar el hardware).
- **Modo desarrollador de Windows** activado si ejecutas Flutter en Windows:

  ```powershell
  start ms-settings:developers
  ```

---

## 2. Ejecutar la API en local

```powershell
dotnet run --project API/Alcoholimetro.Api/Alcoholimetro.Api.csproj
```

URL por defecto: `http://localhost:5231`.

La configuración local (cadena de conexión, CORS, ruta de Firebase y secreto
JWT) vive en `API/Alcoholimetro.Api/appsettings.Development.json` y/o en User
Secrets. **No subas secretos al repositorio.**

Si es la primera vez, configura al menos:

```powershell
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=alcoholimetro;Username=postgres;Password=TU_PASSWORD" --project API/Alcoholimetro.Api

dotnet user-secrets set "Jwt:Secret" "TU_CLAVE_DE_AL_MENOS_32_CARACTERES" --project API/Alcoholimetro.Api
```

Comprueba que responde en `http://localhost:5231/swagger` (solo en Development).

---

## 3. Exponer la API con ngrok

```powershell
ngrok http 5231
```

Copia la URL **HTTPS** de forwarding (por ejemplo
`https://abcd.ngrok-free.app`). La app móvil y, si aplica, la web la usarán como
`API_BASE_URL`.

> El ESP32 no necesita ngrok ni acceso a Internet: solo habla BLE con la app.

---

## 4. Apuntar la app a la API

La URL se pasa en tiempo de compilación con `--dart-define=API_BASE_URL=...`:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:5231
flutter build apk --release --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
flutter build web --release --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
```

La constante está declarada en `APP/lib/core/network/api_client.dart`
(`apiBaseUrl`). Si no se pasa nada, la app usa la URL de Cloud Run.

| Entorno | URL |
|---|---|
| Emulador Android | `http://10.0.2.2:5231` |
| iOS Simulator / web local | `http://127.0.0.1:5231` |
| Dispositivo físico | `http://IP_DE_TU_PC:5231` o la URL HTTPS de ngrok |
| Cloud Run (por defecto) | `https://alcoholimetro-api-282349243482.europe-southwest1.run.app` |

---

## 5. CORS

Los orígenes permitidos se leen de `Cors:AllowedOrigins` en
`appsettings*.json`.

- Añade la URL HTTPS de ngrok y el origen de Flutter Web (por ejemplo
  `http://localhost:62443`) a `Cors:AllowedOrigins`.
- En **Development**, si la lista está vacía se activa un fallback permisivo
  (`AllowAnyOrigin`). Es solo para desarrollo.
- En **Staging/Production**, una lista vacía no permite ningún origen.
- `"*"` **no** es un comodín para `WithOrigins`. El
  `appsettings.Development.json` del repositorio trae `"*"`; para evitar
  ambigüedades, usa una lista explícita de orígenes o déjala vacía para activar
  el fallback.

Ejemplo:

```json
"Cors": {
  "AllowedOrigins": [
    "http://localhost:62443",
    "https://abcd.ngrok-free.app"
  ]
}
```

Más detalle en [API/README.md](API/README.md#cors).

---

## 6. Firebase y notificaciones

### Backend (FCM HTTP v1)

La API usa FCM real si existe `Firebase:CredentialsPath` o la variable
`GOOGLE_APPLICATION_CREDENTIALS`. En Development, si ambos están vacíos, usa un
servicio mock que solo escribe logs.

`appsettings.json` trae una ruta por defecto
(`"CredentialsPath": "firebase-credentials.json"`), así que el mock **no se
activa automáticamente**. Para usarlo, deja el valor vacío y no definas
`GOOGLE_APPLICATION_CREDENTIALS`. Si la ruta está definida pero el archivo no
existe, el servicio real registra un warning y desactiva los envíos.

Opciones para configurar credenciales:

```powershell
# Variable de entorno (recomendada en local)
setx GOOGLE_APPLICATION_CREDENTIALS "C:\ruta\firebase-service-account.json"
```

O en `appsettings.Development.json`:

```json
"Firebase": {
  "ProjectId": "alcoholimetro-1f6ab",
  "CredentialsPath": "C:\\ruta\\firebase-service-account.json"
}
```

**Nunca subas la cuenta de servicio.** El `.gitignore` ya excluye
`firebase-service-account*.json`, `firebase-credentials.json`,
`google-services.json` y `GoogleService-Info.plist`.

### Cliente móvil / web

- Genera la configuración con:

  ```powershell
  flutterfire configure
  ```

  O pasa las claves web por `--dart-define`:

  ```powershell
  flutter run --dart-define=FIREBASE_WEB_API_KEY=... --dart-define=FIREBASE_WEB_APP_ID=...
  ```

- Coloca `google-services.json` en `APP/android/app/`.
- Coloca `GoogleService-Info.plist` en `APP/ios/Runner/`.
- Ambos archivos están ignorados por Git.

### Push web

- La clave VAPID pública está en
  `APP/lib/core/notifications/push_service.dart`:

  ```text
  BKrJpkDUS4D8W1s1QC53STn0Qf8dAZDZutE0dvieOUumqcTlvsN0-BNjKtuE3kzm5c-NVxIkfBG9DSQGJ5VcItA
  ```

- FCM Sender ID: `354206024941`.
- `APP/web/firebase-messaging-sw.js` y los valores web de
  `APP/lib/firebase_options.dart` vienen con placeholders
  `TODO_FIREBASE_WEB_API_KEY` / `TODO_FIREBASE_WEB_APP_ID`. Sustitúyelos por la
  configuración real o vuelve a ejecutar `flutterfire configure` y actualiza el
  service worker.
- El backend usa por defecto el proyecto `alcoholimetro-1f6ab`. Revisa que la
  app apunte al mismo proyecto; si no, las push no llegarán.

### Registrar el token

La app registra el token FCM con `PUT /api/users/device-token` después del
login. Si el registro falla, la app sigue funcionando sin push.

---

## 7. Firmware

- Sketch: `arduinocode.txt` (ESP32).
- IDE: Arduino IDE 2.x con soporte de placas ESP32.
- Librerías: `U8g2` y la pila BLE integrada del ESP32.
- Sensor: MQ-3 con salida analógica en **GPIO 36**; OLED SSD1306 por I2C.
- Monitor serie: **115200 baudios**.
- Calibra `R0` con referencias conocidas y deja calentar el sensor antes de
  tomar medidas.

El dispositivo se anuncia como `Alcoholimetro` y expone el **Nordic UART
Service (NUS)**. No usa Wi-Fi ni se conecta a la API.

---

## 8. BLE

- La app filtra por el UUID del servicio NUS:
  `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`.
- RX (`...0002...`): la app escribe `INICIAR\n`.
- TX (`...0003...`): el ESP32 notifica `READY` y el resultado en mg/L.
- En Android deben estar activos **Bluetooth** y **ubicación** para escanear.
- La app solicita permisos de Bluetooth y geolocalización; si se deniegan, no se
  puede medir.
- El flujo BLE solo está disponible en Android/iOS; la web no mide.

Más detalle en [APP/README.md](APP/README.md#ble-y-flujo-de-medición).

---

## 9. Tests

```powershell
dotnet test API/Alcoholimetro.slnx
cd APP
flutter test
```

Los tests del backend cubren value objects, cálculo de alcoholemia, handlers y
middleware. Los de la app cubren el interceptor de autenticación, el botón de
emergencia y el arranque. No hay tests E2E con hardware BLE real.

---

## 10. Despliegue en producción

### 10.1 API en Google Cloud Run

El contexto de build debe ser **`API/`**, porque el `Dockerfile` copia los
proyectos desde esa carpeta:

```powershell
gcloud run deploy alcoholimetro-api `
  --source API `
  --region europe-southwest1 `
  --allow-unauthenticated
```

Configura en Cloud Run:

- `ConnectionStrings__DefaultConnection` (secreto).
- `Jwt__Secret` (secreto), `Jwt__Issuer`, `Jwt__Audience`,
  `Jwt__ExpirationInHours`.
- `Cors__AllowedOrigins__0`, `Cors__AllowedOrigins__1`, ... con los orígenes
  exactos.
- `Firebase__ProjectId=alcoholimetro-1f6ab` y las credenciales de Firebase
  (`GOOGLE_APPLICATION_CREDENTIALS` o `Firebase__CredentialsPath`).
- `ASPNETCORE_ENVIRONMENT=Production`.

La URL resultante se pasa a la app con `--dart-define=API_BASE_URL=...`.

### 10.2 Web en Firebase Hosting

```powershell
cd APP
flutter build web --release --dart-define=API_BASE_URL=https://alcoholimetro-api-282349243482.europe-southwest1.run.app
firebase deploy --only hosting
```

El repositorio **no incluye `firebase.json`**. Inicializa Hosting con
`firebase init hosting` (directorio público: `build/web`) antes del primer
despliegue. Añade el dominio de Hosting a `Cors:AllowedOrigins` de la API.

### 10.3 APK de Android

```powershell
cd APP
flutter build apk --release --dart-define=API_BASE_URL=https://alcoholimetro-api-282349243482.europe-southwest1.run.app
```

El APK se genera en `APP/build/app/outputs/flutter-apk/app-release.apk`.

> La configuración actual firma el release con la clave de debug. Sirve para
> probar, pero no para publicar en Google Play; configura un keystore de release
> antes de distribuir.

---

## 11. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| La API no arranca o falla al acceder a la BD | Falta `Jwt:Secret` o la cadena de conexión no es válida | Configura User Secrets o variables de entorno. |
| Error de conexión con Supabase | Pooler mal configurado | Usa el puerto 6543 y `No Reset On Close=true`; revisa `Max Auto Prepare=0`. |
| La web no conecta con la API | CORS | Añade el origen exacto a `Cors:AllowedOrigins` o usa el fallback de Development. |
| La app no encuentra el ESP32 | Permisos o Bluetooth/ubicación apagados | Activa Bluetooth y ubicación; concede permisos; acerca el dispositivo. |
| El ESP32 conecta pero no mide | No se envía `INICIAR\n` o no llega la notificación TX | Revisa RX/TX y el timeout de 15 s. |
| No llegan las push | Firebase sin configurar o proyecto distinto | Configura credenciales, revisa `Firebase:ProjectId` y el token FCM. |
| El login devuelve 400 | Formato de `emailRaw` | Envía `"emailRaw": { "value": "..." }` en login. |

---

## 12. Documentación

| Documento | Contenido |
|---|---|
| [README raíz](README.md) | Visión general del TFG, arquitectura, hardware, puesta en marcha y limitaciones. |
| [API/README.md](API/README.md) | Endpoints, autenticación, configuración, FCM, migraciones y despliegue del backend. |
| [APP/README.md](APP/README.md) | Arquitectura de la app, BLE, Firebase, rutas, tests y builds. |
| [arduinocode.txt](arduinocode.txt) | Firmware ESP32 con MQ-3, OLED y BLE NUS. |
