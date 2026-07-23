import 'package:flutter/material.dart';
import 'package:flutter_apps/src/features/auth/login_page.dart';
import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/info_card.dart';

class CongratulationsPage extends StatelessWidget {
  const CongratulationsPage({required this.name, super.key});

  final String name;

  // Premium Fintech Colors (Matching previous screens)
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _primaryColor = Color(0xFF00503A);
  static const Color _textColor = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              // Card container to give a modern, structured look
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Professional Success Indicator (Instead of Emoji)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3EF), // Very light shade of primary
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded, // Trust/Security focused icon
                          color: _primaryColor,
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Congratulations!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      'Your account has been created successfully, $name.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // User's InfoCard widget for next steps
                    const InfoCard(
                      icon: Icons.shield_rounded, // Emphasizing security
                      title: 'Account Ready',
                      body: 'You can now sign in securely using your credentials.',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    AppButton(
                      label: 'Continue to Login',
                      icon: Icons.arrow_forward_rounded, // Modern directional icon
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                LoginPage(location: GeoLocation.fallback()),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
