import 'package:flutter/material.dart';

class AppResponsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1000;

  static bool isTVSize(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide > 720;
}
