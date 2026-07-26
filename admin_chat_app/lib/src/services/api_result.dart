class ApiResult<T> {
  const ApiResult({
    required this.ok,
    required this.message,
    this.data,
  });

  final bool ok;
  final String message;
  final T? data;
}
