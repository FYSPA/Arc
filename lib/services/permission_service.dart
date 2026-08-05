import 'package:flutter/services.dart';

class PermissionService {
  PermissionService._();
  static final inst = PermissionService._();
  static const _channel = MethodChannel('arc_app/permissions');

  Future<bool> check() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> request() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } catch (_) {}
  }
}
