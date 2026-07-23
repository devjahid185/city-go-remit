import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/login_page.dart';
import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';

class IntroOnboardingPage extends StatefulWidget {
  const IntroOnboardingPage({required this.location, super.key});

  final GeoLocation location;

  @override
  State<IntroOnboardingPage> createState() => _IntroOnboardingPageState();
}

class _IntroOnboardingPageState extends State<IntroOnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _IntroSlide(
      title: 'Secure Digital Banking',
      highlight: 'Banking',
      description:
          'Manage your wealth with bank-grade security, encrypted access, and trusted account protection.',
      badge: '256-bit AES',
      icon: Icons.verified_user_rounded,
      illustration: _IllustrationType.vault,
      chips: ['Encrypted', 'Insured', 'Biometric'],
    ),
    _IntroSlide(
      title: 'Instant Global Payments',
      highlight: 'Payments',
      description:
          'Send and receive money across banks and wallets with fast settlement and transparent fees.',
      badge: '< 1s Transfer',
      icon: Icons.bolt_rounded,
      illustration: _IllustrationType.global,
      chips: ['180+ Countries', 'AES-256', 'Zero Hidden Fees'],
    ),
    _IntroSlide(
      title: 'Track & Grow',
      highlight: 'Grow',
      description:
          'Get smart insights on spending, savings, and growth so every financial move feels clear.',
      badge: '+24.8%',
      icon: Icons.trending_up_rounded,
      illustration: _IllustrationType.insights,
      chips: ['Smart Tips', 'Live Insights', 'Savings Goals'],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    await const SessionStore().markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage(location: widget.location)),
    );
  }

  Future<void> _next() async {
    if (_index == _pages.length - 1) {
      await _openLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -70,
            child: _AmbientCircle(
              size: 190,
              color: AppColors.financePrimary.withValues(alpha: .08),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -95,
            child: _AmbientCircle(
              size: 220,
              color: const Color(0xFF66768D).withValues(alpha: .08),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'City Go Remit',
                            style: TextStyle(
                              color: AppColors.financePrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -.6,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _openLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => _OnboardingSlideView(
                      slide: _pages[index],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    children: [
                      _ProgressDots(activeIndex: _index, total: _pages.length),
                      const SizedBox(height: 18),
                      AppButton(
                        label: _index == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        icon: _index == _pages.length - 1
                            ? Icons.login_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: _next,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _openLogin,
                        child: const Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: AppColors.financePrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeroPanel(slide: slide),
          const SizedBox(height: 28),
          _TitleText(title: slide.title, highlight: slide.highlight),
          const SizedBox(height: 12),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final chip in slide.chips) _TrustChip(label: chip),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: .05,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.financeSurfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.financeLine),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: .06),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: _IllustrationCanvas(type: slide.illustration),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _FloatingBadge(icon: slide.icon, label: slide.badge),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCanvas extends StatelessWidget {
  const _IllustrationCanvas({required this.type});

  final _IllustrationType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      _IllustrationType.vault => const _VaultIllustration(),
      _IllustrationType.global => const _GlobalIllustration(),
      _IllustrationType.insights => const _InsightsIllustration(),
    };
  }
}

class _VaultIllustration extends StatelessWidget {
  const _VaultIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _SoftGrid(),
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            color: AppColors.financeSurfaceLow,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.financeLine, width: 10),
          ),
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.financePrimary, width: 6),
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: AppColors.financePrimary,
            size: 46,
          ),
        ),
        Positioned(
          right: 34,
          top: 54,
          child: _MiniCard(
            icon: Icons.fingerprint_rounded,
            text: 'Bio',
            accent: AppColors.financePrimary,
          ),
        ),
      ],
    );
  }
}

class _GlobalIllustration extends StatelessWidget {
  const _GlobalIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const _SoftGrid(),
        Container(
          width: 188,
          height: 188,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.financeSurfaceLow,
            border: Border.all(color: AppColors.financeLine),
          ),
          child: const Icon(
            Icons.public_rounded,
            color: AppColors.financePrimary,
            size: 96,
          ),
        ),
        Positioned(
          left: 20,
          bottom: 42,
          child: _CurrencyStack(),
        ),
        Positioned(
          right: 22,
          top: 40,
          child: _MiniCard(
            icon: Icons.sync_alt_rounded,
            text: 'Fast',
            accent: AppColors.financePrimary,
          ),
        ),
      ],
    );
  }
}

class _InsightsIllustration extends StatelessWidget {
  const _InsightsIllustration();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final gap = 8.0;
        final mainWidth = width * .62;
        final sideWidth = width - mainWidth - gap;

        return Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: mainWidth,
              height: height * .62,
              child: const _InsightCard(
                title: 'Net Growth',
                value: '+24.8%',
                icon: Icons.trending_up_rounded,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              width: sideWidth,
              height: height * .30,
              child: const _SmallInsight(
                icon: Icons.savings_rounded,
                label: '85%',
              ),
            ),
            Positioned(
              right: 0,
              top: height * .30 + gap,
              width: sideWidth,
              height: height * .32,
              child: const _SmallInsight(
                icon: Icons.restaurant_rounded,
                label: '-\$120',
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              width: (width - gap) / 2,
              height: height * .28,
              child: const _WideInsight(label: 'Insights'),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              width: (width - gap) / 2,
              height: height * .28,
              child: const _WideInsight(label: 'Smart Tip', active: true),
            ),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: AppColors.financePrimary, size: 20),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.financePrimary,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const _TinyChart(),
        ],
      ),
    );
  }
}

class _SmallInsight extends StatelessWidget {
  const _SmallInsight({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.financeSurfaceLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.financePrimary, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideInsight extends StatelessWidget {
  const _WideInsight({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.financePrimary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.financePrimary : AppColors.financeLine,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: active ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TinyChart extends StatelessWidget {
  const _TinyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: CustomPaint(
        painter: _ChartPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.financePrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * .82)
      ..quadraticBezierTo(size.width * .18, size.height * .60, size.width * .30, size.height * .52)
      ..quadraticBezierTo(size.width * .48, size.height * .36, size.width * .60, size.height * .44)
      ..quadraticBezierTo(size.width * .78, size.height * .58, size.width, size.height * .18);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title, required this.highlight});

  final String title;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final parts = title.split(highlight);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w500,
          letterSpacing: -.5,
        ),
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: highlight,
            style: const TextStyle(color: AppColors.financePrimary),
          ),
          if (parts.length > 1) TextSpan(text: parts.last),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.financePrimaryStrong,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.financePrimary.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.activeIndex, required this.total});

  final int activeIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < total; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: activeIndex == index ? 34 : 8,
            height: activeIndex == index ? 6 : 6,
            decoration: BoxDecoration(
              color: activeIndex == index
                  ? AppColors.financePrimary
                  : AppColors.financeLine,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          if (index != total - 1) const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _SoftGrid extends StatelessWidget {
  const _SoftGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (int index = 0; index < 64; index++)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.financeLine.withValues(alpha: .65),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .90),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.financeLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyStack extends StatelessWidget {
  const _CurrencyStack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _CurrencyBubble(label: 'USD', color: Color(0xFF565E74)),
        _CurrencyBubble(label: 'EUR', color: AppColors.financePrimary),
        _CurrencyBubble(label: 'GBP', color: Color(0xFF4D5D73)),
      ],
    );
  }
}

class _CurrencyBubble extends StatelessWidget {
  const _CurrencyBubble({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.size, required this.color});

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

class _IntroSlide {
  const _IntroSlide({
    required this.title,
    required this.highlight,
    required this.description,
    required this.badge,
    required this.icon,
    required this.illustration,
    required this.chips,
  });

  final String title;
  final String highlight;
  final String description;
  final String badge;
  final IconData icon;
  final _IllustrationType illustration;
  final List<String> chips;
}

enum _IllustrationType { vault, global, insights }
