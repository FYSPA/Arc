<div align="center">
  <br>
  <img src="assets/Logo.png" alt="Arc Player Logo" width="300" />
  <h1>Arc</h1>
  <p>
    <strong>A local music player built with Flutter, designed with a custom audio engine (Arc Engine) and a custom UI rendering library (Arx Canvas). Supports FLAC, WAV, and MP3 formats.</strong>
  </p>
  <p>
    <a href="#about-the-project">About</a> •
    <a href="#features">Features</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#project-structure">Structure</a> •
    <a href="#roadmap">Roadmap</a>
  </p>
  <p>
    <a href="README.es.md">Leer en Español</a>
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

## About the Project

Arc is a local music player developed as a personal learning project. It aims to provide a clean, modern interface for playing local audio files, with a custom-built audio engine and UI rendering library.

The project is currently in early development. The core theme system, onboarding flow, and settings infrastructure are complete. The main screen, player, and library features are under active development.

## Features

- Local playback of FLAC, WAV, and MP3 files
- Custom audio engine ([Arc Engine](https://github.com/FYSPA/Arc-Engine))
- Custom UI rendering library ([Arx Canvas](https://github.com/FYSPA/Arx-Canvas))
- Material 3 design with dynamic theming
- Light, dark, and AMOLED modes
- Custom icon set (Broken Icons — 900+ icons)
- LexendDeca font (9 weights)
- Onboarding flow with permissions and settings
- Bilingual support (English / Spanish)

## Getting Started

### Prerequisites

- Flutter SDK 3.22+
- Dart SDK 3.12+
- Android Studio or VS Code
- Android SDK (API 27+)

### Installation

```bash
# Clone the repository
git clone https://github.com/FYSPA/Arc.git
cd Arc

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Project Structure

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # MaterialApp + Provider setup
├── core/
│   ├── themes.dart            # Light/dark/AMOLED themes
│   ├── dimensions.dart        # Spacing and sizing system
│   ├── constans.dart          # Brand colors and constants
│   ├── extensions.dart        # Color and widget extensions
│   ├── broken_icons.dart      # Custom icon font (900+ icons)
│   ├── enums.dart             # App-wide enums (empty)
│   └── translations.dart      # i18n (empty)
├── controller/
│   ├── settings_controller.dart    # Settings state (theme, language, folders)
│   ├── navigator_controller.dart   # Navigation state (empty)
│   ├── player_controller.dart      # Audio playback (empty)
│   ├── indexer_controller.dart     # Library scanning (empty)
│   ├── queue_controller.dart       # Queue management (empty)
│   ├── playlist_controller.dart    # Playlist management (empty)
│   ├── history_controller.dart     # Playback history (empty)
│   └── current_color_controller.dart # Dynamic color (empty)
├── ui/
│   ├── pages/
│   │   ├── onboarding_page.dart    # First-run setup
│   │   ├── main_page.dart          # App shell (empty)
│   │   ├── home_page.dart          # Home tab (empty)
│   │   ├── tracks_page.dart        # Track list (empty)
│   │   ├── albums_page.dart        # Album grid (empty)
│   │   ├── artists_page.dart       # Artist grid (empty)
│   │   ├── playlists_page.dart     # Playlist list (empty)
│   │   ├── search_page.dart        # Search (empty)
│   │   └── settings_page.dart      # Settings (empty)
│   ├── miniplayer/
│   │   ├── miniplayer_bar.dart     # Collapsed bar (empty)
│   │   ├── player_page.dart        # Full player (empty)
│   │   └── lyrics_view.dart        # Lyrics display (empty)
│   ├── dialogs/
│   │   ├── theme_dialog.dart       # Theme selector
│   │   ├── performance_dialog.dart # Performance selector
│   │   ├── backup_restore_dialog.dart
│   │   ├── color_picker_dialog.dart
│   │   ├── track_info_dialog.dart  # (empty)
│   │   ├── common_dialogs.dart     # (empty)
│   │   ├── edit_tags_dialog.dart   # (empty)
│   │   └── set_lrc_dialog.dart     # (empty)
│   └── widgets/
│       ├── settings_tile.dart      # Reusable settings tile
│       ├── settings_card.dart      # Settings card container
│       ├── section_header.dart     # Section separator
│       ├── animated_check_mark.dart
│       ├── artwork.dart            # (empty)
│       ├── custom_widgets.dart     # (empty)
│       ├── waveform.dart           # (empty)
│       └── sort_by_button.dart     # (empty)
├── services/
│   ├── lyrics_service.dart         # (empty)
│   ├── audio_tags.dart             # (empty)
│   ├── arx_canvas_client.dart      # (empty)
│   └── artwork_service.dart        # (empty)
└── packages/
    ├── animated_widgets.dart       # (empty)
    ├── scroll_physics_modified.dart # (empty)
    ├── image_advanced.dart         # (empty)
    └── custom_popup.dart           # (empty)
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.22+ |
| Language | Dart 3.12+ |
| State Management | Provider |
| Design System | Material 3 |
| Font | LexendDeca (9 weights) |
| Icons | Broken Icons (900+) |
| Audio Engine | Arc Engine (custom, in development) |
| UI Renderer | Arx Canvas (custom, in development) |
| Min Android | API 27 (Android 8.1) |

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full development roadmap.

Current phase: **Phase 1 — Main Page + Miniplayer**

## License

This project is licensed under the MIT License — see the [LICENCE](LICENCE) file for details.

Copyright (c) 2026 Fernando Suarez
