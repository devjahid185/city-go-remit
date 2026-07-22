import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/utils/validators.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({required this.session, super.key});

  final AppSession session;

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _api = AuthApi();
  List<dynamic> _devices = [];
  bool _loading = false;
  bool _devicesLoading = true;
  bool _currentObscure = true;
  bool _newObscure = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final result = await _api.deviceHistory(email: widget.session.userEmail);
    if (!mounted) return;
    setState(() {
      _devicesLoading = false;
      _devices = result.data['devices'] as List<dynamic>? ?? [];
    });
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.session.userEmail.trim().isEmpty) {
      showAppMessage(context, AppText.t('missing_email'));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await _api.changePassword(
      email: widget.session.userEmail,
      currentPassword: _currentPassword.text,
      password: _newPassword.text,
      passwordConfirmation: _confirmPassword.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    showAppMessage(context, result.message);
    if (result.ok) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.financeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.financeBackground,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          AppText.t('security_settings'),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const _SecuritySummaryCard(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.financeLine),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppText.t('change_password'),
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppText.t('change_password_body'),
                    style: TextStyle(
                      color: AppColors.financeMuted,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _currentPassword,
                    label: AppText.t('current_password'),
                    hint: AppText.t('current_password_hint'),
                    obscureText: _currentObscure,
                    validator: requiredField,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () => _currentObscure = !_currentObscure,
                      ),
                      icon: Icon(
                        _currentObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _newPassword,
                    label: AppText.t('new_password'),
                    hint: AppText.t('new_password_hint'),
                    obscureText: _newObscure,
                    validator: strongPassword,
                    suffix: IconButton(
                      onPressed: () => setState(() => _newObscure = !_newObscure),
                      icon: Icon(
                        _newObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _confirmPassword,
                    label: AppText.t('confirm_new_password'),
                    hint: AppText.t('confirm_new_password_hint'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppText.t('confirm_password_required');
                      }
                      if (value != _newPassword.text) {
                        return AppText.t('passwords_do_not_match');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: AppText.t('update_password'),
                    icon: Icons.lock_reset_rounded,
                    loading: _loading,
                    onPressed: _changePassword,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SecurityOptionCard(
            icon: Icons.verified_user_rounded,
            title: AppText.t('device_protection'),
            subtitle: AppText.t('device_protection_body'),
          ),
          const SizedBox(height: 10),
          _SecurityOptionCard(
            icon: Icons.mark_email_read_rounded,
            title: AppText.t('otp_verification'),
            subtitle: AppText.t('otp_verification_body'),
          ),
          const SizedBox(height: 18),
          _DeviceHistoryCard(loading: _devicesLoading, devices: _devices),
        ],
      ),
    );
  }
}

class _DeviceHistoryCard extends StatelessWidget {
  const _DeviceHistoryCard({required this.loading, required this.devices});

  final bool loading;
  final List<dynamic> devices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Login History', style: TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Recent sign-ins help you spot suspicious access.', style: TextStyle(color: AppColors.financeMuted)),
          const SizedBox(height: 14),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (devices.isEmpty)
            const Text('No device activity found yet.', style: TextStyle(color: AppColors.financeMuted))
          else
            ...devices.take(5).map((raw) {
              final item = raw as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.devices_rounded, color: AppColors.financePrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['device_name']?.toString().isNotEmpty == true ? item['device_name'].toString() : 'App Device', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500)),
                          Text('${item['platform'] ?? 'unknown'} · ${item['logged_in_at'] ?? ''}', style: const TextStyle(color: AppColors.financeMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SecuritySummaryCard extends StatelessWidget {
  const _SecuritySummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppText.t('account_protection_active'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  AppText.t('account_protection_body'),
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _SecurityOptionCard extends StatelessWidget {
  const _SecurityOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.financeSurfaceLow,
            child: Icon(icon, color: AppColors.financePrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.financeMuted,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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
