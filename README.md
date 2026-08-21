<div align="center">
  <br>
  <img src="assets/Logos/ArcVideo.gif" alt="Arc Player Logo" width="300" />
  <h1>Arc</h1>
  <p>
    <strong>A local music player built with Flutter, designed with a custom audio engine (Arc Engine) and a custom UI rendering library (Arx Canvas). Supports FLAC, WAV, and MP3 formats.</strong>
  </p>
  <p>
    <a href="#about-the-project">About</a> •
    <a href="#features">Features</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#beta">Beta</a> •
    <a href="#project-structure">Structure</a> •
    <a href="#changelog">Changelog</a> •
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
    <img src="https://img.shields.io/badge/Status-Beta-FF6B35?logo=android" alt="Status: Beta" />
  </div>
  <br>
</div>

---

## About the Project

Arc is a local music player developed as a personal learning project. It aims to provide a clean, modern interface for playing local audio files, with a custom-built audio engine and UI rendering library.

Arc is now in **public beta** (v1.0.0-beta.1). The core experience — library browsing, playback, the persistent miniplayer, theming, and onboarding — is functional, with Spotify Canvas, swipe navigation, and a configurable bottom bar. Active development continues on playlists, tag editing, and polish; feedback is welcome via Issues.

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
- Persistent miniplayer and bottom chrome across all routes
- Custom bottom navigation bar (standard / compact / hidden)
- Horizontal swipe navigation between library tabs
- Spotify Canvas background in the full-screen player
- Reorderable and hideable library tabs
- "Locate" button on Songs to jump to the playing track
- Tap artists/albums on Home to open their detail page

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

## Beta

The first public beta, **v1.0.0-beta.1**, is available as a signed Android APK.

- **Download:** see the [Releases](https://github.com/FYSPA/Arc/releases) page.
- **Build it yourself:**

  ```bash
  flutter build apk --release
  ```

> This is a beta build. Expect rough edges; please report issues and feedback via GitHub Issues.

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
│   ├── enums.dart             # App-wide enums
│   └── translations.dart      # i18n
├── data/
│   └── models/
│       ├── track.dart        # ArcTrack model
│       ├── album.dart        # ArcAlbum model
│       └── artist.dart       # ArcArtist model
├── controller/
│   ├── settings_controller.dart    # Settings state (theme, language, folders)
│   ├── navigator_controller.dart   # Navigation state
│   ├── player_controller.dart      # Audio playback
│   ├── indexer_controller.dart     # Library scanning
│   ├── queue_controller.dart       # Queue management
│   ├── playlist_controller.dart    # Playlist management
│   ├── history_controller.dart     # Playback history
│   └── current_color_controller.dart # Dynamic color
├── ui/
│   ├── pages/
│   │   ├── onboarding_page.dart    # First-run setup
│   │   ├── main_page.dart          # App shell
│   │   ├── home_page.dart          # Home tab
│   │   ├── tracks_page.dart        # Track list
│   │   ├── albums_page.dart        # Album grid
│   │   ├── artists_page.dart       # Artist grid
│   │   ├── playlists_page.dart     # Playlist list
│   │   ├── search_page.dart        # Search
│   │   ├── settings_page.dart      # Settings
│   │   ├── library_tabs.dart       # Shared library-tab source
│   │   └── subpages/
│   │       ├── album_detail_page.dart
│   │       ├── artist_detail_page.dart
│   │       ├── onboarding_appearance.dart
│   │       ├── onboarding_library.dart
│   │       └── onboarding_permissions.dart      # Settings
│   ├── miniplayer/
│   │   ├── miniplayer_bar.dart     # Collapsed bar
│   │   ├── player_page.dart        # Full player
│   │   └── lyrics_view.dart        # Lyrics display
│   ├── dialogs/
│   │   ├── theme_dialog.dart       # Theme selector
│   │   ├── performance_dialog.dart # Performance selector
│   │   ├── backup_restore_dialog.dart
│   │   ├── color_picker_dialog.dart
│   │   ├── language_dialog.dart
│   │   ├── library_tabs_dialog.dart # Reorder/hide tabs
│   │   ├── add_to_playlist_dialog.dart
│   │   ├── track_info_dialog.dart 
│   │   ├── common_dialogs.dart    
│   │   ├── edit_tags_dialog.dart  
│   │   └── set_lrc_dialog.dart    
│   └── widgets/
│       ├── settings_tile.dart      # Reusable settings tile
│       ├── settings_card.dart      # Settings card container
│       ├── section_header.dart     # Section separator
│       ├── animated_check_mark.dart
│       ├── animated_artwork_widget.dart
│       ├── artwork_flight.dart     # Shared-element artwork transition
│       ├── bottom_chrome.dart      # Miniplayer + custom nav bar
│       ├── canvas_background.dart  # Spotify Canvas video background
│       ├── amoled_glow_effect.dart
│       ├── track_context_menu.dart
│       ├── explandable_box.dart
│       ├── artwork.dart           
│       ├── custom_widgets.dart    
│       ├── waveform.dart          
│       └── sort_by_button.dart    
├── services/
│   ├── lyrics_service.dart        
│   ├── audio_tags.dart            
│   ├── arx_canvas_client.dart     
│   ├── artwork_service.dart
│   └── canvas_service.dart       # Spotify Canvas URL cache/state       
└── packages/
    ├── animated_widgets.dart      
    ├── scroll_physics_modified.dart
    ├── image_advanced.dart        
    └── custom_popup.dart          
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

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full development roadmap.

Current phase: **Public Beta — v1.0.0-beta.1**

## License

This project is licensed under the MIT License — see the [LICENCE](LICENCE) file for details.

Copyright (c) 2026 Fernando Suarez
