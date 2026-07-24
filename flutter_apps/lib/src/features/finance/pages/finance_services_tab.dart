import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/finance/pages/bank_transfer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/bill_payment_page.dart';
import 'package:flutter_apps/src/features/finance/pages/drive_offer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/exchange_page.dart';
import 'package:flutter_apps/src/features/finance/pages/mobile_recharge_page.dart';
import 'package:flutter_apps/src/features/finance/pages/notification_center_page.dart';
import 'package:flutter_apps/src/features/finance/pages/wallet_withdrawal_page.dart';
import 'package:flutter_apps/src/features/finance/widgets/finance_top_bar.dart';
import 'package:flutter_apps/src/features/finance/widgets/service_tile.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/link_launcher.dart';

class FinanceServicesTab extends StatefulWidget {
  const FinanceServicesTab({super.key});

  @override
  State<FinanceServicesTab> createState() => _FinanceServicesTabState();
}

class _FinanceServicesTabState extends State<FinanceServicesTab> {
  final _api = AuthApi();
  String _youtubeUrl = '';
  String _telegramUrl = '';
  Map<String, dynamic> _serviceSettings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await _api.appSettings();
    if (!mounted || !result.ok) return;
    final settings = result.data['settings'] as Map<String, dynamic>? ?? {};
    setState(() {
      _youtubeUrl = settings['youtube_url']?.toString() ?? '';
      _telegramUrl = settings['telegram_url']?.toString() ?? '';
      _serviceSettings = settings['services'] as Map<String, dynamic>? ?? {};
    });
  }

  Future<void> _openLink(String url, String label) async {
    final opened = await const LinkLauncher().open(url);
    if (opened || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.t('social_link_unavailable').replaceFirst(':name', label))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        key: 'mobile_recharge',
        icon: Icons.phone_iphone_rounded,
        label: AppText.t('mobile_recharge'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MobileRechargePage()),
        ),
      ),
      _ServiceItem(
        key: 'drive_offer',
        icon: Icons.wifi_tethering_rounded,
        label: AppText.t('drive_offer'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DriveOfferPage()),
        ),
      ),
      _ServiceItem(
        key: 'bill_payment',
        icon: Icons.receipt_long_rounded,
        label: AppText.t('bill_payment'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BillPaymentPage()),
        ),
      ),
      _ServiceItem(
        key: 'bank_transfer',
        icon: Icons.account_balance_rounded,
        label: AppText.t('bank_transfer'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BankTransferPage()),
        ),
      ),
      _ServiceItem(
        key: 'wallet_withdrawal',
        icon: Icons.account_balance_wallet_rounded,
        label: AppText.t('wallet_withdrawal'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WalletWithdrawalPage()),
        ),
      ),
      _ServiceItem(
        key: 'exchange',
        icon: Icons.currency_exchange_rounded,
        label: AppText.t('exchange'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExchangePage()),
        ),
      ),
      _ServiceItem(
        key: 'youtube',
        icon: Icons.play_circle_fill_rounded,
        label: AppText.t('youtube'),
        onTap: () => _openLink(_youtubeUrl, 'YouTube'),
      ),
      _ServiceItem(
        key: 'telegram',
        icon: Icons.telegram_rounded,
        label: AppText.t('telegram'),
        onTap: () => _openLink(_telegramUrl, 'Telegram'),
      ),
    ].where((service) => _serviceEnabled(service.key)).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.financePrimary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: SafeArea(
            bottom: false,
            child: FinanceTopBar(
              title: AppText.t('services'),
              showMenu: true,
              onNotificationTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
          child: Text(
            AppText.t('all_services'),
            style: const TextStyle(
              color: AppColors.financeMuted,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: .76,
            children: [
              for (var index = 0; index < services.length; index++)
                ServiceTile(
                  icon: services[index].icon,
                  label: services[index].label,
                  onTap: services[index].onTap,
                ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  bool _serviceEnabled(String key) {
    final item = _serviceSettings[key];
    if (item is Map<String, dynamic>) {
      return item['enabled'] != false;
    }
    return true;
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String key;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
