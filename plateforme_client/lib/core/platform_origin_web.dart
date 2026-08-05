// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String? currentBrowserOrigin() {
  final origin = html.window.location.origin;
  return origin.isEmpty ? null : origin;
}
