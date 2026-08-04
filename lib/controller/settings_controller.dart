import 'package:flutter/material.dart';

import '../core/constans.dart';

enum PerformanceMode { off, powerSaving, limit80 }

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final inst = SettingsController._();

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

  List<String> _foldersToExclude = [];
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

  bool _isOnboarded = false;
  bool get isOnboarded => _isOnboarded;

  bool _hasStoragePermission = false;
  bool get hasStoragePermission => _hasStoragePermission;

  bool _useAmoledBlack = false;
  bool get useAmoledBlack => _useAmoledBlack;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    _languageCode = code;
    notifyListeners();
  }

  void setMainColor(Color color) {
    _mainColor = color;
    notifyListeners();
  }

  void setIncludeVideos(bool value) {
    _includeVideos = value;
    notifyListeners();
  }

  void setUseMediaStore(bool value) {
    _useMediaStore = value;
    notifyListeners();
  }

  void addFolderToScan(String path) {
    if (!_foldersToScan.contains(path)) {
      _foldersToScan.add(path);
      notifyListeners();
    }
  }

  void removeFolderToScan(String path) {
    _foldersToScan.remove(path);
    notifyListeners();
  }

  void addFolderToExclude(String path) {
    if (!_foldersToExclude.contains(path)) {
      _foldersToExclude.add(path);
      notifyListeners();
    }
  }

  void removeFolderToExclude(String path) {
    _foldersToExclude.remove(path);
    notifyListeners();
  }

  void setPerformanceMode(PerformanceMode mode) {
    _performanceMode = mode;
    notifyListeners();
  }

  void setLibraryTabs(List<String> tabs) {
    _libraryTabs = List.unmodifiable(tabs);
    notifyListeners();
  }

  void setArtworkCacheSize(int size) {
    _artworkCacheSize = size;
    notifyListeners();
  }

  void setFabType(String type) {
    _fabType = type;
    notifyListeners();
  }

  void setDefaultLibraryTab(String tab) {
    _defaultLibraryTab = tab;
    notifyListeners();
  }

  void setBorderRadiusMultiplier(double value) {
    _borderRadiusMultiplier = value;
    notifyListeners();
  }

  void setStoragePermission(bool granted) {
    _hasStoragePermission = granted;
    notifyListeners();
  }

  void setUseAmoledBlack(bool value) {
    _useAmoledBlack = value;
    notifyListeners();
  }

  void completeOnboarding() {
    _isOnboarded = true;
    notifyListeners();
  }
}
