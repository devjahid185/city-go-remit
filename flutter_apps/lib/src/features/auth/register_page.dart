import 'package:flutter/material.dart';
import 'package:flutter_apps/src/features/auth/otp_page.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';
import 'package:flutter_apps/src/shared/utils/validators.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';
import 'package:flutter_apps/src/shared/widgets/auth_shell.dart';
import 'package:flutter_apps/src/shared/widgets/auth_switch.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController(text: 'Dhaka, Bangladesh');
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referralCode = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirm.dispose();
    _referralCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await _api.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      password: _password.text,
      passwordConfirmation: _confirm.text,
      referralCode: _referralCode.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: _email.text.trim(),
            purpose: OtpPurpose.registration,
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
      title: 'Create Account',
      subtitle: 'Register your mobile app account securely.',
      footer: AuthSwitch(
        text: 'Already have an account?',
        action: 'Sign in',
        onTap: () => Navigator.of(context).pop(),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _name,
                label: 'Full Name',
                hint: 'Your name',
                validator: requiredField,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Email Address',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: requiredEmail,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phone,
                label: 'Phone Number',
                hint: '+880 1XXX-XXXXXX',
                keyboardType: TextInputType.phone,
                validator: requiredField,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _address,
                label: 'Address',
                hint: 'House, Road, City',
                validator: requiredField,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'Enter password',
                obscureText: _obscure,
                validator: strongPassword,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirm,
                label: 'Confirm Password',
                hint: 'Repeat password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your password';
                  }
                  if (value != _password.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _referralCode,
                label: 'Referral Code (Optional)',
                hint: 'Enter invite code',
              ),
              const SizedBox(height: 20),
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
