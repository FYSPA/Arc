import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constans.dart';
import '../core/enums.dart';

enum PerformanceMode { off, powerSaving, limit80 }

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final inst = SettingsController._();

  late SharedPreferences _prefs;

  bool _isOnboarded = false;
  bool get isOnboarded => _isOnboarded;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  String _languageCode = 'es';
  String get languageCode => _languageCode;

  Color _mainColor = kMainColorLight;
  Color get mainColor => _mainColor;

  bool _includeVideos = false;
  bool get includeVideos => _includeVideos;

  bool _useMediaStore = false;
  bool get useMediaStore => _useMediaStore;

  List<String> _foldersToScan = [];
  List<String> get foldersToScan => List.unmodifiable(_foldersToScan);

  final List<String> _foldersToExclude = [];
  List<String> get foldersToExclude => List.unmodifiable(_foldersToExclude);

  PerformanceMode _performanceMode = PerformanceMode.off;
  PerformanceMode get performanceMode => _performanceMode;

  List<String> _libraryTabs = [
    'Songs',
    'Artists',
    'Albums',
    'Folders',
    'Genres',
  ];
  List<String> get libraryTabs => List.unmodifiable(_libraryTabs);

  int _artworkCacheSize = 300;
  int get artworkCacheSize => _artworkCacheSize;

  String _fabType = 'search';
  String get fabType => _fabType;

  String _defaultLibraryTab = 'Songs';
  String get defaultLibraryTab => _defaultLibraryTab;

  double _borderRadiusMultiplier = 1.0;
  double get borderRadiusMultiplier => _borderRadiusMultiplier;

  bool _hasStoragePermission = false;
  bool get hasStoragePermission => _hasStoragePermission;

  bool _useAmoledBlack = false;
  bool get useAmoledBlack => _useAmoledBlack;

  bool _enableAmoledGlow = true;
  bool get enableAmoledGlow => _enableAmoledGlow;

  Set<GlowPosition> _amoledGlowPositions = {GlowPosition.topRight};
  Set<GlowPosition> get amoledGlowPositions =>
      Set.unmodifiable(_amoledGlowPositions);

  double _amoledGlowIntensity = 0.5;
  double get amoledGlowIntensity => _amoledGlowIntensity;

  // ──────────────────── API Keys (ArcCanvasConfig) ────────────────────

  String? _spotifyClientId;
  String? get spotifyClientId => _spotifyClientId;

  String? _spotifyClientSecret;
  String? get spotifyClientSecret => _spotifyClientSecret;

  String? _spotifySpDcCookie;
  String? get spotifySpDcCookie => _spotifySpDcCookie;

  String? _geniusAccessToken;
  String? get geniusAccessToken => _geniusAccessToken;

  String? _musixmatchApiKey;
  String? get musixmatchApiKey => _musixmatchApiKey;

  String? _m8tecBaseUrl;
  String? get m8tecBaseUrl => _m8tecBaseUrl;

  String _appleMusicStorefront = 'us';
  String get appleMusicStorefront => _appleMusicStorefront;

  String? _appleMusicAmpToken;
  String? get appleMusicAmpToken => _appleMusicAmpToken;

  String? _musiclinkApiKey;
  String? get musiclinkApiKey => _musiclinkApiKey;

  // ──────────────────── Load ────────────────────

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    _isOnboarded = _prefs.getBool('is_onboarded') ?? false;

    final themeIndex = _prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    _languageCode = _prefs.getString('language_code') ?? 'es';

    final colorValue = _prefs.getInt('main_color');
    _mainColor = colorValue != null ? Color(colorValue) : kMainColorLight;

    _includeVideos = _prefs.getBool('include_videos') ?? false;

    _useMediaStore = _prefs.getBool('use_media_store') ?? false;

    _foldersToScan = _prefs.getStringList('folders_to_scan') ?? [];

    _foldersToExclude.clear();
    _foldersToExclude.addAll(_prefs.getStringList('folders_to_exclude') ?? []);

    final perfIndex = _prefs.getInt('performance_mode') ?? 0;
    _performanceMode = PerformanceMode.values[perfIndex];

    _libraryTabs =
        _prefs.getStringList('library_tabs') ??
        ['Songs', 'Artists', 'Albums', 'Folders', 'Genres'];

    _artworkCacheSize = _prefs.getInt('artwork_cache_size') ?? 300;

    _fabType = _prefs.getString('fab_type') ?? 'search';

    _defaultLibraryTab = _prefs.getString('default_library_tab') ?? 'Songs';

    _borderRadiusMultiplier =
        _prefs.getDouble('border_radius_multiplier') ?? 1.0;

    _useAmoledBlack = _prefs.getBool('use_amoled_black') ?? false;

    _enableAmoledGlow = _prefs.getBool('enable_amoled_glow') ?? true;

    final glowPosStrings = _prefs.getStringList('amoled_glow_positions');
    if (glowPosStrings != null) {
      _amoledGlowPositions = glowPosStrings
          .map((s) => GlowPosition.values.firstWhere((e) => e.name == s))
          .toSet();
    }

    _amoledGlowIntensity = _prefs.getDouble('amoled_glow_intensity') ?? 0.5;

    _spotifyClientId = _prefs.getString('spotify_client_id');
    _spotifyClientSecret = _prefs.getString('spotify_client_secret');
    _spotifySpDcCookie = _prefs.getString('spotify_sp_dc_cookie');
    _geniusAccessToken = _prefs.getString('genius_access_token');
    _musixmatchApiKey = _prefs.getString('musixmatch_api_key');
    _m8tecBaseUrl = _prefs.getString('m8tec_base_url');
    _appleMusicStorefront = _prefs.getString('apple_music_storefront') ?? 'us';
    _appleMusicAmpToken = _prefs.getString('apple_music_amp_token');
    _musiclinkApiKey = _prefs.getString('musiclink_api_key');

    notifyListeners();
  }

  // ──────────────────── Save helpers ────────────────────

  void _save() {
    _prefs.setBool('is_onboarded', _isOnboarded);
    _prefs.setInt('theme_mode', _themeMode.index);
    _prefs.setString('language_code', _languageCode);
    _prefs.setInt('main_color', _mainColor.toARGB32());
    _prefs.setBool('include_videos', _includeVideos);
    _prefs.setBool('use_media_store', _useMediaStore);
    _prefs.setStringList('folders_to_scan', _foldersToScan);
    _prefs.setStringList('folders_to_exclude', _foldersToExclude);
    _prefs.setInt('performance_mode', _performanceMode.index);
    _prefs.setStringList('library_tabs', _libraryTabs);
    _prefs.setInt('artwork_cache_size', _artworkCacheSize);
    _prefs.setString('fab_type', _fabType);
    _prefs.setString('default_library_tab', _defaultLibraryTab);
    _prefs.setDouble('border_radius_multiplier', _borderRadiusMultiplier);
    _prefs.setBool('use_amoled_black', _useAmoledBlack);
    _prefs.setBool('enable_amoled_glow', _enableAmoledGlow);
    _prefs.setStringList(
      'amoled_glow_positions',
      _amoledGlowPositions.map((e) => e.name).toList(),
    );
    _prefs.setDouble('amoled_glow_intensity', _amoledGlowIntensity);
    _prefs.setString('spotify_client_id', _spotifyClientId ?? '');
    _prefs.setString('spotify_client_secret', _spotifyClientSecret ?? '');
    _prefs.setString('spotify_sp_dc_cookie', _spotifySpDcCookie ?? '');
    _prefs.setString('genius_access_token', _geniusAccessToken ?? '');
    _prefs.setString('musixmatch_api_key', _musixmatchApiKey ?? '');
    _prefs.setString('m8tec_base_url', _m8tecBaseUrl ?? '');
    _prefs.setString('apple_music_storefront', _appleMusicStorefront);
    _prefs.setString('apple_music_amp_token', _appleMusicAmpToken ?? '');
    _prefs.setString('musiclink_api_key', _musiclinkApiKey ?? '');
  }

  // ──────────────────── Setters ────────────────────

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _save();
  }

  void setLanguageCode(String code) {
    _languageCode = code;
    notifyListeners();
    _save();
  }

  void setMainColor(Color color) {
    _mainColor = color;
    notifyListeners();
    _save();
  }

  void setIncludeVideos(bool value) {
    _includeVideos = value;
    notifyListeners();
    _save();
  }

  void setUseMediaStore(bool value) {
    _useMediaStore = value;
    notifyListeners();
    _save();
  }

  void addFolderToScan(String path) {
    if (!_foldersToScan.contains(path)) {
      _foldersToScan.add(path);
      notifyListeners();
      _save();
    }
  }

  void removeFolderToScan(String path) {
    _foldersToScan.remove(path);
    notifyListeners();
    _save();
  }

  void setFoldersToScan(List<String> paths) {
    _foldersToScan = List.from(paths);
    notifyListeners();
    _save();
  }

  void addFolderToExclude(String path) {
    if (!_foldersToExclude.contains(path)) {
      _foldersToExclude.add(path);
      notifyListeners();
      _save();
    }
  }

  void removeFolderToExclude(String path) {
    _foldersToExclude.remove(path);
    notifyListeners();
    _save();
  }

  void setPerformanceMode(PerformanceMode mode) {
    _performanceMode = mode;
    notifyListeners();
    _save();
  }

  void setLibraryTabs(List<String> tabs) {
    _libraryTabs = List.unmodifiable(tabs);
    notifyListeners();
    _save();
  }

  void setArtworkCacheSize(int size) {
    _artworkCacheSize = size;
    notifyListeners();
    _save();
  }

  void setFabType(String type) {
    _fabType = type;
    notifyListeners();
    _save();
  }

  void setDefaultLibraryTab(String tab) {
    _defaultLibraryTab = tab;
    notifyListeners();
    _save();
  }

  void setBorderRadiusMultiplier(double value) {
    _borderRadiusMultiplier = value;
    notifyListeners();
    _save();
  }

  void setStoragePermission(bool granted) {
    _hasStoragePermission = granted;
    notifyListeners();
  }

  void setUseAmoledBlack(bool value) {
    _useAmoledBlack = value;
    notifyListeners();
    _save();
  }

  void setEnableAmoledGlow(bool value) {
    _enableAmoledGlow = value;
    notifyListeners();
    _save();
  }

  void toggleAmoledGlowPosition(GlowPosition position) {
    if (_amoledGlowPositions.contains(position)) {
      _amoledGlowPositions.remove(position);
    } else if (_amoledGlowPositions.length < 2) {
      _amoledGlowPositions.add(position);
    }
    notifyListeners();
    _save();
  }

  void setAmoledGlowPositions(Set<GlowPosition> positions) {
    _amoledGlowPositions = Set<GlowPosition>.from(positions);
    notifyListeners();
    _save();
  }

  void setAmoledGlowIntensity(double value) {
    _amoledGlowIntensity = value;
    notifyListeners();
    _save();
  }

  // ──────────────────── API Key Setters ────────────────────

  void setSpotifyClientId(String? value) {
    _spotifyClientId = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setSpotifyClientSecret(String? value) {
    _spotifyClientSecret = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setSpotifySpDcCookie(String? value) {
    _spotifySpDcCookie = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setGeniusAccessToken(String? value) {
    _geniusAccessToken = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setMusixmatchApiKey(String? value) {
    _musixmatchApiKey = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setM8tecBaseUrl(String? value) {
    _m8tecBaseUrl = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setAppleMusicStorefront(String value) {
    _appleMusicStorefront = value;
    notifyListeners();
    _save();
  }

  void setAppleMusicAmpToken(String? value) {
    _appleMusicAmpToken = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void setMusiclinkApiKey(String? value) {
    _musiclinkApiKey = value?.isEmpty == true ? null : value;
    notifyListeners();
    _save();
  }

  void completeOnboarding() {
    _isOnboarded = true;
    notifyListeners();
    _save();
  }
}
