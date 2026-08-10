# Arc — Development Roadmap

> Last updated: 2026-08-10
> Stack: Flutter + Provider + arc_engine + arx_canvas
> Strategy: **Logic first → Design → Performance**

---

## Completed

### Core (Foundation)
- [x] `themes.dart` — Light/dark/AMOLED themes, LexendDeca font
- [x] `dimensions.dart` — Scaling system (space, multipliedRadius)
- [x] `constans.dart` — Brand colors (kMainColorLight/Dark, pitchBlack)
- [x] `extensions.dart` — Color extensions (alphaBlendWith, withOpacityExt)
- [x] `broken_icons.dart` — 900+ custom icons

### Controller
- [x] `settings_controller.dart` — Theme, language, performance, folders, media store + SharedPreferences persistence
- [x] `navigator_controller.dart` — Navigation state (currentPageIndex, navigateTo)
- [x] `player_controller.dart` — arc_engine wrapper, queue, gapless, MediaSession, failure skip
- [x] `current_color_controller.dart` — Dynamic accent color from artwork
- [x] `indexer_controller.dart` — Chunked MediaStore scanning + folder filtering + sort cache

### Models
- [x] `track.dart` — ArcTrack model (fromMap)
- [x] `album.dart` — ArcAlbum model (fromMap)
- [x] `artist.dart` — ArcArtist model (fromMap)

### Services
- [x] `permission_service.dart` — Custom MethodChannel for Android 13+ audio permission
- [x] `media_store_service.dart` — Custom MethodChannel for songs, albums, artists, folders, artwork
- [x] `artwork_service.dart` — Two-tier cache + throttle pool + off-main-thread Kotlin decode

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
- [x] `main_page.dart` — Scaffold + AppBar + IndexedStack + NavigationBar M3
- [x] `miniplayer_bar.dart` — Reads from PlayerController, play/pause, opens PlayerPage
- [x] `home_page.dart` — Recently Added, Top Artists/Albums sections
- [x] `albums_page.dart` — 2-column grid with artwork
- [x] `artists_page.dart` — List with circular artwork
- [x] `tracks_page.dart` — Searchable/sortable list with progressive loading

### UI — Player
- [x] `player_page.dart` — Full-screen with artwork, controls, queue view, lyrics toggle
- [x] `lyrics_view.dart` — Fetches lyrics via arx_canvas, handles track changes + race conditions

### UI — Settings
- [x] `settings_page.dart` — 4 sections: Appearance, Library, Audio, About + Secrets Keys

### Splash
- [x] `splash_page.dart` — GIF with ShaderMask for dark mode, preload data during splash

### Infrastructure
- [x] Fonts registered (LexendDeca 9 weights + Broken icons)
- [x] Package ID changed to `dev.yh.arc_app`
- [x] Navigation flow: Splash → Onboarding → MainPage
- [x] SharedPreferences persistence — All settings survive app restart
- [x] Onboarding shown only once — `_isOnboarded` persisted to disk
- [x] arc_engine — Native C++ audio playback (FFI) updated to 34c9f6c
- [x] arx_canvas — Lyrics fetching (LRCLIB, Genius, Musixmatch, etc.)

---

## Phase 3A — Album Detail Page

> **Status:** ✅ Completed

- [x] `album_detail_page.dart` — Full page (not bottom sheet)
- [x] Album artwork header + track list
- [x] Play all / shuffle buttons
- [x] Tap track → play with album queue
- [x] Navigation from `albums_page.dart` tap

---

## Phase 3B — Artist Detail Page

> **Status:** ✅ Completed

- [x] `artist_detail_page.dart` — Full page (not bottom sheet)
- [x] Artist artwork + track list grouped by album
- [x] Play all / shuffle buttons
- [x] Tap track → play with artist queue
- [x] Navigation from `artists_page.dart` tap

---

## Phase 3C — Folders Page

> **Status:** ✅ Completed

- [x] `folders_page.dart` — Real implementation (replace placeholder)
- [x] List folders with song count
- [x] Tap folder → folder tracks
- [x] Tap track → play with folder queue
- [x] Uses `queryFolders()` from MediaStoreService

---

## Phase 4 — Global Search

> **Status:** ✅ Completed

- [x] `search_page.dart` — Dedicated search tab or overlay
- [x] Search across tracks, albums, artists simultaneously
- [x] Results grouped by category with section headers
- [x] Debounced input (300ms)
- [x] Tap result → navigate to detail or play

---

## Phase 5A — Track Context Menu

> **Status:** ✅ Completed

- [x] `track_context_menu.dart` — Bottom sheet menu on long-press
- [x] Options: Add to queue, Play next, Track info, Share
- [x] Works from any track list (home, tracks, album detail, artist detail, folders, search)

---

## Phase 5B — Queue Management

> **Status:** ✅ Completed

- [x] Drag-to-reorder in queue view (ReorderableListView)
- [x] Swipe to remove from queue (Dismissible)
- [x] Clear queue button in queue header
- [x] Queue header with track count

---

## Phase 6 — Synced Lyrics

> **Status:** ✅ Completed

- [x] Parse synced lyrics (LRC format) from arx_canvas
- [x] Auto-scroll to current line based on playback position
- [x] Highlight current line with accent color
- [x] Tap line to seek
- [x] Fallback to plain lyrics when synced unavailable

---

## Phase 7 — Animated Artwork

> **Status:** ✅ Completed

- [x] Animated artwork support via arx_canvas (Apple Music, Spotify Canvas)
- [x] GIF/video artwork display in player page and album detail header
- [x] Asset caching for animated artwork (CacheManager)
- [x] Graceful fallback to static artwork (local MediaStore + online iTunes/Deezer/Spotify)
- [x] Album detail: AnimatedArtworkWidget in header with static fallback
- [x] Online artwork fallback in track list, albums grid, artists list, home page
- [x] Artist photos via ArtistPhotoServiceWrapper (Deezer/AMP/Spotify)
- [x] ImageProvider cache for instant artwork sharing between miniplayer/player
- [x] Pre-cache album artwork during indexing
- [x] Fix: video conflict between album detail and player (isPlaying sync)

---

## Phase 7B — Delete Songs

> **Status:** Pending

- [ ] Android permission: `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="32"`
- [ ] Native handler: `"deleteSong"` on `arc_app/media` channel (ContentResolver + File.delete)
- [ ] Dart service: `MediaStoreService.deleteSong(id, filePath)`
- [ ] Indexer: `removeTrack(ArcTrack)` method (remove from lists, invalidate sort cache)
- [ ] Player: `removeFromQueueByTrack(ArcTrack)` + skip to next if deleted track is current
- [ ] UI: Add "Delete" option with `Broken.trash` icon to TrackContextMenu
- [ ] Confirmation dialog before permanent deletion
- [ ] Snackbar confirmation after deletion

---

## Phase 8 — Design Polish (Diseño)

> **Status:** Pending (after all logic is complete)

- [ ] Smooth page transitions (Hero animations)
- [ ] Tinted popups/dialogs with dynamic color
- [ ] Animated widgets (micro-interactions)
- [ ] Custom AppBar designs per page
- [ ] Accessibility (semantics)
- [ ] Theme refinement

---

## Phase 9 — Performance (Performance)

> **Status:** Pending (after design is complete)

- [ ] Performance profiling with DevTools
- [ ] Scroll optimization (repaint boundaries, cache extent)
- [ ] Image memory management
- [ ] Reduce widget rebuilds
- [ ] Lazy loading optimization
- [ ] APK size optimization

---

## Summary

| Phase | Description | Status | Strategy |
|-------|-------------|--------|----------|
| Core | Foundation | ✅ Completed | — |
| 1. Player | Playback UI | ✅ Completed | — |
| 2. Indexer | Track scanning + listing | ✅ Completed | — |
| 3A | Album detail page | ✅ Completed | Logic |
| 3B | Artist detail page | ✅ Completed | Logic |
| 3C | Folders page | ✅ Completed | Logic |
| 4 | Global search | ✅ Completed | Logic |
| 5A | Track context menu | ✅ Completed | Logic |
| 5B | Queue management | ✅ Completed | Logic |
| 6 | Synced lyrics | ✅ Completed | Logic |
| 7 | Animated artwork | ✅ Completed | Logic |
| 7B | Delete songs | ⏳ Pending | Logic |
| 8 | Design polish | ⏳ Pending | Design |
| 9 | Performance | ⏳ Pending | Performance |
