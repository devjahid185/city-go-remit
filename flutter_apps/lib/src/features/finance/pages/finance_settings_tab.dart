import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/features/finance/pages/beneficiaries_page.dart';
import 'package:flutter_apps/src/features/auth/login_page.dart';
import 'package:flutter_apps/src/features/finance/pages/live_chat_page.dart';
import 'package:flutter_apps/src/features/finance/pages/notification_center_page.dart';
import 'package:flutter_apps/src/features/finance/pages/personal_information_page.dart';
import 'package:flutter_apps/src/features/finance/pages/referral_page.dart';
import 'package:flutter_apps/src/features/finance/pages/security_settings_page.dart';
import 'package:flutter_apps/src/features/finance/widgets/finance_top_bar.dart';
import 'package:flutter_apps/src/services/push_notification_service.dart';
import 'package:flutter_apps/src/services/session_store.dart';

class FinanceSettingsTab extends StatefulWidget {
  const FinanceSettingsTab({required this.name, super.key});

  final String name;

  @override
  State<FinanceSettingsTab> createState() => _FinanceSettingsTabState();
}

class _FinanceSettingsTabState extends State<FinanceSettingsTab> {
  late Future<AppSession> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = const SessionStore().load();
  }

  void _refreshSession() {
    setState(() => _sessionFuture = const SessionStore().load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSession>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        final session = snapshot.data;
        final displayName = (session?.userName.trim().isNotEmpty ?? false)
            ? session!.userName
            : widget.name;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            FinanceTopBar(
              title: AppText.t('app_title'),
              onNotificationTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
              ),
            ),
            const SizedBox(height: 8),
            _ProfileHeader(
              name: displayName,
              email: session?.userEmail ?? '',
              phone: session?.userPhone ?? '',
              address: session?.userAddress ?? '',
            ),
            const SizedBox(height: 24),
            _SettingsSection(
              title: AppText.t('account'),
              children: [
                _SettingsTile(
                  icon: Icons.person_rounded,
                  title: AppText.t('personal_information'),
                  subtitle: AppText.t('personal_information_subtitle'),
                  onTap: session == null
                      ? null
                      : () async {
                          final updated = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => PersonalInformationPage(
                                session: session,
                              ),
                            ),
                          );
                          if (updated == true) _refreshSession();
                        },
                ),
                _SettingsTile(
                  icon: Icons.lock_rounded,
                  title: AppText.t('security_settings'),
                  subtitle: AppText.t('security_settings_subtitle'),
                  onTap: session == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SecuritySettingsPage(
                                session: session,
                              ),
                            ),
                          ),
                ),
                _SettingsTile(
                  icon: Icons.credit_card_rounded,
                  title: 'Saved Beneficiaries',
                  subtitle: 'Manage recharge, bill and bank receivers',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BeneficiariesPage()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.group_add_rounded,
                  title: 'Refer & Earn',
                  subtitle: 'Invite friends and track reward balance',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReferralPage()),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: AppText.t('preferences'),
              children: [
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: AppText.t('notifications'),
                  subtitle: AppText.t('notifications_subtitle'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.chat_bubble_rounded,
                  title: AppText.t('live_chat'),
                  subtitle: AppText.t('chat_header'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LiveChatPage()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: AppText.t('language'),
                  subtitle: AppText.languageName,
                  onTap: () => _showLanguageSheet(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutSheet(context),
                icon: const Icon(Icons.logout_rounded),
                label: Text(AppText.t('sign_out')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.financePrimary,
                  side: const BorderSide(color: AppColors.financePrimary),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogoutSheet(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LogoutSheet(),
    );

    if (confirmed != true || !context.mounted) return;

    await PushNotificationService.instance.unregisterCurrentToken();
    await const SessionStore().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> _showLanguageSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LanguageSheet(),
    );

    if (selected == null) return;
    await AppLanguageController.setLanguage(selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.t('language_updated'))),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.financeLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.financePrimary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.financePrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppText.t('logout_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppText.t('logout_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.financeMuted,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.financeLine),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppText.t('cancel'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.financePrimary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppText.t('sign_out'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.financeLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.t('select_language'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            for (final language in AppLanguage.values) ...[
              _LanguageTile(language: language),
              if (language != AppLanguage.values.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final selected = AppLanguageController.current == language;
    return Material(
      color: selected
          ? AppColors.financePrimary.withValues(alpha: .08)
          : AppColors.financeSurfaceLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () => Navigator.of(context).pop(language),
        leading: CircleAvatar(
          backgroundColor: selected ? AppColors.financePrimary : Colors.white,
          child: Icon(
            selected ? Icons.check_rounded : Icons.language_rounded,
            color: selected ? Colors.white : AppColors.financePrimary,
          ),
        ),
        title: Text(
          language.nativeName,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(language.englishName),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  final String name;
  final String email;
  final String phone;
  final String address;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isEmpty ? 'U' : name.trim().substring(0, 1).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.financeLine),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .035),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.financeSurfaceLow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.financePrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.financePrimary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProfileInfoRow(
              icon: Icons.mail_rounded,
              value: email.isEmpty ? AppText.t('email_not_set') : email,
            ),
            const SizedBox(height: 8),
            _ProfileInfoRow(
              icon: Icons.phone_rounded,
              value: phone.isEmpty ? AppText.t('phone_not_set') : phone,
            ),
            const SizedBox(height: 8),
            _ProfileInfoRow(
              icon: Icons.location_on_rounded,
              value: address.isEmpty ? AppText.t('address_not_set') : address,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.financePrimary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.financeMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.financeMuted,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.financeLine),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.financeSurfaceLow,
        child: Icon(icon, color: AppColors.financePrimary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.financeMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
