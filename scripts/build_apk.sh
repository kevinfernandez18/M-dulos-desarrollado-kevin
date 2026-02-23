#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter no está instalado en este entorno." >&2
  exit 1
fi

flutter --version

# Si el repo fue scaffold manual sin carpetas de plataforma,
# se generan sin sobreescribir lib/ existente.
if [ ! -d android ]; then
  echo "Generando carpetas de plataforma con flutter create..."
  flutter create . --platforms=android
fi

flutter pub get
flutter test
flutter build apk --release

echo "APK generado en: build/app/outputs/flutter-apk/app-release.apk"
