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
    <a href="#beta">Beta</a> •
    <a href="#estructura-del-proyecto">Estructura</a> •
    <a href="#changelog">Changelog</a> •
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
    <img src="https://img.shields.io/badge/Status-Beta-FF6B35?logo=android" alt="Status: Beta" />
  </div>
  <br>
</div>

---

## Sobre el Proyecto

Arc es un reproductor de música local desarrollado como proyecto personal de aprendizaje. Su objetivo es proporcionar una interfaz limpia y moderna para reproducir archivos de audio locales, con un motor de audio y una biblioteca de renderizado de UI construidos desde cero.

Arc ya se encuentra en **beta pública** (v1.0.0-beta.1). La experiencia central — exploración de la biblioteca, reproducción, miniplayer persistente, temas y onboarding — es funcional, con Spotify Canvas, navegación por deslizamiento y una barra inferior configurable. El desarrollo activo continúa en playlists, edición de etiquetas y pulido; los comentarios son bienvenidos vía Issues.

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
- Miniplayer persistente y chrome inferior en todas las rutas
- Barra de navegación inferior configurable (estándar / compacto / oculto)
- Navegación por deslizamiento horizontal entre pestañas
- Fondo Spotify Canvas en el reproductor completo
- Pestañas de biblioteca reordenable y ocultable
- Botón "ubicar" en Songs para saltar a la canción en reproducción
- Tocar artistas/álbumes en Home abre su página de detalle

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

## Beta

La primera beta pública, **v1.0.0-beta.1**, está disponible como APK firmada de Android.

- **Descarga:** consulta la página de [Releases](https://github.com/FYSPA/Arc/releases).
- **Compílala tú mismo:**

  ```bash
  flutter build apk --release
  ```

> Esta es una build beta. Espera imperfecciones; por favor reporta problemas y comentarios vía GitHub Issues.

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
│   ├── enums.dart             # Enums de la app
│   └── translations.dart      # i18n
├── data/
│   └── models/
│       ├── track.dart        # ArcTrack model
│       ├── album.dart        # ArcAlbum model
│       └── artist.dart       # ArcArtist model
├── controller/
│   ├── settings_controller.dart    # Estado de configuración (tema, idioma, carpetas)
│   ├── navigator_controller.dart   # Estado de navegación
│   ├── player_controller.dart      # Reproducción de audio
│   ├── indexer_controller.dart     # Escaneo de biblioteca
│   ├── queue_controller.dart       # Gestión de cola
│   ├── playlist_controller.dart    # Gestión de playlists
│   ├── history_controller.dart     # Historial de reproducción
│   └── current_color_controller.dart # Color dinámico
├── ui/
│   ├── pages/
│   │   ├── onboarding_page.dart    # Configuración inicial
│   │   ├── main_page.dart          # Shell de la app
│   │   ├── home_page.dart          # Tab de inicio
│   │   ├── tracks_page.dart        # Lista de tracks
│   │   ├── albums_page.dart        # Grid de álbumes
│   │   ├── artists_page.dart       # Grid de artistas
│   │   ├── playlists_page.dart     # Lista de playlists
│   │   ├── search_page.dart        # Búsqueda
│   │   ├── settings_page.dart      # Settings
│   │   ├── library_tabs.dart       # Shared library-tab source
│   │   └── subpages/
│   │       ├── album_detail_page.dart
│   │       ├── artist_detail_page.dart
│   │       ├── onboarding_appearance.dart
│   │       ├── onboarding_library.dart
│   │       └── onboarding_permissions.dart      # Configuración
│   ├── miniplayer/
│   │   ├── miniplayer_bar.dart     # Barra contraída
│   │   ├── player_page.dart        # Reproductor completo
│   │   └── lyrics_view.dart        # Vista de letras
│   ├── dialogs/
│   │   ├── theme_dialog.dart       # Selector de tema
│   │   ├── performance_dialog.dart # Selector de rendimiento
│   │   ├── backup_restore_dialog.dart
│   │   ├── color_picker_dialog.dart
│   │   ├── language_dialog.dart
│   │   ├── library_tabs_dialog.dart # Reorder/hide tabs
│   │   ├── add_to_playlist_dialog.dart
│   │   ├── track_info_dialog.dart  #
│   │   ├── common_dialogs.dart     #
│   │   ├── edit_tags_dialog.dart   #
│   │   └── set_lrc_dialog.dart     #
│   └── widgets/
│       ├── settings_tile.dart      # Tile reutilizable de configuración
│       ├── settings_card.dart      # Contenedor card de configuración
│       ├── section_header.dart     # Separador de secciones
│       ├── animated_check_mark.dart
│       ├── animated_artwork_widget.dart
│       ├── artwork_flight.dart     # Shared-element artwork transition
│       ├── bottom_chrome.dart      # Miniplayer + custom nav bar
│       ├── canvas_background.dart  # Spotify Canvas video background
│       ├── amoled_glow_effect.dart
│       ├── track_context_menu.dart
│       ├── explandable_box.dart
│       ├── artwork.dart            #
│       ├── custom_widgets.dart     #
│       ├── waveform.dart           #
│       └── sort_by_button.dart     #
├── services/
│   ├── lyrics_service.dart         #
│   ├── audio_tags.dart             #
│   ├── arx_canvas_client.dart      #
│   ├── artwork_service.dart
│   └── canvas_service.dart       # Spotify Canvas URL cache/state
└── packages/
    ├── animated_widgets.dart       #
    ├── scroll_physics_modified.dart #
    ├── image_advanced.dart         #
    └── custom_popup.dart           #
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

## Changelog

Consulta [CHANGELOG.md](CHANGELOG.md) para el historial de versiones completo.

## Roadmap

Consulta [ROADMAP.es.md](ROADMAP.es.md) para el roadmap completo de desarrollo.

Fase actual: **Beta Pública — v1.0.0-beta.1**

## Licencia

Este proyecto está licenciado bajo la Licencia MIT — consulta el archivo [LICENCE](LICENCE) para más detalles.

Copyright (c) 2026 Fernando Suarez
