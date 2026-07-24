import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/finance/pages/add_money_page.dart';
import 'package:flutter_apps/src/features/finance/pages/bank_transfer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/bill_payment_page.dart';
import 'package:flutter_apps/src/features/finance/pages/drive_offer_page.dart';
import 'package:flutter_apps/src/features/finance/pages/live_chat_page.dart';
import 'package:flutter_apps/src/features/finance/pages/mobile_recharge_page.dart';
import 'package:flutter_apps/src/features/finance/pages/notification_center_page.dart';
import 'package:flutter_apps/src/features/finance/widgets/finance_top_bar.dart';
import 'package:flutter_apps/src/features/finance/widgets/service_tile.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/prayer_schedule_service.dart';
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
  final _api = AuthApi();
  Map<String, dynamic> _serviceSettings = {};

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  @override
  void didUpdateWidget(covariant FinanceHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cardKey.currentState?.refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final services = [
      _HomeServiceItem(
        key: 'bank_transfer',
        icon: Icons.sync_alt_rounded,
        label: AppText.t('bank_transfer'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BankTransferPage()),
        ),
      ),
      _HomeServiceItem(
        key: 'mobile_recharge',
        icon: Icons.phone_iphone_rounded,
        label: AppText.t('mobile_recharge'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MobileRechargePage()),
        ),
      ),
      _HomeServiceItem(
        key: 'bill_payment',
        icon: Icons.receipt_long_rounded,
        label: AppText.t('bill_payment'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BillPaymentPage()),
        ),
      ),
      _HomeServiceItem(
        key: 'drive_offer',
        icon: Icons.wifi_tethering_rounded,
        label: AppText.t('drive_offer'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DriveOfferPage()),
        ),
      ),
    ].where((service) => _serviceEnabled(service.key)).toList();

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
          child: _CardPreview(
            key: _cardKey,
            name: widget.name,
            addMoneyEnabled: _serviceEnabled('add_money'),
          ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  for (final service in services)
                    SizedBox(
                      width: itemWidth,
                      child: ServiceTile(
                        icon: service.icon,
                        label: service.label,
                        onTap: service.onTap,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _PrayerScheduleSection(),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Future<void> _loadAppSettings() async {
    final result = await _api.appSettings();
    if (!mounted || !result.ok) return;
    final settings = result.data['settings'] as Map<String, dynamic>? ?? {};
    setState(() {
      _serviceSettings = settings['services'] as Map<String, dynamic>? ?? {};
    });
  }

  bool _serviceEnabled(String key) {
    final item = _serviceSettings[key];
    if (item is Map<String, dynamic>) {
      return item['enabled'] != false;
    }
    return true;
  }
}

class _HomeServiceItem {
  const _HomeServiceItem({
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

class _PrayerScheduleSection extends StatefulWidget {
  const _PrayerScheduleSection();

  @override
  State<_PrayerScheduleSection> createState() => _PrayerScheduleSectionState();
}

class _PrayerScheduleSectionState extends State<_PrayerScheduleSection> {
  final _service = const PrayerScheduleService();
  PrayerSchedule? _schedule;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final schedule = await _service.loadToday();
    if (!mounted) return;
    setState(() {
      _schedule = schedule;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF073D35),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF073D35).withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PrayerPatternPainter())),
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(170, 116),
                painter: _MadinahSilhouettePainter(),
              ),
            ),
            Positioned(
              right: -48,
              top: -58,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .12),
                          ),
                        ),
                        child: const Icon(
                          Icons.nights_stay_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppText.t('prayer_schedule'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _locationText(schedule),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .70),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (schedule?.dateLabel.isNotEmpty ?? false)
                        Text(
                          schedule!.dateLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .66),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const _PrayerLoadingGrid()
                  else if (schedule == null)
                    _PrayerUnavailable(onRetry: _load)
                  else
                    _PrayerTimeGrid(schedule: schedule),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _locationText(PrayerSchedule? schedule) {
    if (schedule == null) return AppText.t('detecting_location');
    final location = schedule.location;
    return '${location.flag} ${location.addressHint}';
  }
}

class _PrayerTimeGrid extends StatelessWidget {
  const _PrayerTimeGrid({required this.schedule});

  final PrayerSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final activeIndex = schedule.activePrayerIndex;

    return GridView.builder(
      itemCount: schedule.prayers.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final prayer = schedule.prayers[index];
        final active = index == activeIndex;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: .95)
                : Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: .12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppText.t('prayer_${prayer.name.toLowerCase()}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? const Color(0xFF073D35) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                prayer.time,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF073D35)
                      : Colors.white.withValues(alpha: .78),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerLoadingGrid extends StatelessWidget {
  const _PrayerLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.65,
      children: [
        for (var index = 0; index < 6; index++)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
            ),
          ),
      ],
    );
  }
}

class _PrayerUnavailable extends StatelessWidget {
  const _PrayerUnavailable({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppText.t('prayer_unavailable'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .76),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(AppText.t('retry')),
        ),
      ],
    );
  }
}

class _PrayerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: .055);

    for (var offset = -size.height; offset < size.width; offset += 34) {
      canvas.drawLine(
        Offset(offset, size.height),
        Offset(offset + size.height, 0),
        linePaint,
      );
    }

    for (var x = 22.0; x < size.width; x += 44) {
      for (var y = 22.0; y < size.height; y += 44) {
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MadinahSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .14);
    final softPaint = Paint()..color = Colors.white.withValues(alpha: .07);

    final baseline = size.height;
    final domePath = Path()
      ..moveTo(size.width * .20, baseline)
      ..lineTo(size.width * .20, size.height * .58)
      ..quadraticBezierTo(
        size.width * .38,
        size.height * .18,
        size.width * .56,
        size.height * .58,
      )
      ..lineTo(size.width * .56, baseline)
      ..close();
    canvas.drawPath(domePath, softPaint);

    canvas.drawCircle(
      Offset(size.width * .38, size.height * .34),
      3.4,
      paint,
    );

    final minaretX = size.width * .72;
    final minaretPath = Path()
      ..moveTo(minaretX - 11, baseline)
      ..lineTo(minaretX - 9, size.height * .25)
      ..lineTo(minaretX + 9, size.height * .25)
      ..lineTo(minaretX + 11, baseline)
      ..close();
    canvas.drawPath(minaretPath, paint);

    final crownPath = Path()
      ..moveTo(minaretX - 15, size.height * .28)
      ..lineTo(minaretX, size.height * .08)
      ..lineTo(minaretX + 15, size.height * .28)
      ..close();
    canvas.drawPath(crownPath, softPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(minaretX - 17, size.height * .36, 34, 8),
        const Radius.circular(5),
      ),
      softPaint,
    );

    final moonPaint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawArc(
      Rect.fromLTWH(size.width * .05, size.height * .05, 24, 24),
      -1.2,
      4.0,
      false,
      moonPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  const _CardPreview({required this.name, required this.addMoneyEnabled, super.key});

  final String name;
  final bool addMoneyEnabled;

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
    return SizedBox(
      height: 146,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.financePrimary.withValues(alpha: .22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(18),
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
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 112),
                      child: Column(
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
                    ),
                  ],
                ),
                if (widget.addMoneyEnabled)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _AddMoneyButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddMoneyPage()),
                        ),
                      ),
                    ),
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
}

class _AddMoneyButton extends StatelessWidget {
  const _AddMoneyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              color: AppColors.financePrimary,
              size: 17,
            ),
            const SizedBox(width: 5),
            Text(
              AppText.t('add_money'),
              style: const TextStyle(
                color: AppColors.financePrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
