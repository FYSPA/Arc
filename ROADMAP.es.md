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

### Controller
- [x] `settings_controller.dart` — Theme, language, performance, folders, media store

### UI — Onboarding
- [x] `onboarding_page.dart` — Full screen, AMOLED, section headers
- [x] `settings_tile.dart` — Widget genérico (tap/toggle/expansion)
- [x] `settings_card.dart` — Card contenedora con header
- [x] `animated_check_mark.dart` — Checkmark animado
- [x] `section_header.dart` — Separador de secciones
- [x] `onboarding_bottom_bar.dart` — Botones permiso + continuar

### UI — Diálogos
- [x] `theme_dialog.dart` — Selector visual con cards
- [x] `performance_dialog.dart` — Selector visual con cards
- [x] `backup_restore_dialog.dart` — Icono + botones

### Infraestructura
- [x] Fonts registrados (LexendDeca 9 pesos + Broken icons)
- [x] Package ID cambiado a `dev.yh.arc_app`
- [x] `arc_engine` / `arx_canvas` como dependencias git (temporalmente deshabilitadas)

---

## Fase 1 — Main Page + Miniplayer (PRIORIDAD MÁXIMA)

> **Objetivo:** Tener la pantalla principal funcionando con navegación y miniplayer.

### 1.1 `enums.dart` — Tipos de datos
- [ ] `LibraryTab` (songs, artists, albums, folders, genres, playlists)
- [ ] `SortType`, `SortDirection`
- [ ] `QueueSource`
- [ ] `MediaType`

### 1.2 `navigator_controller.dart` — Navegación
- [ ] Estado: `currentPageIndex` (bottom nav)
- [ ] Método: `navigateTo(index)`
- [ ] Stream/notifier para cambio de página

### 1.3 `main_page.dart` — Estructura principal
- [ ] `Scaffold` con `IndexedStack` o `PageView`
- [ ] `BottomNavigationBar` con 4-5 tabs
- [ ] `MiniplayerBar` integrado arriba del bottom nav
- [ ] Drawer (opcional, puede ser fase 7)

### 1.4 `miniplayer_bar.dart` — Barra contraída
- [ ] Altura ~82px
- [ ] Artwork thumbnail (48x48)
- [ ] Título + artista
- [ ] Play/pause button
- [ ] Swipe up → expandir a player_page
- [ ] Diseño: `design_extracted/07`

### 1.5 `home_page.dart` — Contenido del tab Home
- [ ] Stats recientes / favoritas
- [ ] Últimas canciones escuchadas
- [ ] Placeholder funcional

**Docs:** `design_extracted/07`, `design_screens/02`

---

## Fase 2 — Player Page (Reproductor)

> **Objetivo:** Pantalla completa del reproductor con artwork y controles.

### 2.1 `player_controller.dart` — Lógica de audio
- [ ] Conectar `just_audio` (o `arc_engine` cuando funcione)
- [ ] Estados: `playing`, `paused`, `position`, `duration`
- [ ] Métodos: `play()`, `pause()`, `seekTo()`, `skipNext()`, `skipPrevious()`
- [ ] Cola de reproducción

### 2.2 `current_color_controller.dart` — Color dinámico
- [ ] Extraer color dominante de la carátula
- [ ] Notificar cambio de color a toda la UI
- [ ] Animación de transición entre colores

### 2.3 `player_page.dart` — Pantalla completa
- [ ] Artwork grande con animación
- [ ] Título + artista + álbum
- [ ] Barra de progreso (slider)
- [ ] Controles: prev, play/pause, next, shuffle, repeat
- [ ] Botones: favorito, playlist, letras
- [ ] Diseño: `design_extracted/01, 02, 04`

### 2.4 `lyrics_view.dart` — Vista de letras
- [ ] Scroll sincronizado con la posición del audio
- [ ] Fade effect en líneas no activas
- [ ] Diseño: `design_extracted/08`

**Docs:** `design_extracted/01, 02, 04, 08` + `API-ArcEngine.md`

---

## Fase 3 — Indexador + Tracks Page

> **Objetivo:** Escanear la librería de música y mostrar la lista de canciones.

### 3.1 `indexer_controller.dart` — Escaneo
- [ ] Escanear carpetas del dispositivo
- [ ] Leer tags con `audio_tags` (título, artista, álbum, duración)
- [ ] Guardar en base de datos
- [ ] Progreso de indexación

### 3.2 `audio_tags.dart` — Service
- [ ] Leer metadata de MP3/FLAC
- [ ] Extraer carátula embedida

### 3.3 `tracks_page.dart` — Lista de canciones
- [ ] `ListView` con `TrackTile`
- [ ] Sorting (título, artista, fecha, duración)
- [ ] Selección múltiple
- [ ] Diseño: `design_library/01`

### 3.4 `track_tile.dart` — Widget de canción
- [ ] Artwork thumbnail + título + artista + duración
- [ ] Long press → menú contextual
- [ ] Tap → reproducir
- [ ] Diseño: `design_widgets/01`

**Docs:** `design_library/01` + `design_widgets/01`

---

## Fase 4 — Biblioteca (Albums, Artists, Playlists)

> **Objetivo:** Vistas de grid para álbumes, artistas y playlists.

### 4.1 `albums_page.dart`
- [ ] Grid de álbumes con artwork
- [ ] Tap → tracks del álbum
- [ ] Diseño: `design_library/02`

### 4.2 `artists_page.dart`
- [ ] Grid de artistas (imagen circular)
- [ ] Tap → tracks del artista
- [ ] Diseño: `design_library/03`

### 4.3 `playlists_page.dart`
- [ ] Lista de playlists
- [ ] Crear playlist
- [ ] Diseño: `design_library/06`

### 4.4 `playlist_controller.dart`
- [ ] CRUD de playlists
- [ ] Agregar/quitar tracks

### 4.5 Widgets de biblioteca
- [ ] `album_card.dart` — Card de álbum
- [ ] `artist_card.dart` — Card de artista
- [ ] `playlist_tile.dart` — Tile de playlist
- [ ] Diseño: `design_widgets/01, 02`

**Docs:** `design_library/02, 03, 06` + `design_widgets/01, 02`

---

## Fase 5 — Búsqueda

> **Objetivo:** Búsqueda local de tracks, álbumes, artistas.

### 5.1 `search_page.dart`
- [ ] Campo de búsqueda
- [ ] Resultados por categoría (tracks, albums, artists)
- [ ] Diseño: `design_screens/03`

**Docs:** `design_screens/03`

---

## Fase 6 — Settings Page

> **Objetivo:** Página completa de configuración.

### 6.1 `settings_page.dart`
- [ ] Secciones: Appearance, Playback, Library, Storage, Advanced
- [ ] Reusar `SettingsTile` del onboarding
- [ ] Diseño: `design_settings/01`

### 6.2 Sub-settings
- [ ] Theme settings (`design_settings/02`)
- [ ] Indexer settings (`design_settings/03`)
- [ ] Playback settings (`design_settings/04`)
- [ ] Customization (`design_settings/05`)
- [ ] Backup & Restore (`design_settings/08`)

**Docs:** `design_settings/*`

---

## Fase 7 — Diálogos Avanzados

> **Objetivo:** Menús contextuales y diálogos de detalle.

### 7.1 `track_info_dialog.dart`
- [ ] Info detallada del track con color dinámico
- [ ] Diseño: `design_dialogs/01`

### 7.2 `common_dialogs.dart`
- [ ] Menú ⋮ universal
- [ ] Agregar a playlist, cola, favoritos
- [ ] Diseño: `design_dialogs/05`

### 7.3 `edit_tags_dialog.dart`
- [ ] Editar metadata de tracks
- [ ] Diseño: `design_dialogs/03`

**Docs:** `design_dialogs/01, 03, 05`

---

## Fase 8 — arc_engine + arx_canvas

> **Objetivo:** Conectar los plugins de audio y visual.

### 8.1 arc_engine
- [ ] Compilar librerías nativas (FLAC, OGG) para arm64-v8a
- [ ] Agregar x86_64 para testing en emulador
- [ ] Conectar `PlayerController` con arc_engine

### 8.2 arx_canvas
- [ ] Artwork animado (Apple/Spotify style)
- [ ] Letras sincronizadas
- [ ] Cache de assets

**Docs:** `API-ArcEngine.md` + `API-ArxCanvas.md`

---

## Fase 9 — Pulido Final

> **Objetivo:** Detalles, animaciones, accesibilidad.

- [ ] Transiciones de página suaves
- [ ] Scroll optimizado (`packages/scroll_physics_modified.dart`)
- [ ] Popups tintados (`packages/custom_popup.dart`)
- [ ] Widgets animados (`packages/animated_widgets.dart`)
- [ ] Accesibilidad (semantics)
- [ ] Performance profiling
- [ ] Testing

---

## Resumen

| Fase | Estado | Dependencias |
|------|--------|-------------|
| Core | Completada | — |
| Onboarding | Completada | Core |
| 1. Main Page + Miniplayer | Siguiente | Core |
| 2. Player Page | Pendiente | Fase 1 |
| 3. Indexador + Tracks | Pendiente | Fase 1 |
| 4. Biblioteca | Pendiente | Fase 3 |
| 5. Búsqueda | Pendiente | Fase 3 |
| 6. Settings | Pendiente | Fase 1 |
| 7. Diálogos | Pendiente | Fase 3 |
| 8. Plugins | Pendiente | Fase 2 |
| 9. Pulido | Pendiente | Todas |

---

## Archivos vacíos (27)

Los siguientes archivos existen pero están vacíos — se implementan en las fases indicadas:

**Pages (8):** main_page, tracks_page, albums_page, artists_page, playlists_page, search_page, settings_page, player_page

**Miniplayer (3):** miniplayer_bar, player_page, lyrics_view

**Controllers (6):** indexer_controller, navigator_controller, queue_controller, playlist_controller, history_controller, current_color_controller

**Services (4):** lyrics_service, audio_tags, arx_canvas_client, artwork_service

**Core (2):** enums, utils

**Widgets (5):** custom_widgets, artwork, waveform, sort_by_button, explandable_box
