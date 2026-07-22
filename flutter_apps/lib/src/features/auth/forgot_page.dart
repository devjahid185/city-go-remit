import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/otp_page.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/utils/validators.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';
import 'package:flutter_apps/src/shared/widgets/auth_shell.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await _api.forgotPassword(email: _email.text.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: _email.text.trim(),
            purpose: OtpPurpose.passwordReset,
          ),
        ),
      );
    } else {
      showAppMessage(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Recover Access',
      subtitle: 'Enter your registered email to receive a secure OTP.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Remembered password? ',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Back to login',
              style: TextStyle(
                color: AppColors.financePrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Send OTP',
                icon: Icons.mark_email_read_rounded,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
