import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/finance/pages/bank_transfer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/bill_payment_page.dart';
import 'package:flutter_apps/src/features/finance/pages/drive_offer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/exchange_page.dart';
import 'package:flutter_apps/src/features/finance/pages/mobile_recharge_page.dart';
import 'package:flutter_apps/src/features/finance/pages/notification_center_page.dart';
import 'package:flutter_apps/src/features/finance/widgets/finance_top_bar.dart';
import 'package:flutter_apps/src/features/finance/widgets/service_tile.dart';

class FinanceServicesTab extends StatelessWidget {
  const FinanceServicesTab({super.key});

  static const services = [
    (Icons.phone_iphone_rounded, 'Mobile\nRecharge'),
    (Icons.wifi_tethering_rounded, 'Drive\nOffer'),
    (Icons.receipt_long_rounded, 'Bill\nPayment'),
    (Icons.account_balance_rounded, 'Bank\nTransfer'),
    (Icons.savings_rounded, 'Savings'),
    (Icons.currency_exchange_rounded, 'Exchange'),
  ];

  @override
  Widget build(BuildContext context) {
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
              title: 'Services',
              showMenu: true,
              onNotificationTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 26, 20, 14),
          child: Text(
            'ALL SERVICES',
            style: TextStyle(
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
                  icon: services[index].$1,
                  label: services[index].$2,
                  onTap: index == 0
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MobileRechargePage()),
                          )
                      : index == 1
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DriveOfferPage()),
                              )
                          : index == 2
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BillPaymentPage()),
                              )
                          : index == 3
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const BankTransferPage()),
                                  )
                              : index == 5
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const ExchangePage()),
                                      )
                                  : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}
