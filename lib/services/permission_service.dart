import 'dart:io';

import 'package:flutter/services.dart';

class PermissionService {
  PermissionService._();
  static final inst = PermissionService._();
  static const _channel = MethodChannel('arc_app/permissions');

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  Future<bool> check() async {
    if (!_isMobile) return false;
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> request() async {
    if (!_isMobile) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> openSettings() async {
    if (!_isMobile) return;
    try {
      await _channel.invokeMethod('openSettings');
    } catch (_) {}
  }
}
