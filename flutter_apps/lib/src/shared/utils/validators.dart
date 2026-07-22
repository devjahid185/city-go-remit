String? requiredField(String? value) {
  if (value == null || value.trim().isEmpty) return 'This field is required';
  return null;
}

String? requiredEmail(String? value) {
  final required = requiredField(value);
  if (required != null) return required;
  if (!value!.contains('@')) return 'Enter a valid email';
  return null;
}

String? strongPassword(String? value) {
  return requiredField(value);
}
