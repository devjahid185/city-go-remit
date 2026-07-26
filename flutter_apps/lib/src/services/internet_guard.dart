import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_navigator.dart';

class InternetGuard {
  const InternetGuard._();

  static bool _dialogOpen = false;
  static DateTime? _lastDialogAt;

  static bool get dialogOpen => _dialogOpen;

  static Future<bool> ensureOnline({bool showDialog = true}) async {
    final online = await hasInternet();

    if (!online && showDialog) {
      _showOfflineDialog();
    }

    return online;
  }

  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('cloudflare.com').timeout(
        const Duration(seconds: 3),
      );

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  static void _showOfflineDialog() {
    final context = AppNavigator.context;
    if (context == null || _dialogOpen) return;

    final now = DateTime.now();
    if (_lastDialogAt != null && now.difference(_lastDialogAt!).inSeconds < 3) {
      return;
    }

    _dialogOpen = true;
    _lastDialogAt = now;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.financeLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.financePrimary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.financePrimary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your mobile data or Wi‑Fi connection, then try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.financeMuted,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.financeMuted,
                        side: const BorderSide(color: AppColors.financeLine),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.financePrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _dialogOpen = false);
  }
}
