String safeMessageText(String message) {
  final cleaned = message
      .replaceAll(RegExp(r'https?:\/\/\S+', caseSensitive: false), 'the server')
      .replaceAll(RegExp(r'\b(?:[a-z0-9-]+\.)+[a-z]{2,}(?:\/\S*)?', caseSensitive: false), 'the server')
      .replaceAll(RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?(?:\/\S*)?'), 'the server')
      .replaceAll(RegExp(r'\bAPI URL\b', caseSensitive: false), 'server connection')
      .replaceAll(RegExp(r'\bbase URL\b', caseSensitive: false), 'server connection')
      .trim();

  return cleaned.isEmpty ? 'Something went wrong. Please try again.' : cleaned;
}
