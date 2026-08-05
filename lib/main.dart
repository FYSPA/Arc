import 'package:flutter/material.dart';

import 'controller/settings_controller.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsController.inst.load();
  runApp(const ArcApp());
}
