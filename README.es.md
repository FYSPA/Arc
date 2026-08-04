<div align="center">
  <br>
  <img src="assets/Logos/ArcVideo.gif" alt="Arc Player Logo" width="300" />
  <h1>Arc</h1>
  <p>
    <strong>Un reproductor de música local construido con Flutter, diseñado con un motor de audio personalizado (Arc Engine) y una biblioteca de renderizado de UI personalizada (Arx Canvas). Soporta formatos FLAC, WAV y MP3.</strong>
  </p>
  <p>
    <a href="#sobre-el-proyecto">Acerca de</a> •
    <a href="#características">Características</a> •
    <a href="#primeros-pasos">Primeros Pasos</a> •
    <a href="#estructura-del-proyecto">Estructura</a> •
    <a href="#roadmap">Roadmap</a>
  </p>
  <p>
    <a href="README.md">Read in English</a>
  </p>
  <div align="center">
    <a href="LICENCE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
    <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter" alt="Flutter 3.22+" />
    <img src="https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart" alt="Dart 3.12+" />
    <img src="https://img.shields.io/badge/Android-API_27+-3DDC84?logo=android" alt="Android API 27+" />
  </div>
  <br>
</div>

---

## Sobre el Proyecto

Arc es un reproductor de música local desarrollado como proyecto personal de aprendizaje. Su objetivo es proporcionar una interfaz limpia y moderna para reproducir archivos de audio locales, con un motor de audio y una biblioteca de renderizado de UI construidos desde cero.

El proyecto se encuentra en una etapa temprana de desarrollo. El sistema de temas principal, el flujo de onboarding y la infraestructura de configuración están completos. La pantalla principal, el reproductor y las funciones de biblioteca están en desarrollo activo.

## Características

- Reproducción local de archivos FLAC, WAV y MP3
- Motor de audio personalizado ([Arc Engine](https://github.com/FYSPA/Arc-Engine))
- Biblioteca de renderizado UI personalizada ([Arx Canvas](https://github.com/FYSPA/Arx-Canvas))
- Diseño Material 3 con temática dinámica
- Modos claro, oscuro y AMOLED
- Iconografía personalizada (Broken Icons — más de 900 iconos)
- Fuente LexendDeca (9 pesos)
- Flujo de onboarding con permisos y configuración
- Soporte bilingüe (Español / Inglés)

## Primeros Pasos

### Requisitos previos

- Flutter SDK 3.22+
- Dart SDK 3.12+
- Android Studio o VS Code
- Android SDK (API 27+)

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/FYSPA/Arc.git
cd Arc

# Instalar dependencias
flutter pub get

# Ejecutar la app
flutter run
```

## Estructura del Proyecto

```
lib/
├── main.dart                  # Punto de entrada
├── app.dart                   # MaterialApp + configuración Provider
├── core/
│   ├── themes.dart            # Temas light/dark/AMOLED
│   ├── dimensions.dart        # Sistema de espaciado y tamaño
│   ├── constans.dart          # Colores de marca y constantes
│   ├── extensions.dart        # Extensiones de color y widgets
│   ├── broken_icons.dart      # Fuente de iconos personalizada (900+)
│   ├── enums.dart             # Enums de la app (vacío)
│   └── translations.dart      # i18n (vacío)
├── controller/
│   ├── settings_controller.dart    # Estado de configuración (tema, idioma, carpetas)
│   ├── navigator_controller.dart   # Estado de navegación (vacío)
│   ├── player_controller.dart      # Reproducción de audio (vacío)
│   ├── indexer_controller.dart     # Escaneo de biblioteca (vacío)
│   ├── queue_controller.dart       # Gestión de cola (vacío)
│   ├── playlist_controller.dart    # Gestión de playlists (vacío)
│   ├── history_controller.dart     # Historial de reproducción (vacío)
│   └── current_color_controller.dart # Color dinámico (vacío)
├── ui/
│   ├── pages/
│   │   ├── onboarding_page.dart    # Configuración inicial
│   │   ├── main_page.dart          # Shell de la app (vacío)
│   │   ├── home_page.dart          # Tab de inicio (vacío)
│   │   ├── tracks_page.dart        # Lista de tracks (vacío)
│   │   ├── albums_page.dart        # Grid de álbumes (vacío)
│   │   ├── artists_page.dart       # Grid de artistas (vacío)
│   │   ├── playlists_page.dart     # Lista de playlists (vacío)
│   │   ├── search_page.dart        # Búsqueda (vacío)
│   │   └── settings_page.dart      # Configuración (vacío)
│   ├── miniplayer/
│   │   ├── miniplayer_bar.dart     # Barra contraída (vacío)
│   │   ├── player_page.dart        # Reproductor completo (vacío)
│   │   └── lyrics_view.dart        # Vista de letras (vacío)
│   ├── dialogs/
│   │   ├── theme_dialog.dart       # Selector de tema
│   │   ├── performance_dialog.dart # Selector de rendimiento
│   │   ├── backup_restore_dialog.dart
│   │   ├── color_picker_dialog.dart
│   │   ├── track_info_dialog.dart  # (vacío)
│   │   ├── common_dialogs.dart     # (vacío)
│   │   ├── edit_tags_dialog.dart   # (vacío)
│   │   └── set_lrc_dialog.dart     # (vacío)
│   └── widgets/
│       ├── settings_tile.dart      # Tile reutilizable de configuración
│       ├── settings_card.dart      # Contenedor card de configuración
│       ├── section_header.dart     # Separador de secciones
│       ├── animated_check_mark.dart
│       ├── artwork.dart            # (vacío)
│       ├── custom_widgets.dart     # (vacío)
│       ├── waveform.dart           # (vacío)
│       └── sort_by_button.dart     # (vacío)
├── services/
│   ├── lyrics_service.dart         # (vacío)
│   ├── audio_tags.dart             # (vacío)
│   ├── arx_canvas_client.dart      # (vacío)
│   └── artwork_service.dart        # (vacío)
└── packages/
    ├── animated_widgets.dart       # (vacío)
    ├── scroll_physics_modified.dart # (vacío)
    ├── image_advanced.dart         # (vacío)
    └── custom_popup.dart           # (vacío)
```

## Tech Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.22+ |
| Lenguaje | Dart 3.12+ |
| Gestión de Estado | Provider |
| Sistema de Diseño | Material 3 |
| Fuente | LexendDeca (9 pesos) |
| Iconos | Broken Icons (900+) |
| Motor de Audio | Arc Engine (personalizado, en desarrollo) |
| Renderizado UI | Arx Canvas (personalizado, en desarrollo) |
| Android Mínimo | API 27 (Android 8.1) |

## Roadmap

Consulta [ROADMAP.es.md](ROADMAP.es.md) para el roadmap completo de desarrollo.

Fase actual: **Fase 1 — Main Page + Miniplayer**

## Licencia

Este proyecto está licenciado bajo la Licencia MIT — consulta el archivo [LICENCE](LICENCE) para más detalles.

Copyright (c) 2026 Fernando Suarez
