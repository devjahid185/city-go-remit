import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/forgot_page.dart';
import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/features/auth/onboarding_page.dart';
import 'package:flutter_apps/src/features/home/home_page.dart';
import 'package:flutter_apps/src/services/api_result.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/services/google_auth_service.dart';
import 'package:flutter_apps/src/services/push_notification_service.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/utils/validators.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';
import 'package:flutter_apps/src/shared/widgets/auth_shell.dart';
import 'package:flutter_apps/src/shared/widgets/auth_switch.dart';

class LoginPage extends StatefulWidget {
  LoginPage({GeoLocation? location, super.key})
      : location = location ?? GeoLocation.fallback();

  final GeoLocation location;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = AuthApi();
  final _googleAuth = GoogleAuthService();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await _api.login(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      await _saveLoginAndOpenHome(result);
    } else {
      showAppMessage(context, result.message);
    }
  }

  void _startSignup({required String source, String? email}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingPage(
          location: widget.location,
          source: source,
          email: email,
        ),
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final account = await _googleAuth.signIn();
      if (!mounted) return;

      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }

      final result = await _api.googleLogin(idToken: account.idToken);
      if (!mounted) return;
      setState(() => _googleLoading = false);

      if (result.ok) {
        await _saveLoginAndOpenHome(result);
      } else {
        showAppMessage(context, result.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _googleLoading = false);
      showAppMessage(context, 'Google sign-in setup is incomplete. Please try again later.');
    }
  }

  Future<void> _saveLoginAndOpenHome(ApiResult result) async {
    final user = result.data['user'] as Map<String, dynamic>? ?? {};
    final name = user['name']?.toString() ?? 'User';
    final token = result.data['token']?.toString();
    await const SessionStore().saveLogin(
      userName: name,
      userEmail: user['email']?.toString() ?? '',
      userPhone: user['phone']?.toString() ?? '',
      userAddress: user['address']?.toString() ?? '',
      userBalance: double.tryParse(user['balance']?.toString() ?? '') ?? 0,
      referralCode: user['referral_code']?.toString() ?? '',
      referralBonusEarned: double.tryParse(user['referral_bonus_earned']?.toString() ?? '') ?? 0,
      authToken: token,
    );
    await PushNotificationService.instance.registerSavedUserToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Welcome Back',
      subtitle: 'Sign in securely to manage your wallet.',
      footer: AuthSwitch(
        text: "Don't have an account?",
        action: 'Create account',
        onTap: () => _startSignup(
          source: 'email',
          email: _email.text.trim().contains('@') ? _email.text.trim() : null,
        ),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _email,
                label: 'Email Address',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: requiredEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: '••••••••',
                obscureText: _obscure,
                validator: requiredField,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPage()),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.financePrimary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Sign In',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),
              _GoogleButton(loading: _googleLoading, onPressed: _continueWithGoogle),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, required this.loading});

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.financeLine, width: 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.financePrimary,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: TextStyle(
                      color: AppColors.financePrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
