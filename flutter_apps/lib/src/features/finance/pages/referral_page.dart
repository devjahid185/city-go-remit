import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSession>(
      future: const SessionStore().load(),
      builder: (context, snapshot) {
        final session = snapshot.data;
        final code = session?.referralCode ?? '';
        final bonus = (session?.referralBonusEarned ?? 0).toStringAsFixed(2);

        return Scaffold(
          backgroundColor: AppColors.financeBackground,
          appBar: AppBar(
            title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.w500)),
            backgroundColor: AppColors.financeBackground,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.financeLine),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.group_add_rounded, color: AppColors.financePrimary, size: 42),
                    const SizedBox(height: 14),
                    const Text('Invite friends to City Go Remit', style: TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text('Share your code. When your friend creates an account, referral rewards will be added automatically if admin keeps the campaign active.', style: TextStyle(color: AppColors.financeMuted, height: 1.45)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.financeBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.financeLine),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Referral Code', style: TextStyle(color: AppColors.financeMuted)),
                          const SizedBox(height: 8),
                          Text(code.isEmpty ? 'Not available yet' : code, style: const TextStyle(color: AppColors.ink, fontSize: 26, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: code.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: code));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
                              }
                            },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Invite Code'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.financePrimary, minimumSize: const Size.fromHeight(50)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.financeLine),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_rounded, color: Color(0xFF15803D)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Total referral bonus earned', style: TextStyle(color: AppColors.financeMuted))),
                    Text('BDT $bonus', style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
