import 'package:flutter/material.dart';
import 'package:flutter_apps/src/services/internet_guard.dart';

void showAppMessage(BuildContext context, String message) {
  if (InternetGuard.dialogOpen && message.toLowerCase().contains('internet')) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(safeAppMessageText(message))),
          ],
        ),
      ),
    );
}

String safeAppMessageText(String message) {
  final cleaned = message
      .replaceAll(RegExp(r'https?:\/\/\S+', caseSensitive: false), 'the server')
      .replaceAll(RegExp(r'\b(?:[a-z0-9-]+\.)+[a-z]{2,}(?:\/\S*)?', caseSensitive: false), 'the server')
      .replaceAll(RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?(?:\/\S*)?'), 'the server')
      .replaceAll(RegExp(r'\bAPI URL\b', caseSensitive: false), 'server connection')
      .replaceAll(RegExp(r'\bbase URL\b', caseSensitive: false), 'server connection')
      .trim();

  return cleaned.isEmpty ? 'Something went wrong. Please try again.' : cleaned;
}
