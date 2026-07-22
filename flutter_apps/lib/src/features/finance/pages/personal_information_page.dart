import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/session_store.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({required this.session, super.key});

  final AppSession session;

  @override
  State<PersonalInformationPage> createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.session.userName);
    _email = TextEditingController(text: widget.session.userEmail);
    _phone = TextEditingController(text: widget.session.userPhone);
    _address = TextEditingController(text: widget.session.userAddress);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    await const SessionStore().saveProfile(
      userName: _name.text,
      userEmail: _email.text,
      userPhone: _phone.text,
      userAddress: _address.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppText.t('profile_updated'))),
    );
    Navigator.of(context).pop(true);
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
          AppText.t('personal_information'),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
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
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.financeSurfaceLow,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _initial(_name.text),
                    style: const TextStyle(
                      color: AppColors.financePrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppText.t('manage_profile'),
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        AppText.t('manage_profile_body'),
                        style: TextStyle(
                          color: AppColors.financeMuted,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                  AppTextField(
                    controller: _name,
                    label: AppText.t('full_name'),
                    hint: AppText.t('full_name_hint'),
                    validator: _required,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _email,
                    label: AppText.t('email_address'),
                    hint: AppText.t('email_hint'),
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _phone,
                    label: AppText.t('phone_number'),
                    hint: AppText.t('phone_hint'),
                    keyboardType: TextInputType.phone,
                    validator: _required,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _address,
                    label: AppText.t('address'),
                    hint: AppText.t('address_hint'),
                    validator: _required,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: AppText.t('save_changes'),
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppText.t('required_field');
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppText.t('required_field');
    if (!input.contains('@') || !input.contains('.')) {
      return AppText.t('valid_email');
    }
    return null;
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed.substring(0, 1).toUpperCase();
  }
}
