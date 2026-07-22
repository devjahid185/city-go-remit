import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/finance/pages/bank_transfer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/bill_payment_page.dart';
import 'package:flutter_apps/src/features/finance/pages/drive_offer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/exchange_page.dart';
import 'package:flutter_apps/src/features/finance/pages/live_chat_page.dart';
import 'package:flutter_apps/src/features/finance/pages/mobile_recharge_page.dart';
import 'package:flutter_apps/src/features/finance/pages/notification_center_page.dart';
import 'package:flutter_apps/src/features/finance/widgets/finance_top_bar.dart';
import 'package:flutter_apps/src/features/finance/widgets/service_tile.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class FinanceHomeTab extends StatefulWidget {
  const FinanceHomeTab({required this.name, required this.onOpenServices, super.key});

  final String name;
  final VoidCallback onOpenServices;

  @override
  State<FinanceHomeTab> createState() => _FinanceHomeTabState();
}

class _FinanceHomeTabState extends State<FinanceHomeTab> {
  final _cardKey = GlobalKey<_CardPreviewState>();

  @override
  void didUpdateWidget(covariant FinanceHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cardKey.currentState?.refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        FinanceTopBar(
          title: AppText.t('app_title'),
          onChatTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LiveChatPage()),
          ),
          onNotificationTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _CardPreview(key: _cardKey, name: widget.name),
        ),
        const _HomeBannerCarousel(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Text(
                AppText.t('payment_services'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onOpenServices,
                child: Text(AppText.t('see_all')),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: .78,
            children: [
              ServiceTile(
                icon: Icons.sync_alt_rounded,
                label: AppText.t('bank_transfer'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BankTransferPage()),
                ),
              ),
              ServiceTile(
                icon: Icons.phone_iphone_rounded,
                label: AppText.t('mobile_recharge'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MobileRechargePage()),
                ),
              ),
              ServiceTile(
                icon: Icons.receipt_long_rounded,
                label: AppText.t('bill_payment'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BillPaymentPage()),
                ),
              ),
              ServiceTile(
                icon: Icons.wifi_tethering_rounded,
                label: AppText.t('drive_offer'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DriveOfferPage()),
                ),
              ),
              ServiceTile(
                icon: Icons.qr_code_scanner_rounded,
                label: AppText.t('tap_pay'),
              ),
              ServiceTile(
                icon: Icons.currency_exchange_rounded,
                label: AppText.t('exchange'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExchangePage()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel();

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  final _api = AuthApi();
  final _controller = PageController(viewportFraction: .92);
  Timer? _autoSlideTimer;
  List<Map<String, dynamic>> _banners = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _api.homeBanners();
    if (!mounted || !result.ok) return;
    setState(() {
      _banners = List<Map<String, dynamic>>.from(result.data['banners'] as List? ?? []);
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_banners.length < 2) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextIndex = (_index + 1) % _banners.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handleTap(Map<String, dynamic> banner) {
    final type = banner['action_type']?.toString() ?? 'none';
    final value = banner['action_value']?.toString() ?? '';
    if (type != 'service') return;

    final Widget? page = switch (value) {
      'mobile_recharge' => const MobileRechargePage(),
      'bill_payment' => const BillPaymentPage(),
      'bank_transfer' => const BankTransferPage(),
      'drive_offer' => const DriveOfferPage(),
      'live_chat' => const LiveChatPage(),
      _ => null,
    };

    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          SizedBox(
            height: 112,
            child: PageView.builder(
              controller: _controller,
              itemCount: _banners.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _HomeBannerCard(
                    banner: banner,
                    onTap: () => _handleTap(banner),
                  ),
                );
              },
            ),
          ),
          if (_banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _banners.length; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _index == index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _index == index
                          ? AppColors.financePrimary
                          : AppColors.financeLine,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeBannerCard extends StatelessWidget {
  const _HomeBannerCard({
    required this.banner,
    required this.onTap,
  });

  final Map<String, dynamic> banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['image_url']?.toString() ?? '';
    final buttonText = banner['button_text']?.toString() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              headers: const {'ngrok-skip-browser-warning': 'true'},
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppColors.ink);
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner['title']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if ((banner['subtitle'] ?? '').toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            banner['subtitle'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .82),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (buttonText.trim().isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPreview extends StatefulWidget {
  const _CardPreview({required this.name, super.key});

  final String name;

  @override
  State<_CardPreview> createState() => _CardPreviewState();
}

class _CardPreviewState extends State<_CardPreview> {
  final _api = AuthApi();
  double _balance = 0;
  bool _showBalance = false;
  bool _balanceLoading = false;
  String _phone = '';
  String _email = '';
  Timer? _hideBalanceTimer;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _hideBalanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final store = const SessionStore();
    final session = await store.load();
    if (!mounted) return;
    setState(() {
      _balance = session.userBalance;
      _phone = session.userPhone;
      _email = session.userEmail;
    });

    if (session.userEmail.trim().isEmpty) return;
    final result = await _api.profile(email: session.userEmail);
    if (!mounted || !result.ok) return;
    final user = result.data['user'] as Map<String, dynamic>? ?? {};
    final latestBalance = double.tryParse(user['balance']?.toString() ?? '') ?? _balance;
    await store.saveProfile(
      userName: user['name']?.toString() ?? session.userName,
      userEmail: user['email']?.toString() ?? session.userEmail,
      userPhone: user['phone']?.toString() ?? '',
      userAddress: user['address']?.toString() ?? session.userAddress,
      userBalance: latestBalance,
    );
    if (!mounted) return;
    setState(() {
      _balance = latestBalance;
      _phone = user['phone']?.toString() ?? _phone;
      _email = user['email']?.toString() ?? _email;
    });
  }

  Future<void> _toggleBalance() async {
    _hideBalanceTimer?.cancel();

    if (_showBalance) {
      setState(() => _showBalance = false);
      return;
    }

    setState(() => _balanceLoading = true);
    await refreshProfile();
    if (!mounted) return;
    setState(() {
      _balanceLoading = false;
      _showBalance = true;
    });

    _hideBalanceTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showBalance = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.financePrimary.withValues(alpha: .22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.financePrimary,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -72,
                  top: -82,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: -52,
                  bottom: -70,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _CardPatternPainter()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: .8,
                                ),
                              ),
                              if (_phone.trim().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  _phone.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .78),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: .18)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD166),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'CGR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: .8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.t('available_balance').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .68),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _BalanceToggle(
                          visible: _showBalance,
                          loading: _balanceLoading,
                          balance: _money(_balance),
                          onTap: _toggleBalance,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .13),
                              border: Border.all(color: Colors.white.withValues(alpha: .12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '••••  ••••  ••••  $_dynamicLastFour',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'VIRTUAL',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .76),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Card',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _money(double amount) {
    final fixed = amount.toStringAsFixed(2);
    return 'BDT $fixed';
  }

  String get _dynamicLastFour {
    final source = _phone.trim().isNotEmpty
        ? _phone
        : _email.trim().isNotEmpty
            ? _email
            : widget.name;
    final digits = source.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);

    var hash = 0;
    for (final unit in source.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return (hash % 10000).toString().padLeft(4, '0');
  }
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;

    for (var offset = -size.height; offset < size.width; offset += 28) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BalanceToggle extends StatelessWidget {
  const _BalanceToggle({
    required this.visible,
    required this.loading,
    required this.balance,
    required this.onTap,
  });

  final bool visible;
  final bool loading;
  final String balance;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading
          ? null
          : () {
              onTap();
            },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Colors.white,
                size: 16,
              ),
            const SizedBox(width: 7),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                loading
                    ? AppText.t('updating_balance')
                    : visible
                        ? balance
                        : AppText.t('tap_to_show_balance'),
                key: ValueKey('$visible-$loading'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: visible ? 18 : 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: visible ? .1 : 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
