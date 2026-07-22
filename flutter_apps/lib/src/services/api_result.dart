class ApiResult {
  const ApiResult({
    required this.ok,
    required this.message,
    this.data = const {},
  });

  final bool ok;
  final String message;
  final Map<String, dynamic> data;
}
