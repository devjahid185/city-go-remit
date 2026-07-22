import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/intro_onboarding_page.dart';
import 'package:flutter_apps/src/features/auth/login_page.dart';
import 'package:flutter_apps/src/features/home/home_page.dart';
import 'package:flutter_apps/src/services/location_service.dart';
import 'package:flutter_apps/src/services/push_notification_service.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = await const SessionStore().load();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (session.loggedIn) {
      await PushNotificationService.instance.registerSavedUserToken();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(name: session.userName)),
      );
      return;
    }

    final location = await const LocationService().detect();
    if (!mounted) return;

    if (session.onboardingSeen) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage(location: location)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => IntroOnboardingPage(location: location)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _SplashOrb(
              size: 190,
              color: AppColors.financePrimaryStrong.withValues(alpha: .12),
            ),
          ),
          Positioned(
            bottom: -95,
            left: -80,
            child: _SplashOrb(
              size: 220,
              color: AppColors.financePrimary.withValues(alpha: .10),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.financePrimary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.financePrimary.withValues(alpha: .22),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'City Go Remit',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.financePrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Preparing your secure finance workspace...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 112,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            color: AppColors.financePrimary,
                            backgroundColor: AppColors.financeLine,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Bank-grade encrypted security',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashOrb extends StatelessWidget {
  const _SplashOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
