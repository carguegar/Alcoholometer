# Alcoholimetro — RUNBOOK

Operational guide for running the API, the Flutter app, and the firmware locally.

## 1. Prerequisites

- .NET 8 SDK
- Flutter 3.7+
- ngrok (for exposing the local API over HTTPS)
- A Postgres database (see `appsettings*.json` → `ConnectionStrings:DefaultConnection`)
- Windows Developer Mode enabled (required by Flutter plugins for `flutter run` / `flutter build`):

```powershell
start ms-settings:developers
```

## 2. Run API locally

```powershell
dotnet run --project API/Alcoholimetro.Api/Alcoholimetro.Api.csproj
```

Default URL: `http://localhost:5231`.

Local-only configuration (connection strings, CORS, Firebase path, JWT secret) lives in
`API/Alcoholimetro.Api/appsettings.Development.json` and/or User Secrets. Do **not** commit secrets.

## 3. Expose API via ngrok

```powershell
ngrok http 5231
```

Copy the **HTTPS** forwarding URL (e.g. `https://abcd.ngrok-free.app`).

## 4. Configure the app to point at ngrok

Override `API_BASE_URL` at build time:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
flutter build apk --release --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
flutter build web --dart-define=API_BASE_URL=https://abcd.ngrok-free.app
```

The constant is declared in `APP/lib/core/network/api_client.dart` (`apiBaseUrl`).

## 5. CORS

CORS allowed origins are read from `Cors:AllowedOrigins` in `appsettings*.json`.

- Add the ngrok HTTPS URL to `Cors:AllowedOrigins` in `appsettings.Development.json` when testing
  the web client through a tunnel.
- Leaving `Cors:AllowedOrigins` empty in **Development** triggers a permissive
  `AllowAnyOrigin` fallback (DEV-ONLY).
- In any non-Development environment an empty list means **no origins allowed**. Always populate
  the list explicitly for Staging/Production.

Example (`appsettings.Development.json`):

```json
"Cors": {
  "AllowedOrigins": [
    "http://localhost:62443",
    "https://abcd.ngrok-free.app"
  ]
}
```

## 6. Firebase / Notifications

### Backend (FCM HTTP v1)

Provide a Firebase service-account JSON. **Never commit it.** Pick one:

- Env var (preferred):

  ```powershell
  setx GOOGLE_APPLICATION_CREDENTIALS "C:\path\to\firebase-service-account.json"
  ```

- Or set `Firebase:CredentialsPath` in `appsettings.Development.json`:

  ```json
  "Firebase": {
    "ProjectId": "alcoholimetro",
    "CredentialsPath": "C:\\path\\to\\firebase-service-account.json"
  }
  ```

### Mobile / Web client

- Generate `firebase_options.dart` automatically:

  ```powershell
  flutterfire configure
  ```

  Or pass values via `--dart-define`:

  ```powershell
  flutter run --dart-define=FIREBASE_WEB_API_KEY=... --dart-define=FIREBASE_WEB_APP_ID=...
  ```

- Drop `google-services.json` into `APP/android/app/`.
- Drop `GoogleService-Info.plist` into `APP/ios/Runner/`.
- Both files are gitignored.

### Web push

- VAPID public key (already wired in `APP/lib/core/notifications/push_service.dart`):

  ```
  BKrJpkDUS4D8W1s1QC53STn0Qf8dAZDZutE0dvieOUumqcTlvsN0-BNjKtuE3kzm5c-NVxIkfBG9DSQGJ5VcItA
  ```

- FCM Sender ID: `354206024941`.

## 7. Firmware

- Sketch: `arduinocode.txt` (ESP32).
- IDE: Arduino IDE 2.x with ESP32 board support installed.
- Libraries: `U8g2` plus the built-in ESP32 BLE stack. Nothing else.

## 8. BLE pairing

- The firmware advertises as `Alcoholimetro` and exposes the **Nordic UART Service (NUS)**.
- The mobile app filters by the NUS UUID.
- On Android, ensure both **Bluetooth** and **Location** are enabled before scanning.
