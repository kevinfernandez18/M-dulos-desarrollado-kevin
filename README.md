# Taller de Patrones (MVP Android-first)

Aplicación Flutter enfocada en costura por tallas para **blusas** y **vestidos**. Diseñada para uso offline, con interfaz de botones grandes y flujo simple para costureras.

## Funcionalidades MVP

- Gestión de tallas `XS/S/M/L/XL` y medidas por prenda.
- Plantillas base de medidas para **Blusa** y **Vestido**.
- Biblioteca de patrones por prenda/talla/modelo.
- Captura de foto desde cámara para digitalizar patrones en papel.
- Calibración de escala en cm (referencia A4 o regla).
- Editor básico sobre canvas con:
  - puntos
  - líneas
  - navegación zoom/pan
  - anotaciones tipo texto y piquetes
- Configuración de margen de costura (`1.0`, `1.5`, `2.0` cm) para exportación.
- Exportación a PDF mosaico A4 1:1 con:
  - título
  - talla
  - fecha
  - cuadro de verificación `5x5 cm`
  - paginado por mosaico
- Compartir PDF por WhatsApp/Drive/etc.

## Stack

- Flutter + Dart
- SQLite local con `sqflite`
- PDF con paquete `pdf`
- Compartir con `share_plus`
- Sin login (100% offline)

## Arquitectura (clean architecture ligera)

```text
lib/
  core/
    theme/
  features/
    home/presentation/
    sizes/{domain,data,presentation}/
    patterns/{domain,data,presentation}/
    exports/{services,presentation}/
```

## Tablas SQLite

- `sizes`
- `measurements`
- `patterns`
- `pattern_versions`
- `pattern_entities`

Incluye seed inicial de tallas `XS-XL` y campos sugeridos (busto, cintura, cadera, largo, hombro) para blusa/vestido.

## Requisitos

- Flutter 3.22+
- Android SDK configurado

## Ejecutar

```bash
flutter pub get
flutter run
```

## Generar APK local

> Si el repo aún no tiene carpeta `android/`, el script la crea automáticamente sin tocar tu código de `lib/`.

```bash
./scripts/build_apk.sh
```

Salida esperada:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Generar APK con GitHub Actions (sin instalar Flutter en tu PC)

1. Sube este repo a GitHub.
2. Ve a **Actions** → **Build Android APK**.
3. Ejecuta workflow (`Run workflow`).
4. Descarga el artifact `app-release-apk`.

Workflow: `.github/workflows/android-apk.yml`

## Datos demo

Se incluyen ejemplos en `assets/demo/`:
- `pattern_blusa_base.json`
- `pattern_vestido_base.json`

## Próximos pasos sugeridos

1. Mejorar editor con curvas bézier y selección/mover/borrar avanzada.
2. Offset geométrico real para margen de costura en contornos cerrados.
3. Trazado preciso del mosaico A4 (render de geometrías por página).
4. Historial de versiones visual con comparación.
