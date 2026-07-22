import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';

class FinanceTopBar extends StatelessWidget {
  const FinanceTopBar({
    required this.title,
    this.showMenu = false,
    this.onChatTap,
    this.onNotificationTap,
    super.key,
  });

  final String title;
  final bool showMenu;
  final VoidCallback? onChatTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final foreground = showMenu ? Colors.white : AppColors.financePrimary;
    final muted = showMenu ? Colors.white : AppColors.financeMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: showMenu ? Colors.white.withValues(alpha: .12) : AppColors.financeSurfaceLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: showMenu ? Colors.white24 : AppColors.financeLine),
            ),
            child: Icon(
              showMenu ? Icons.menu_rounded : Icons.person_rounded,
              color: foreground,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              letterSpacing: -.4,
            ).copyWith(color: foreground),
          ),
          const Spacer(),
          if (onChatTap != null) ...[
            _TopBarChatButton(
              muted: muted,
              onTap: onChatTap!,
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(Icons.notifications_none_rounded),
            color: muted,
          ),
        ],
      ),
    );
  }
}

class _TopBarChatButton extends StatelessWidget {
  const _TopBarChatButton({
    required this.muted,
    required this.onTap,
  });

  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Live Chat',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.financeLine),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: muted,
                size: 22,
              ),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    border: Border.all(color: Colors.white, width: 1.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
