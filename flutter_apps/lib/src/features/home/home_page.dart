import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/account_blocked_page.dart';
import 'package:flutter_apps/src/features/finance/pages/finance_history_tab.dart';
import 'package:flutter_apps/src/features/finance/pages/finance_home_tab.dart';
import 'package:flutter_apps/src/features/finance/pages/finance_services_tab.dart';
import 'package:flutter_apps/src/features/finance/pages/finance_settings_tab.dart';
import 'package:flutter_apps/src/features/finance/widgets/finance_bottom_nav.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.name, super.key});

  final String name;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _api = AuthApi();
  int _currentIndex = 0;
  late final PageController _pageController;
  late List<Widget> _pages;
  OverlayEntry? _swipeHintEntry;
  Timer? _accessCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _pages = _buildPages();
    _verifyAccountAccess();
    _accessCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _verifyAccountAccess(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSwipeHintOnce());
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _pages = _buildPages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accessCheckTimer?.cancel();
    _removeSwipeHint();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyAccountAccess();
    }
  }

  Future<void> _showSwipeHintOnce() async {
    final store = const SessionStore();
    final session = await store.load();
    if (!mounted || session.homeSwipeHintSeen) return;

    await store.markHomeSwipeHintSeen();
    if (!mounted) return;
    _swipeHintEntry = OverlayEntry(
      builder: (context) => _SwipeCoachmark(onClose: _removeSwipeHint),
    );
    Overlay.of(context).insert(_swipeHintEntry!);
  }

  void _removeSwipeHint() {
    _swipeHintEntry?.remove();
    _swipeHintEntry = null;
  }

  void _changePage(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _verifyAccountAccess() async {
    final store = const SessionStore();
    final session = await store.load();
    if (!mounted || !session.loggedIn || session.userEmail.trim().isEmpty) return;

    final result = await _api.profile(email: session.userEmail);
    if (!mounted || result.ok || result.data['account_banned'] != true) return;

    await store.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccountBlockedPage()),
      (_) => false,
    );
  }

  List<Widget> _buildPages() {
    return [
      _KeepAlivePage(
        child: FinanceHomeTab(
          name: widget.name,
          onOpenServices: () => _changePage(1),
        ),
      ),
      const _KeepAlivePage(child: FinanceServicesTab()),
      const _KeepAlivePage(child: FinanceHistoryTab()),
      _KeepAlivePage(child: FinanceSettingsTab(name: widget.name)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          allowImplicitScrolling: false,
          children: _pages,
        ),
      ),
      bottomNavigationBar: FinanceBottomNav(
        currentIndex: _currentIndex,
        onTap: _changePage,
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(child: widget.child);
  }
}

class _SwipeCoachmark extends StatelessWidget {
  const _SwipeCoachmark({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black.withValues(alpha: .42)),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).size.height * .28,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 18, end: 0),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: Column(
                children: [
                  const _SwipePreviewCard(),
                  const SizedBox(height: 16),
                  _CoachmarkCard(onClose: onClose),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text(
                  'Skip tip',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipePreviewCard extends StatelessWidget {
  const _SwipePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chevron_left_rounded,
            color: AppColors.financePrimary,
            size: 32,
          ),
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.financePrimary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_rounded, color: AppColors.financePrimary),
                  SizedBox(width: 8),
                  Text(
                    'Swipe pages',
                    style: TextStyle(
                      color: AppColors.financePrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.financePrimary,
            size: 32,
          ),
        ],
      ),
    );
  }
}

class _CoachmarkCard extends StatelessWidget {
  const _CoachmarkCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.financePrimary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.financePrimary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quick Navigation Tip',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Swipe left or right anywhere on the page to move between Home, Services, History and Settings.',
            style: TextStyle(
              color: AppColors.financeMuted,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.financePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
