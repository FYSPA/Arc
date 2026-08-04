# Arc — Development Roadmap

> Last updated: 2026-08-04
> Stack: Flutter + Provider + arc_engine + arx_canvas

---

## Completed

### Core (Foundation)
- [x] `themes.dart` — Light/dark/AMOLED themes, LexendDeca font
- [x] `dimensions.dart` — Scaling system (space, multipliedRadius)
- [x] `constans.dart` — Brand colors (kMainColorLight/Dark, pitchBlack)
- [x] `extensions.dart` — Color extensions (alphaBlendWith, withOpacityExt)

### Controller
- [x] `settings_controller.dart` — Theme, language, performance, folders, media store
- [x] `navigator_controller.dart` — Navigation state (currentPageIndex, navigateTo)

### UI — Onboarding
- [x] `onboarding_page.dart` — Full screen, AMOLED, section headers
- [x] `settings_tile.dart` — Generic widget (tap/toggle/expansion)
- [x] `settings_card.dart` — Container card with header
- [x] `animated_check_mark.dart` — Animated checkmark
- [x] `section_header.dart` — Section separator
- [x] `onboarding_bottom_bar.dart` — Permission + continue buttons

### UI — Dialogs
- [x] `theme_dialog.dart` — Visual selector with cards
- [x] `performance_dialog.dart` — Visual selector with cards
- [x] `backup_restore_dialog.dart` — Icon + buttons

### UI — Main Page + Miniplayer
- [x] `enums.dart` — `LibraryTab` enum (home, songs, albums, artists, folders)
- [x] `main_page.dart` — Scaffold + AppBar + IndexedStack + NavigationBar M3
- [x] `miniplayer_bar.dart` — 82px collapsed bar (artwork, title, play/pause)
- [x] `home_page.dart` — Home tab with scroll sections (Recently Added, Played, Top Artists/Albums)

### Infrastructure
- [x] Fonts registered (LexendDeca 9 weights + Broken icons)
- [x] Package ID changed to `dev.yh.arc_app`
- [x] `arc_engine` / `arx_canvas` as git dependencies (temporarily disabled)
- [x] Navigation flow: Onboarding → MainPage via Provider state

---

## Phase 2 — Player Page

> **Goal:** Full-screen player with artwork and controls.

### 2.1 `player_controller.dart` — Audio logic
- [ ] Connect `just_audio` (or `arc_engine` when working)
- [ ] States: `playing`, `paused`, `position`, `duration`
- [ ] Methods: `play()`, `pause()`, `seekTo()`, `skipNext()`, `skipPrevious()`
- [ ] Playback queue

### 2.2 `current_color_controller.dart` — Dynamic color
- [ ] Extract dominant color from artwork
- [ ] Notify color changes to the entire UI
- [ ] Color transition animation

### 2.3 `player_page.dart` — Full screen
- [ ] Large artwork with animation
- [ ] Title + artist + album
- [ ] Progress bar (slider)
- [ ] Controls: prev, play/pause, next, shuffle, repeat
- [ ] Buttons: favorite, playlist, lyrics
- [ ] Design: `design_extracted/01, 02, 04`

### 2.4 `lyrics_view.dart` — Lyrics display
- [ ] Scroll synchronized with audio position
- [ ] Fade effect on inactive lines
- [ ] Design: `design_extracted/08`

**Docs:** `design_extracted/01, 02, 04, 08` + `API-ArcEngine.md`

---

## Phase 3 — Indexer + Tracks Page

> **Goal:** Scan the music library and display the song list.

### 3.1 `indexer_controller.dart` — Scanning
- [ ] Scan device folders
- [ ] Read tags with `audio_tags` (title, artist, album, duration)
- [ ] Save to database
- [ ] Indexing progress

### 3.2 `audio_tags.dart` — Service
- [ ] Read MP3/FLAC metadata
- [ ] Extract embedded artwork

### 3.3 `tracks_page.dart` — Song list
- [ ] `ListView` with `TrackTile`
- [ ] Sorting (title, artist, date, duration)
- [ ] Multi-select
- [ ] Design: `design_library/01`

### 3.4 `track_tile.dart` — Song widget
- [ ] Artwork thumbnail + title + artist + duration
- [ ] Long press → context menu
- [ ] Tap → play
- [ ] Design: `design_widgets/01`

**Docs:** `design_library/01` + `design_widgets/01`

---

## Phase 4 — Library (Albums, Artists, Playlists)

> **Goal:** Grid views for albums, artists and playlists.

### 4.1 `albums_page.dart`
- [ ] Album grid with artwork
- [ ] Tap → album tracks
- [ ] Design: `design_library/02`

### 4.2 `artists_page.dart`
- [ ] Artist grid (circular images)
- [ ] Tap → artist tracks
- [ ] Design: `design_library/03`

### 4.3 `playlists_page.dart`
- [ ] Playlist list
- [ ] Create playlist
- [ ] Design: `design_library/06`

### 4.4 `playlist_controller.dart`
- [ ] Playlist CRUD
- [ ] Add/remove tracks

### 4.5 Library widgets
- [ ] `album_card.dart` — Album card
- [ ] `artist_card.dart` — Artist card
- [ ] `playlist_tile.dart` — Playlist tile
- [ ] Design: `design_widgets/01, 02`

**Docs:** `design_library/02, 03, 06` + `design_widgets/01, 02`

---

## Phase 5 — Search

> **Goal:** Local search for tracks, albums, artists.

### 5.1 `search_page.dart`
- [ ] Search field
- [ ] Results by category (tracks, albums, artists)
- [ ] Design: `design_screens/03`

**Docs:** `design_screens/03`

---

## Phase 6 — Settings Page

> **Goal:** Full settings page.

### 6.1 `settings_page.dart`
- [ ] Sections: Appearance, Playback, Library, Storage, Advanced
- [ ] Reuse `SettingsTile` from onboarding
- [ ] Design: `design_settings/01`

### 6.2 Sub-settings
- [ ] Theme settings (`design_settings/02`)
- [ ] Indexer settings (`design_settings/03`)
- [ ] Playback settings (`design_settings/04`)
- [ ] Customization (`design_settings/05`)
- [ ] Backup & Restore (`design_settings/08`)

**Docs:** `design_settings/*`

---

## Phase 7 — Advanced Dialogs

> **Goal:** Context menus and detail dialogs.

### 7.1 `track_info_dialog.dart`
- [ ] Detailed track info with dynamic color
- [ ] Design: `design_dialogs/01`

### 7.2 `common_dialogs.dart`
- [ ] Universal ⋮ menu
- [ ] Add to playlist, queue, favorites
- [ ] Design: `design_dialogs/05`

### 7.3 `edit_tags_dialog.dart`
- [ ] Edit track metadata
- [ ] Design: `design_dialogs/03`

**Docs:** `design_dialogs/01, 03, 05`

---

## Phase 8 — arc_engine + arx_canvas

> **Goal:** Connect audio and visual plugins.

### 8.1 arc_engine
- [ ] Compile native libraries (FLAC, OGG) for arm64-v8a
- [ ] Add x86_64 for emulator testing
- [ ] Connect `PlayerController` with arc_engine

### 8.2 arx_canvas
- [ ] Animated artwork (Apple/Spotify style)
- [ ] Synchronized lyrics
- [ ] Asset caching

**Docs:** `API-ArcEngine.md` + `API-ArxCanvas.md`

---

## Phase 9 — Final Polish

> **Goal:** Details, animations, accessibility.

- [ ] Smooth page transitions
- [ ] Optimized scroll (`packages/scroll_physics_modified.dart`)
- [ ] Tinted popups (`packages/custom_popup.dart`)
- [ ] Animated widgets (`packages/animated_widgets.dart`)
- [ ] Accessibility (semantics)
- [ ] Performance profiling
- [ ] Testing

---

## Summary

| Phase | Status | Dependencies |
|-------|--------|-------------|
| Core | Completed | — |
| Onboarding | Completed | Core |
| 1. Main Page + Miniplayer | Completed | Core |
| 2. Player Page | Next | Phase 1 |
| 3. Indexer + Tracks | Pending | Phase 1 |
| 4. Library | Pending | Phase 3 |
| 5. Search | Pending | Phase 3 |
| 6. Settings | Pending | Phase 1 |
| 7. Dialogs | Pending | Phase 3 |
| 8. Plugins | Pending | Phase 2 |
| 9. Polish | Pending | All |

---

## Empty Files (22)

The following files exist but are empty — they are implemented in the indicated phases:

**Pages (7):** tracks_page, albums_page, artists_page, playlists_page, search_page, settings_page, player_page

**Miniplayer (2):** player_page, lyrics_view

**Controllers (5):** indexer_controller, queue_controller, playlist_controller, history_controller, current_color_controller

**Services (4):** lyrics_service, audio_tags, arx_canvas_client, artwork_service

**Core (1):** utils

**Widgets (5):** custom_widgets, artwork, waveform, sort_by_button, explandable_box
