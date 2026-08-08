/// Extracts the first human-readable message from common REST error payloads.
///
/// Django REST Framework can return a string, a list of strings, or nested
/// maps such as `{errors: {phone: [message]}}`. Never cast a field value
/// directly to [String], especially on Flutter web where JSON arrays retain
/// their JavaScript array runtime type.
String? firstApiErrorMessage(dynamic value) {
  if (value is String) {
    final message = value.trim();
    return message.isEmpty ? null : message;
  }

  if (value is Iterable) {
    for (final item in value) {
      final message = firstApiErrorMessage(item);
      if (message != null) return message;
    }
    return null;
  }

  if (value is Map) {
    // Prefer the API's normalized errors envelope and detail before walking
    // through field-specific errors in insertion order.
    for (final key in const ['errors', 'detail', 'message']) {
      if (value.containsKey(key)) {
        final message = firstApiErrorMessage(value[key]);
        if (message != null) return message;
      }
    }
    for (final item in value.values) {
      final message = firstApiErrorMessage(item);
      if (message != null) return message;
    }
  }

  return null;
}
