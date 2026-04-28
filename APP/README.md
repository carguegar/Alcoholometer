# app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configurar API

La URL base de la API se resuelve en este orden:

1. `--dart-define=API_BASE_URL=...` al ejecutar/build (recomendado).
2. Default: `http://10.0.2.2:5231` (loopback del emulador Android al host).

Ejemplos:

```bash
# Apuntar a una API remota
flutter run --dart-define=API_BASE_URL=https://mi-api.com

# Build release con URL custom
flutter build apk --dart-define=API_BASE_URL=https://mi-api.com
```

> En iOS Simulator usa `http://127.0.0.1:5231`. En dispositivo físico, la IP de tu máquina en la red local.
