# Arc — Roadmap de Desarrollo

> Última actualización: 2026-08-10
> Stack: Flutter + Provider + arc_engine + arx_canvas
> Estrategia: **Lógica primero → Diseño → Performance**

---

## Completado

### Core (Fundamentos)
- [x] `themes.dart` — Temas light/dark/AMOLED, font LexendDeca
- [x] `dimensions.dart` — Sistema de escala (space, multipliedRadius)
- [x] `constans.dart` — Colores de marca (kMainColorLight/Dark, pitchBlack)
- [x] `extensions.dart` — Color extensions (alphaBlendWith, withOpacityExt)
- [x] `broken_icons.dart` — 900+ iconos custom

### Controllers
- [x] `settings_controller.dart` — Theme, language, performance, folders, media store + persistencia con SharedPreferences
- [x] `navigator_controller.dart` — Estado de navegación (currentPageIndex, navigateTo)
- [x] `player_controller.dart` — Wrapper de arc_engine, cola, gapless, MediaSession, auto-skip en fallos
- [x] `current_color_controller.dart` — Color de acento dinámico desde la carátula
- [x] `indexer_controller.dart` — Escaneo chunked de MediaStore + filtrado por carpetas + caché de sort

### Modelos
- [x] `track.dart` — Modelo ArcTrack (fromMap)
- [x] `album.dart` — Modelo ArcAlbum (fromMap)
- [x] `artist.dart` — Modelo ArcArtist (fromMap)

### Servicios
- [x] `permission_service.dart` — MethodChannel custom para permiso de audio en Android 13+
- [x] `media_store_service.dart` — MethodChannel custom para songs, albums, artists, folders, artwork
- [x] `artwork_service.dart` — Caché de dos niveles + throttle pool + decode off-main-thread en Kotlin

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
- [x] `main_page.dart` — Scaffold + AppBar + IndexedStack + NavigationBar M3
- [x] `miniplayer_bar.dart` — Lee de PlayerController, play/pause, abre PlayerPage
- [x] `home_page.dart` — Secciones Recently Added, Top Artists/Albums
- [x] `albums_page.dart` — Grid de 2 columnas con artwork
- [x] `artists_page.dart` — Lista con artwork circular
- [x] `tracks_page.dart` — Lista searchable/sortable con carga progresiva

### UI — Player
- [x] `player_page.dart` — Pantalla completa con artwork, controles, vista de cola, toggle de letras
- [x] `lyrics_view.dart` — Obtiene letras vía arx_canvas, maneja cambios de track + race conditions

### UI — Settings
- [x] `settings_page.dart` — 4 secciones: Apariencia, Biblioteca, Audio, Acerca de + Secrets Keys

### Splash
- [x] `splash_page.dart` — GIF con ShaderMask para dark mode, precarga de datos durante splash

### Infraestructura
- [x] Fonts registrados (LexendDeca 9 pesos + Broken icons)
- [x] Package ID cambiado a `dev.yh.arc_app`
- [x] Flujo de navegación: Splash → Onboarding → MainPage
- [x] Persistencia con SharedPreferences — Todos los settings sobreviven el reinicio
- [x] Onboarding solo se muestra una vez — `_isOnboarded` persistido a disco
- [x] arc_engine — Reproducción de audio nativa en C++ (FFI) actualizado a 34c9f6c
- [x] arx_canvas — Obtención de letras (LRCLIB, Genius, Musixmatch, etc.)

---

## Fase 3A — Página de Detalle de Álbum

> **Estado:** ✅ Completada

- [x] `album_detail_page.dart` — Página completa (no bottom sheet)
- [x] Header con artwork del álbum + lista de tracks
- [x] Botones Play all / Shuffle
- [x] Tap track → reproducir con cola del álbum
- [x] Navegación desde `albums_page.dart` al tocar

---

## Fase 3B — Página de Detalle de Artista

> **Estado:** ✅ Completada

- [x] `artist_detail_page.dart` — Página completa (no bottom sheet)
- [x] Artwork del artista + lista de tracks agrupados por álbum
- [x] Botones Play all / Shuffle
- [x] Tap track → reproducir con cola del artista
- [x] Navegación desde `artists_page.dart` al tocar

---

## Fase 3C — Página de Carpetas

> **Estado:** ✅ Completada

- [x] `folders_page.dart` — Implementación real (reemplazar placeholder)
- [x] Lista de carpetas con conteo de canciones
- [x] Tap carpeta → tracks de la carpeta
- [x] Tap track → reproducir con cola de la carpeta
- [x] Usa `queryFolders()` de MediaStoreService

---

## Fase 4 — Búsqueda Global

> **Estado:** ✅ Completada

- [x] `search_page.dart` — Tab o overlay de búsqueda dedicado
- [x] Buscar en tracks, álbumes y artistas simultáneamente
- [x] Resultados agrupados por categoría con headers
- [x] Input con debounce (300ms)
- [x] Tap resultado → navegar al detalle o reproducir

---

## Fase 5A — Menú Contextual de Track

> **Estado:** ✅ Completada

- [x] `track_context_menu.dart` — Bottom sheet al hacer long-press
- [x] Opciones: Agregar a cola, Reproducir siguiente, Info del track, Compartir
- [x] Funciona desde cualquier lista de tracks (home, tracks, detalle álbum, detalle artista, carpetas, búsqueda)

---

## Fase 5B — Gestión de Cola

> **Estado:** ✅ Completada

- [x] Drag-to-reorder en la vista de cola (ReorderableListView)
- [x] Swipe para quitar de la cola (Dismissible)
- [x] Botón limpiar cola en el header
- [x] Header de cola con conteo de tracks

---

## Fase 6 — Letras Sincronizadas

> **Estado:** ✅ Completada

- [x] Parsear letras sincronizadas (formato LRC) de arx_canvas
- [x] Auto-scroll a la línea actual según la posición de reproducción
- [x] Highlight de la línea actual con color de acento
- [x] Tap en línea para buscar (seek)
- [x] Fallback a letras plain cuando no hay sincronización disponible

---

## Fase 7 — Artwork Animado

> **Estado:** ✅ Completada

- [x] Soporte de artwork animado vía arx_canvas (Apple Music, Spotify Canvas)
- [x] Display de artwork GIF/video en la página del player y header del detalle de álbum
- [x] Caché de assets para artwork animado (CacheManager)
- [x] Fallback graceful a artwork estático (local MediaStore + online iTunes/Deezer/Spotify)
- [x] Detalle de álbum: AnimatedArtworkWidget en header con fallback estático
- [x] Fallback online de artwork en lista de tracks, grid de álbumes, lista de artistas, home page
- [x] Fotos de artistas vía ArtistPhotoServiceWrapper (Deezer/AMP/Spotify)
- [x] Caché de ImageProvider para compartir artwork instantáneamente entre miniplayer/player
- [x] Pre-caché de artwork de álbumes durante el indexado
- [x] Fix: conflicto de video entre detalle de álbum y player (sincronización de isPlaying)

---

## Fase 7B — Eliminar Canciones

> **Estado:** Pendiente

- [ ] Permiso Android: `WRITE_EXTERNAL_STORAGE` con `maxSdkVersion="32"`
- [ ] Handler nativo: `"deleteSong"` en canal `arc_app/media` (ContentResolver + File.delete)
- [ ] Servicio Dart: `MediaStoreService.deleteSong(id, filePath)`
- [ ] Indexer: método `removeTrack(ArcTrack)` (quitar de listas, invalidar caché de sort)
- [ ] Player: `removeFromQueueByTrack(ArcTrack)` + saltar a siguiente si la canción eliminada es la actual
- [ ] UI: Agregar opción "Eliminar" con icono `Broken.trash` en TrackContextMenu
- [ ] Diálogo de confirmación antes de eliminación permanente
- [ ] Snackbar de confirmación después de la eliminación

---

## Fase 8 — Pulido de Diseño (Diseño)

> **Estado:** Pendiente (después de completar toda la lógica)

- [ ] Transiciones de página suaves (Hero animations)
- [ ] Popups/diálogos tintados con color dinámico
- [ ] Widgets animados (micro-interacciones)
- [ ] AppBars customizados por página
- [ ] Accesibilidad (semantics)
- [ ] Refinamiento de temas

---

## Fase 9 — Performance

> **Estado:** Pendiente (después del diseño)

- [ ] Profiling de performance con DevTools
- [ ] Optimización de scroll (repaint boundaries, cache extent)
- [ ] Gestión de memoria de imágenes
- [ ] Reducir rebuilds innecesarios de widgets
- [ ] Optimización de lazy loading
- [ ] Optimización de tamaño del APK

---

## Resumen

| Fase | Descripción | Estado | Estrategia |
|------|-------------|--------|------------|
| Core | Fundamentos | ✅ Completada | — |
| 1. Player | UI de reproducción | ✅ Completada | — |
| 2. Indexador | Escaneo y listado | ✅ Completada | — |
| 3A | Detalle de álbum | ✅ Completada | Lógica |
| 3B | Detalle de artista | ✅ Completada | Lógica |
| 3C | Página de carpetas | ✅ Completada | Lógica |
| 4 | Búsqueda global | ✅ Completada | Lógica |
| 5A | Menú contextual | ✅ Completada | Lógica |
| 5B | Gestión de cola | ✅ Completada | Lógica |
| 6 | Letras sincronizadas | ✅ Completada | Lógica |
| 7 | Artwork animado | ✅ Completada | Lógica |
| 7B | Eliminar canciones | ⏳ Pendiente | Lógica |
| 8 | Pulido de diseño | ⏳ Pendiente | Diseño |
| 9 | Performance | ⏳ Pendiente | Performance |
