import 'package:flutter/foundation.dart';

class NavigatorController extends ChangeNotifier {
  NavigatorController._();
  static final inst = NavigatorController._();

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  void navigateTo(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }
}
