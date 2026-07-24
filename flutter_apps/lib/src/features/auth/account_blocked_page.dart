import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/auth/login_page.dart';
import 'package:flutter_apps/src/services/location_service.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class AccountBlockedPage extends StatelessWidget {
  const AccountBlockedPage({super.key});

  Future<void> _goToLogin(BuildContext context) async {
    await const SessionStore().signOut();
    final location = await const LocationService().detect();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage(location: location)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.red.withValues(alpha: .12)),
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: AppColors.financePrimary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppText.t('account_blocked_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppText.t('account_blocked_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.financeMuted,
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _goToLogin(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.financePrimary,
                    side: const BorderSide(color: AppColors.financePrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppText.t('back_to_login')),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
