import 'package:web/web.dart' as web;

String? currentBrowserOrigin() {
  final origin = web.window.location.origin;
  return origin.isEmpty ? null : origin;
}
