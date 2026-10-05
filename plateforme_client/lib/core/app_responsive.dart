import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/providers/device_info_provider.dart';

/// Breakpoints shared by the customer experience on phones, tablets, browsers,
/// desktop monitors and televisions.
class AppResponsive {
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static Size screenSize(BuildContext context) =>
      MediaQuery.of(context).size;

  static bool isMobile(BuildContext context) =>
      screenSize(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = screenSize(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      screenSize(context).width >= desktopBreakpoint;

  /// Hardware detection handles Android TV; the size fallback also makes
  /// browser layouts comfortable on large television screens.
  static bool isTVSize(BuildContext context) {
    try {
      if (Provider.of<DeviceInfoProvider>(context).isTV) {
        return true;
      }
    } catch (_) {
      // Some isolated widgets are rendered without the app providers.
    }

    final size = screenSize(context);
    return size.width >= 1280 && size.shortestSide >= 720;
  }

  static double pagePadding(BuildContext context) {
    if (isTVSize(context)) return 40;
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isTVSize(context)) return 1720;
    if (isDesktop(context)) return 1280;
    return 960;
  }

  static int contentGridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 5,
    int tv = 6,
  }) {
    if (isTVSize(context)) return tv;
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
