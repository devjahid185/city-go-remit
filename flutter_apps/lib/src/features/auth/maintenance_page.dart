import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/auth/splash_page.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

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
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.financePrimary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.financePrimary.withValues(alpha: .12),
                  ),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: AppColors.financePrimary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppText.t('maintenance_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppText.t('maintenance_body'),
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
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SplashPage()),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppText.t('try_again')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.financePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'City Go Remit',
                style: TextStyle(
                  color: AppColors.financeMuted.withValues(alpha: .75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
