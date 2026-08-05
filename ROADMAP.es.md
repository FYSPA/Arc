# Arc — Roadmap de Desarrollo

> Última actualización: 2026-08-04
> Stack: Flutter + Provider + arc_engine + arx_canvas

---

## Completado

### Core (Fundamentos)
- [x] `themes.dart` — Temas light/dark/AMOLED, font LexendDeca
- [x] `dimensions.dart` — Sistema de escala (space, multipliedRadius)
- [x] `constans.dart` — Colores de marca (kMainColorLight/Dark, pitchBlack)
- [x] `extensions.dart` — Color extensions (alphaBlendWith, withOpacityExt)
- [x] `broken_icons.dart` — 900+ iconos custom

### Controllers
- [x] `settings_controller.dart` — Theme, language, performance, folders, media store + **persistencia con SharedPreferences**
- [x] `navigator_controller.dart` — Estado de navegación (currentPageIndex, navigateTo)
- [x] `player_controller.dart` — Wrapper de arc_engine, cola, gapless, MediaSession
- [x] `current_color_controller.dart` — Color de acento dinámico desde la carátula
- [x] `indexer_controller.dart` — Escaneo chunked de MediaStore + filtrado por carpetas

### Modelos
- [x] `track.dart` — Modelo ArcTrack (fromMap)
- [x] `album.dart` — Modelo ArcAlbum (fromMap)
- [x] `artist.dart` — Modelo ArcArtist (fromMap)

### Servicios
- [x] `permission_service.dart` — MethodChannel custom para permiso de audio en Android 13+
- [x] `media_store_service.dart` — MethodChannel custom para songs, albums, artists, folders, artwork
- [x] `artwork_service.dart` — Caché de dos niveles + getArtworkImage() + getCachedPath()

### UI — Onboarding
- [x] `onboarding_page.dart` — PageView de 3 páginas (Apariencia, Permisos, Biblioteca)
- [x] `onboarding_appearance.dart` — Tema, color, AMOLED, glow, idioma, border radius
- [x] `onboarding_permissions.dart` — Permiso de almacenamiento + selección de carpetas
- [x] `onboarding_library.dart` — Tabs de biblioteca, rendimiento, configuración FAB
- [x] `settings_tile.dart` — Widget genérico (tap/toggle/expansion)
- [x] `settings_card.dart` — Card contenedora con header
- [x] `animated_check_mark.dart` — Checkmark animado
- [x] `section_header.dart` — Separador de secciones
- [x] `onboarding_page_header.dart` — Header reutilizable para páginas de onboarding

### UI — Diálogos
- [x] `theme_dialog.dart` — Selector visual con cards
- [x] `performance_dialog.dart` — Selector visual con cards
- [x] `color_picker_dialog.dart` — Selector de color de acento
- [x] `language_dialog.dart` — Selector de idioma
- [x] `library_tabs_dialog.dart` — Configuración de tabs

### UI — Main Page + Miniplayer
- [x] `main_page.dart` — Scaffold + AppBar + IndexedStack + NavigationBar M3 + botón Settings
- [x] `miniplayer_bar.dart` — Lee de PlayerController, play/pause, abre PlayerPage
- [x] `home_page.dart` — Secciones Recently Added, Top Artists/Albums
- [x] `albums_page.dart` — Grid de 2 columnas con artwork
- [x] `artists_page.dart` — Lista con artwork circular
- [x] `tracks_page.dart` — Lista searchable/sortable con carga progresiva

### UI — Player
- [x] `player_page.dart` — Pantalla completa con artwork, controles, vista de cola, toggle de letras
- [x] `lyrics_view.dart` — Obtiene letras vía arx_canvas, maneja cambios de track + race conditions

### UI — Settings
- [x] `settings_page.dart` — 4 secciones: Apariencia, Biblioteca, Audio, Acerca de + **Secrets Keys**

### Splash
- [x] `splash_page.dart` — GIF con ShaderMask para dark mode, routing condicional a onboarding/main

### Infraestructura
- [x] Fonts registrados (LexendDeca 9 pesos + Broken icons)
- [x] Package ID cambiado a `dev.yh.arc_app`
- [x] Flujo de navegación: Splash → Onboarding → MainPage
- [x] **Persistencia con SharedPreferences** — Todos los settings sobreviven el reinicio
- [x] **Onboarding solo se muestra una vez** — `_isOnboarded` persistido a disco
- [x] **arc_engine** — Reproducción de audio nativa en C++ (FFI)
- [x] **arx_canvas** — Obtención de letras (LRCLIB, Genius, Musixmatch, etc.)

---

## Fase 3 — Biblioteca (Albums, Artists, Playlists)

> **Estado:** Pendiente

### 3.1 `albums_page.dart`
- [x] Grid de álbumes con artwork (hecho en Fase 2)
- [ ] Tap → tracks del álbum

### 3.2 `artists_page.dart`
- [x] Grid de artistas (hecho en Fase 2)
- [ ] Tap → tracks del artista

### 3.3 `playlists_page.dart`
- [ ] Lista de playlists
- [ ] Crear playlist

### 3.4 `playlist_controller.dart`
- [ ] CRUD de playlists
- [ ] Agregar/quitar tracks

---

## Fase 4 — Búsqueda

> **Estado:** Pendiente

### 4.1 `search_page.dart`
- [ ] Campo de búsqueda
- [ ] Resultados por categoría (tracks, albums, artists)

---

## Fase 6 — Diálogos Avanzados

> **Estado:** Pendiente

### 6.1 `track_info_dialog.dart`
- [ ] Info detallada del track con color dinámico

### 6.2 `common_dialogs.dart`
- [ ] Menú universal
- [ ] Agregar a playlist, cola, favoritos

### 6.3 `edit_tags_dialog.dart`
- [ ] Editar metadata de tracks

---

## Fase 7 — Integración completa arx_canvas

> **Estado:** Parcialmente completada

### 7.1 Letras
- [x] Obtención de letras plain text vía LyricsService (multi-provider fallback)
- [x] Detección de cambio de track + fix de race conditions
- [x] Secrets keys para Genius, Musixmatch, Spotify
- [ ] Letras sincronizadas con auto-scroll
- [ ] Highlight de línea actual

### 7.2 Artwork animado
- [ ] Artwork animado de Apple Music
- [ ] Spotify Canvas
- [ ] Caché de assets

---

## Fase 8 — Pulido Final

> **Estado:** Pendiente

- [ ] Transiciones de página suaves
- [ ] Scroll optimizado
- [ ] Popups tintados
- [ ] Widgets animados
- [ ] Accesibilidad (semantics)
- [ ] Performance profiling
- [ ] Testing

---

## Resumen

| Fase | Estado | Dependencias |
|------|--------|-------------|
| Core | ✅ Completada | — |
| Onboarding | ✅ Completada | Core |
| Main Page + Miniplayer | ✅ Completada | Core |
| 1. Player Page | ✅ Completada | Main Page |
| 2. Indexador + Tracks | ✅ Completada | Main Page |
| 3. Biblioteca | Pendiente | Fase 2 |
| 4. Búsqueda | Pendiente | Fase 2 |
| 5. Settings | ✅ Completada | Main Page |
| 6. Diálogos | Pendiente | Fase 2 |
| 7. arx_canvas Full | Parcial | Fase 1 |
| 8. Pulido | Pendiente | Todas |
