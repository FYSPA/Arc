import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
class CanvasService {
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

  Future<String?> getCanvasUrl(ArcTrack track) async {
    final id = track.id;
    if (_canvasUrls.containsKey(id)) return _canvasUrls[id];
    // Si ya hay una petición en vuelo para esta canción, compartirla en lugar
    // de disparar otra (el usuario puede haber entrado/salido del player).
    final existing = _inflight[id];
    if (existing != null) return existing;

    final future = _fetchCanvasForTrack(track, id);
    _inflight[id] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(id);
    }
  }

  Future<String?> _fetchCanvasForTrack(ArcTrack track, int id) async {
    final cookiePresent =
        SettingsController.inst.spotifySpDcCookie?.isNotEmpty ?? false;

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
        if (cookiePresent) _canvasUrls[id] = null;
        return null;
      }

      logD('[Canvas] resolved spotifyTrackId for "${track.title}" (cached)');
      _spotifyIds[id] = spotifyId;
      final cache = await _cache;
      cache[id.toString()] = spotifyId;
      await _saveCache();
    }

    final url = await _fetchCanvas(spotifyId);
    if (cookiePresent) _canvasUrls[id] = url;
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
      // Sonda explícita del token: distingue cookie mal formada de secreto
      // TOTP obsoleto.
      try {
        final token = await _getAuth().getAccessToken();
        logD('[Canvas] sp_dc token OK (len=${token.length})');
      } on Object catch (e) {
        logD('[Canvas] sp_dc getAccessToken FAILED: ${e.runtimeType}: $e');
      }
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
