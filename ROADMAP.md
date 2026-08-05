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
- [x] `broken_icons.dart` — 900+ custom icons

### Controller
- [x] `settings_controller.dart` — Theme, language, performance, folders, media store + **SharedPreferences persistence**
- [x] `navigator_controller.dart` — Navigation state (currentPageIndex, navigateTo)
- [x] `player_controller.dart` — arc_engine wrapper, queue, gapless, MediaSession
- [x] `current_color_controller.dart` — Dynamic accent color from artwork
- [x] `indexer_controller.dart` — Chunked MediaStore scanning + folder filtering

### Models
- [x] `track.dart` — ArcTrack model (fromMap)
- [x] `album.dart` — ArcAlbum model (fromMap)
- [x] `artist.dart` — ArcArtist model (fromMap)

### Services
- [x] `permission_service.dart` — Custom MethodChannel for Android 13+ audio permission
- [x] `media_store_service.dart` — Custom MethodChannel for songs, albums, artists, folders, artwork
- [x] `artwork_service.dart` — Two-tier cache + getArtworkImage() + getCachedPath()

### UI — Onboarding
- [x] `onboarding_page.dart` — 3-page PageView (Appearance, Permissions, Library)
- [x] `onboarding_appearance.dart` — Theme, color, AMOLED, glow, language, border radius
- [x] `onboarding_permissions.dart` — Storage permission + folder selection
- [x] `onboarding_library.dart` — Library tabs, performance, FAB config
- [x] `settings_tile.dart` — Generic widget (tap/toggle/expansion)
- [x] `settings_card.dart` — Container card with header
- [x] `animated_check_mark.dart` — Animated checkmark
- [x] `section_header.dart` — Section separator
- [x] `onboarding_page_header.dart` — Reusable header for onboarding pages

### UI — Dialogs
- [x] `theme_dialog.dart` — Visual selector with cards
- [x] `performance_dialog.dart` — Visual selector with cards
- [x] `color_picker_dialog.dart` — Accent color picker
- [x] `language_dialog.dart` — Language selector
- [x] `library_tabs_dialog.dart` — Tab configuration

### UI — Main Page + Miniplayer
- [x] `main_page.dart` — Scaffold + AppBar + IndexedStack + NavigationBar M3 + Settings button
- [x] `miniplayer_bar.dart` — Reads from PlayerController, play/pause, opens PlayerPage
- [x] `home_page.dart` — Recently Added, Top Artists/Albums sections
- [x] `albums_page.dart` — 2-column grid with artwork
- [x] `artists_page.dart` — List with circular artwork
- [x] `tracks_page.dart` — Searchable/sortable list with progressive loading

### UI — Player
- [x] `player_page.dart` — Full-screen with artwork, controls, queue view, lyrics toggle
- [x] `lyrics_view.dart` — Fetches lyrics via arx_canvas, handles track changes + race conditions

### UI — Settings
- [x] `settings_page.dart` — 4 sections: Appearance, Library, Audio, About + **Secrets Keys**

### Splash
- [x] `splash_page.dart` — GIF with ShaderMask for dark mode, conditional routing to onboarding/main

### Infrastructure
- [x] Fonts registered (LexendDeca 9 weights + Broken icons)
- [x] Package ID changed to `dev.yh.arc_app`
- [x] Navigation flow: Splash → Onboarding → MainPage
- [x] **SharedPreferences persistence** — All settings survive app restart
- [x] **Onboarding shown only once** — `_isOnboarded` persisted to disk
- [x] **arc_engine** — Native C++ audio playback (FFI)
- [x] **arx_canvas** — Lyrics fetching (LRCLIB, Genius, Musixmatch, etc.)

---

## Phase 3 — Library (Albums, Artists, Playlists)

> **Status:** Pending

### 3.1 `albums_page.dart`
- [x] Album grid with artwork (done in Phase 2)
- [ ] Tap → album tracks

### 3.2 `artists_page.dart`
- [x] Artist grid (done in Phase 2)
- [ ] Tap → artist tracks

### 3.3 `playlists_page.dart`
- [ ] Playlist list
- [ ] Create playlist

### 3.4 `playlist_controller.dart`
- [ ] Playlist CRUD
- [ ] Add/remove tracks

---

## Phase 4 — Search

> **Status:** Pending

### 4.1 `search_page.dart`
- [ ] Search field
- [ ] Results by category (tracks, albums, artists)

---

## Phase 6 — Advanced Dialogs

> **Status:** Pending

### 6.1 `track_info_dialog.dart`
- [ ] Detailed track info with dynamic color

### 6.2 `common_dialogs.dart`
- [ ] Universal menu
- [ ] Add to playlist, queue, favorites

### 6.3 `edit_tags_dialog.dart`
- [ ] Edit track metadata

---

## Phase 7 — arx_canvas Full Integration

> **Status:** Partially Complete

### 7.1 Lyrics
- [x] Plain lyrics fetching via LyricsService (multi-provider fallback)
- [x] Track change detection + race condition fix
- [x] Secrets keys for Genius, Musixmatch, Spotify
- [ ] Synced lyrics with auto-scroll
- [ ] Line highlighting

### 7.2 Animated artwork
- [ ] Apple Music animated artwork
- [ ] Spotify Canvas
- [ ] Asset caching

---

## Phase 8 — Final Polish

> **Status:** Pending

- [ ] Smooth page transitions
- [ ] Optimized scroll
- [ ] Tinted popups
- [ ] Animated widgets
- [ ] Accessibility (semantics)
- [ ] Performance profiling
- [ ] Testing

---

## Summary

| Phase | Status | Dependencies |
|-------|--------|-------------|
| Core | ✅ Completed | — |
| Onboarding | ✅ Completed | Core |
| Main Page + Miniplayer | ✅ Completed | Core |
| 1. Player Page | ✅ Completed | Main Page |
| 2. Indexer + Tracks | ✅ Completed | Main Page |
| 3. Library | Pending | Phase 2 |
| 4. Search | Pending | Phase 2 |
| 5. Settings | ✅ Completed | Main Page |
| 6. Dialogs | Pending | Phase 2 |
| 7. arx_canvas Full | Partial | Phase 1 |
| 8. Polish | Pending | All |
