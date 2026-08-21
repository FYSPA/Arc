import 'package:flutter/material.dart';

import '../controller/settings_controller.dart';

const double kFABSize = 52.0;
const double kDialogMaxWidth = 428.0;
const double kBottomPaddingMiniplayer = 150.0;
const double kExpandableBoxHeight = 48.0;
const double kQueueBottomRowHeight = 48.0;
const double kHistoryDayHeaderHeight = 40.0;

extension DimensionExtensions on double {
  double get space => this;
  double get spaceX => this * 1.5;
  double get multipliedRadius =>
      this * SettingsController.inst.borderRadiusMultiplier;
}

extension ContextExtensions on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  double calculateDialogHorizontalMargin(double minimum) {
    final screenWidth = width;
    final val = (screenWidth / 1000).clamp(0.0, 1.0);
    double percentage = 0.25 * val * val;
    percentage = percentage.clamp(0.0, 0.25);
    return (screenWidth * percentage).clamp(minimum, double.infinity);
  }

  double get settingsHorizontalMargin {
    if (width < 600) return 0.0;
    return 0.12 * calculateDialogHorizontalMargin(0.0);
  }
}
