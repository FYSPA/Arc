import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:arx_canvas/arx_canvas.dart' as arx;
import 'package:path_provider/path_provider.dart';

import '../controller/settings_controller.dart';
import '../core/utils.dart';
import '../data/models/track.dart';

/// Workaround para arx_canvas (rev 845f83): el fallback hardcodeado de
/// [arx.SpotifyTotpGenerator] usa los bytes del secreto correcto (v61) pero
/// etiqueta la versión como 18, y Spotify rechaza `totpVer=18`. El escritorio
/// funciona porque descarga la v61 real; el teléfono (que no alcanza el host
/// del secreto) cae al fallback y falla con 401. Corregimos la versión a 61
/// cuando el generador devuelve la etiqueta obsoleta, sin reimplementar el TOTP.
class _CanvasTotpGenerator extends arx.SpotifyTotpGenerator {
  static const int _currentVersion = 61;

  @override
  Future<arx.TotpResult> generate() async {
    final r = await super.generate();
    if (r.version < _currentVersion) {
      logD(
        '[Canvas] totp fallback v${r.version} → corregido a v$_currentVersion',
      );
      return arx.TotpResult(code: r.code, version: _currentVersion);
    }
    logD('[Canvas] totp v${r.version} (descargado)');
    return r;
  }
}

/// Resolves and caches Spotify Canvas videos for the full player background.
///
/// The Spotify track id is resolved **at most once per track** and persisted to
/// disk (`canvas_cache.json`). This keeps the MusicLink free quota (300 uses /
/// key, ~600 with two keys) from being exhausted on every player open: the
/// resolver (Deezer → Odesli → MusicLink → Web API) runs only the first time,
/// afterwards the cached track id is used directly with `getCanvas`, which is
/// authenticated by the user's own `sp_dc` cookie (not MusicLink).
class CanvasService extends ChangeNotifier {
  CanvasService._();
  static final inst = CanvasService._();

  arx.SpotifyCanvasClient? _client;
  arx.SpotifyTrackResolver? _resolver;
  arx.SpotifyAuth? _auth;
  Directory? _cacheDir;

  final Map<int, String> _spotifyIds = {};

  /// Cache del resultado del canvas por canción: una sola llamada a la API de
  /// Spotify por track. `null` = esta canción no tiene canvas (o falló con
  /// cookie presente). No se cachea cuando no hay cookie, para reintentar si
  /// el usuario la agrega después.
  final Map<int, String?> _canvasUrls = {};

  /// Peticiones en vuelo por canción. Si el usuario entra/sale/entra al player
  /// rápido, las llamadas concurrentes comparten un mismo Future → una sola
  /// llamada a la API, sin desperdiciar red.
  final Map<int, Future<String?>> _inflight = {};
  Map<String, String>? _diskCache;
  Map<String, String?>? _urlDiskCache;

  Future<Directory> get _directory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/artwork_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  Future<Map<String, String>> get _cache async {
    if (_diskCache != null) return _diskCache!;
    final dir = await _directory;
    final file = File('${dir.path}/canvas_cache.json');
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _diskCache = map.map((k, v) => MapEntry(k, v as String));
      } catch (_) {
        _diskCache = {};
      }
    } else {
      _diskCache = {};
    }
    return _diskCache!;
  }

  Future<void> _saveCache() async {
    final dir = await _directory;
    final file = File('${dir.path}/canvas_cache.json');
    try {
      await file.writeAsString(jsonEncode(_diskCache ?? {}));
    } catch (_) {}
  }

  /// Cache persistent de la URL del canvas por canción (key = track id). A
  /// diferencia de [_canvasUrls] (que es solo en memoria y se pierde al reiniciar
  /// la app), esto evita volver a consumir la API de Spotify en cada reinicio.
  /// `null` = esta canción no tiene canvas (o falló con cookie presente).
  Future<Map<String, String?>> get _urlCache async {
    if (_urlDiskCache != null) return _urlDiskCache!;
    final dir = await _directory;
    final file = File('${dir.path}/canvas_urls.json');
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _urlDiskCache = map.map((k, v) => MapEntry(k, v as String?));
      } catch (_) {
        _urlDiskCache = {};
      }
    } else {
      _urlDiskCache = {};
    }
    return _urlDiskCache!;
  }

  Future<void> _saveUrlCache() async {
    final dir = await _directory;
    final file = File('${dir.path}/canvas_urls.json');
    try {
      await file.writeAsString(jsonEncode(_urlDiskCache ?? {}));
    } catch (_) {}
  }

  arx.SpotifyAuth _getAuth() {
    if (_auth != null) return _auth!;
    final s = SettingsController.inst;
    _auth = arx.SpotifyAuth(totpGenerator: _CanvasTotpGenerator());
    if (s.spotifySpDcCookie != null && s.spotifySpDcCookie!.isNotEmpty) {
      _auth!.setSpDcCookie(s.spotifySpDcCookie!);
    }
    return _auth!;
  }

  arx.SpotifyCanvasClient _getClient() {
    if (_client != null) return _client!;
    final auth = _getAuth();
    final service = arx.SpotifyCanvasService(auth: auth);
    _client = arx.SpotifyCanvasClient(auth: auth, service: service);
    return _client!;
  }

  arx.SpotifyTrackResolver _getResolver() {
    if (_resolver != null) return _resolver!;
    final s = SettingsController.inst;
    // Resolución gratuita (sin Premium): MusicLink + Odesli + Deezer.
    // El único token usado es el de sp_dc (no requiere Premium); se omite
    // Client Credentials (clientId/secret) porque exige Premium desde 2025.
    _resolver = arx.SpotifyTrackResolver(
      spotifyAuth: _getAuth(),
      deezerSearch: arx.DeezerSearch(),
      odesliService: arx.OdesliService(),
      musiclinkService: arx.MusicLinkService(apiKeys: s.allMusiclinkApiKeys),
      logger: arx.CallbackLogger(
        (e) =>
            logD('[Canvas:resolver] [${e.name}] ${e.level.name}: ${e.message}'),
      ),
    );
    return _resolver!;
  }

  /// Returns the HLS canvas URL for [track], or `null` when unavailable.
  /// The Spotify track id is resolved once per track and cached on disk, and
  /// the resulting canvas URL (or its absence) is cached in memory so rebuilds
  /// and widget remounts don't trigger a second Spotify API call. Concurrent
  /// calls for the same track share a single in-flight request.
  /// Returns `true` when the canvas result for [id] has already been resolved
  /// and turned out to be absent (no Canvas for this track). Used by the player
  /// to show a persistent "no canvas" marker.
  bool hasNoCanvas(int? id) =>
      id != null && _canvasUrls.containsKey(id) && _canvasUrls[id] == null;

  /// True cuando ya se resolvió/obtuvo un canvas para [id] (está en caché,
  /// ya sea en memoria o persistido en disco). Usado por el player para mostrar
  /// un indicador de que el canvas está disponible/cacheado.
  bool hasCachedCanvas(int? id) =>
      id != null && _canvasUrls.containsKey(id) && _canvasUrls[id] != null;

  /// Borra la URL cacheada de una canción (memoria + disco) para forzar su
  /// reobtención. Usado cuando una URL persistida expiró y el video falla al
  /// cargar: el caller la invoca y reintenta con [getCanvasUrl] (forceRefresh).
  Future<void> invalidateUrl(int? id) async {
    if (id == null) return;
    _canvasUrls.remove(id);
    final cache = await _urlCache;
    cache.remove(id.toString());
    await _saveUrlCache();
    notifyListeners();
  }

  Future<String?> getCanvasUrl(
    ArcTrack track, {
    bool forceRefresh = false,
  }) async {
    final id = track.id;
    if (!forceRefresh && _canvasUrls.containsKey(id)) return _canvasUrls[id];
    // Si ya hay una petición en vuelo para esta canción, compartirla en lugar
    // de disparar otra (el usuario puede haber entrado/salido del player).
    final existing = _inflight[id];
    if (existing != null) return existing;

    final future = _fetchCanvasForTrack(track, id, forceRefresh: forceRefresh);
    _inflight[id] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(id);
    }
  }

  Future<String?> _fetchCanvasForTrack(
    ArcTrack track,
    int id, {
    bool forceRefresh = false,
  }) async {
    final cookiePresent =
        SettingsController.inst.spotifySpDcCookie?.isNotEmpty ?? false;

    // Reusa la URL (o la ausencia de ella) cacheada en disco ANTES de resolver
    // el spotifyTrackId, para no consumir la API en cada reinicio cuando ya
    // sabemos que una canción no tiene canvas (caché con valor null).
    if (!forceRefresh) {
      final urlCache = await _urlCache;
      if (urlCache.containsKey(id.toString())) {
        final cached = urlCache[id.toString()];
        _canvasUrls[id] = cached;
        notifyListeners();
        logD(
          '[Canvas] url reusada desde caché de disco para "${track.title}"'
          '${cached == null ? ' (sin canvas)' : ''}',
        );
        return cached;
      }
    }

    String? spotifyId = _spotifyIds[id];
    if (spotifyId == null) {
      final cache = await _cache;
      spotifyId = cache[id.toString()];
      if (spotifyId != null) _spotifyIds[id] = spotifyId;
    }

    if (spotifyId == null) {
      final metadata = arx.ArcTrackMetadata.fromFlacData(
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: Duration(milliseconds: track.duration ?? 0),
      );
      try {
        spotifyId = await _getResolver().resolveFromMetadata(metadata);
      } catch (e) {
        logD(
          '[Canvas] resolve failed for "${track.title}" / "${track.artist}": $e',
        );
      }
      if (spotifyId == null || spotifyId.isEmpty) {
        logD(
          '[Canvas] no spotifyTrackId for "${track.title}" / "${track.artist}"',
        );
        if (cookiePresent) {
          _canvasUrls[id] = null;
          final urlCache = await _urlCache;
          urlCache[id.toString()] = null;
          await _saveUrlCache();
          notifyListeners();
        }
        return null;
      }

      logD('[Canvas] resolved spotifyTrackId for "${track.title}" (cached)');
      _spotifyIds[id] = spotifyId;
      final cache = await _cache;
      cache[id.toString()] = spotifyId;
      await _saveCache();
    }

    final url = await _fetchCanvas(spotifyId);
    if (cookiePresent) {
      _canvasUrls[id] = url;
      final urlCache = await _urlCache;
      urlCache[id.toString()] = url;
      await _saveUrlCache();
      notifyListeners();
    }
    return url;
  }

  Future<String?> _fetchCanvas(String spotifyId) async {
    final s = SettingsController.inst;
    final cookie = s.spotifySpDcCookie;
    if (cookie == null || cookie.isEmpty) {
      // arx_canvas fetches the canvas video through Spotify's internal API,
      // which authenticates with the sp_dc cookie. Without it there is no
      // canvas video — degrade gracefully to the gradient background.
      return null;
    }
    // ── Diagnóstico de la cookie sp_dc (aisla el 401 por valor mal pegado) ──
    final hasPrefix = cookie.contains('sp_dc=');
    final hasSpace = cookie.contains(RegExp(r'\s'));
    logD(
      '[Canvas] cookie len=${cookie.length} hasPrefix=$hasPrefix '
      'hasSpace=$hasSpace auth=${_getAuth().isAuthenticated}',
    );
    try {
      final video = await _getClient().getCanvas(spotifyId);
      if (video != null && video.url.isNotEmpty) {
        logD(
          '[Canvas] canvas url obtained for $spotifyId (${video.url.length} chars)',
        );
        return video.url;
      }
      logD('[Canvas] getCanvas returned no canvas for $spotifyId');
    } catch (e) {
      logD('[Canvas] getCanvas failed for $spotifyId: $e');
    }
    return null;
  }

  void disposeClient() {
    _client?.dispose();
    _client = null;
    _resolver?.dispose();
    _resolver = null;
    _auth = null;
  }
}
