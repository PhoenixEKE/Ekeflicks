String? validateInternationalPhone(String? value, {bool optional = true}) {
  final phone = (value ?? '').trim();
  if (phone.isEmpty && optional) return null;
  final normalized = phone.replaceAll(RegExp(r'[\s().-]'), '');
  if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(normalized)) {
    return 'Ajoutez l’indicatif du pays, par exemple +2250102030405';
  }
  return null;
}

String normalizeInternationalPhone(String value) {
  return value.trim().replaceAll(RegExp(r'[\s().-]'), '');
}
