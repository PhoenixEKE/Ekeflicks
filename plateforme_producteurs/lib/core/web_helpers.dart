import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void canonicalizeProducerPortalUrl() {
  final location = web.window.location;
  final hash = location.hash;

  if (location.pathname != '/' && hash.startsWith('#/')) {
    web.window.history.replaceState(null, '', '/$hash');
  }
}

void openPdfBytes(List<int> bytes) {
  final uint8List = Uint8List.fromList(bytes);

  final blob = web.Blob(
    <web.BlobPart>[uint8List.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  final url = web.URL.createObjectURL(blob);

  web.window.open(url, '_blank');

  Future<void>.delayed(const Duration(seconds: 30), () {
    web.URL.revokeObjectURL(url);
  });
}

void downloadPdfBytes(List<int> bytes, String filename) {
  final uint8List = Uint8List.fromList(bytes);

  final blob = web.Blob(
    <web.BlobPart>[uint8List.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;

  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';

  web.document.body?.append(anchor);

  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
