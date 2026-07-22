import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/login_page.dart';
import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/utils/validators.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';
import 'package:flutter_apps/src/shared/widgets/auth_shell.dart';

enum OtpPurpose { registration, passwordReset }

class OtpPage extends StatefulWidget {
  const OtpPage({
    required this.email,
    required this.purpose,
    super.key,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;
  bool _obscure = true;

  bool get _isReset => widget.purpose == OtpPurpose.passwordReset;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = _isReset
        ? await _api.resetPasswordWithOtp(
            email: widget.email,
            otp: _otp.text.trim(),
            password: _password.text,
            passwordConfirmation: _confirm.text,
          )
        : await _api.verifyRegistrationOtp(
            email: widget.email,
            otp: _otp.text.trim(),
          );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      showAppMessage(
        context,
        _isReset
            ? 'Password reset complete. Please sign in.'
            : 'Account verified. Please sign in.',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage(location: GeoLocation.fallback())),
        (route) => false,
      );
    } else {
      showAppMessage(context, result.message);
    }
  }

  Future<void> _resend() async {
    if (!_isReset) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _loading = true);
    final result = await _api.forgotPassword(email: widget.email);
    if (!mounted) return;
    setState(() => _loading = false);
    showAppMessage(context, result.message);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: _isReset ? 'Reset Password' : 'Verify Identity',
      subtitle: 'We sent a 6-digit verification code to ${widget.email}.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isReset ? "Didn't receive the code? " : 'Wrong email address? ',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: _loading ? null : _resend,
            child: Text(
              _isReset ? 'Resend OTP' : 'Change email',
              style: TextStyle(
                color: _loading ? Colors.grey : AppColors.financePrimary,
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
                controller: _otp,
                label: 'Secure OTP Code',
                hint: '123456',
                keyboardType: TextInputType.number,
                textInputAction: _isReset ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: _isReset ? null : (_) => _submit(),
                validator: (value) {
                  if (value == null || value.trim().length != 6) {
                    return 'Enter a valid 6-digit code';
                  }
                  return null;
                },
              ),
              if (_isReset) ...[
                const SizedBox(height: 20),
                AppTextField(
                  controller: _password,
                  label: 'New Password',
                  hint: 'Enter new password',
                  obscureText: _obscure,
                  validator: strongPassword,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 20),
                AppTextField(
                  controller: _confirm,
                  label: 'Confirm New Password',
                  hint: 'Repeat password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _password.text) return 'Passwords do not match';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: 28),
              AppButton(
                label: _isReset ? 'Update Password' : 'Verify Account',
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
