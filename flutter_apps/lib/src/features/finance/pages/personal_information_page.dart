import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/core/app_language.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
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
  final _api = AuthApi();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _dateOfBirth;
  late final TextEditingController _fatherName;
  late final TextEditingController _motherName;
  late final TextEditingController _countryName;
  late final TextEditingController _countryCode;
  late final TextEditingController _countryFlag;
  String _documentName = '';
  Uint8List? _documentBytes;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final nameParts = widget.session.userName.trim().split(' ');
    _firstName = TextEditingController(text: nameParts.isEmpty ? '' : nameParts.first);
    _lastName = TextEditingController(text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    _email = TextEditingController(text: widget.session.userEmail);
    _phone = TextEditingController(text: widget.session.userPhone);
    _address = TextEditingController(text: widget.session.userAddress);
    _dateOfBirth = TextEditingController();
    _fatherName = TextEditingController();
    _motherName = TextEditingController();
    _countryName = TextEditingController();
    _countryCode = TextEditingController();
    _countryFlag = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _dateOfBirth.dispose();
    _fatherName.dispose();
    _motherName.dispose();
    _countryName.dispose();
    _countryCode.dispose();
    _countryFlag.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (widget.session.userEmail.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final result = await _api.profile(email: widget.session.userEmail);
    if (!mounted) return;

    if (result.ok) {
      final user = result.data['user'] as Map<String, dynamic>? ?? {};
      _firstName.text = _value(user['first_name'], fallback: _firstName.text);
      _lastName.text = _value(user['last_name'], fallback: _lastName.text);
      _email.text = _value(user['email'], fallback: _email.text);
      _phone.text = _value(user['phone'], fallback: _phone.text);
      _address.text = _value(user['address'], fallback: _address.text);
      _dateOfBirth.text = _value(user['date_of_birth']);
      _fatherName.text = _value(user['father_name']);
      _motherName.text = _value(user['mother_name']);
      _countryName.text = _value(user['country_name']);
      _countryCode.text = _value(user['country_code']);
      _countryFlag.text = _value(user['country_flag']);
      _documentName = _value(user['government_document_name']);
    }

    setState(() => _loading = false);
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null) return;

    setState(() {
      _documentName = file.name;
      _documentBytes = file.bytes;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 12, now.month, now.day),
      initialDate: DateTime(now.year - 20, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.financePrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    _dateOfBirth.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final result = await _api.updateProfile(
      currentEmail: widget.session.userEmail,
      email: _email.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      dateOfBirth: _dateOfBirth.text.trim(),
      fatherName: _fatherName.text.trim(),
      motherName: _motherName.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      countryName: _countryName.text.trim(),
      countryCode: _countryCode.text.trim(),
      countryFlag: _countryFlag.text.trim(),
      documentName: _documentName.trim(),
      documentBytes: _documentBytes,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    final user = result.data['user'] as Map<String, dynamic>? ?? {};
    await const SessionStore().saveProfile(
      userName: _value(user['name'], fallback: '${_firstName.text} ${_lastName.text}'),
      userEmail: _value(user['email'], fallback: _email.text),
      userPhone: _value(user['phone'], fallback: _phone.text),
      userAddress: _value(user['address'], fallback: _address.text),
      userBalance: double.tryParse(user['balance']?.toString() ?? ''),
      referralCode: user['referral_code']?.toString(),
      referralBonusEarned: double.tryParse(user['referral_bonus_earned']?.toString() ?? ''),
    );

    if (!mounted) return;
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
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.financePrimary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _ProfileIntro(
                  initial: _initial(_firstName.text),
                  title: AppText.t('manage_profile'),
                  subtitle: AppText.t('manage_profile_body'),
                ),
                const SizedBox(height: 14),
                _FormCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _firstName,
                                label: 'First Name',
                                hint: 'Enter first name',
                                validator: _required,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                controller: _lastName,
                                label: 'Last Name',
                                hint: 'Enter last name',
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _email,
                          label: AppText.t('email_address'),
                          hint: AppText.t('email_hint'),
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _phone,
                          label: AppText.t('phone_number'),
                          hint: AppText.t('phone_hint'),
                          keyboardType: TextInputType.phone,
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _dateOfBirth,
                          label: 'Date of Birth',
                          hint: 'Select date',
                          readOnly: true,
                          onTap: _pickDate,
                          suffix: const Icon(Icons.calendar_month_rounded),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _fatherName,
                          label: 'Father Name',
                          hint: 'Enter father name',
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _motherName,
                          label: 'Mother Name',
                          hint: 'Enter mother name',
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _address,
                          label: AppText.t('address'),
                          hint: AppText.t('address_hint'),
                          validator: _required,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _countryName,
                                label: 'Country',
                                hint: 'Bangladesh',
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 110,
                              child: AppTextField(
                                controller: _countryCode,
                                label: 'Code',
                                hint: '+880',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _countryFlag,
                          label: 'Flag',
                          hint: '🇧🇩',
                        ),
                        const SizedBox(height: 18),
                        _DocumentPicker(
                          name: _documentName,
                          bytes: _documentBytes,
                          onTap: _pickDocument,
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

  String _value(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({
    required this.initial,
    required this.title,
    required this.subtitle,
  });

  final String initial;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
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
              initial,
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
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
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
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.financeLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({
    required this.name,
    required this.bytes,
    required this.onTap,
  });

  final String name;
  final Uint8List? bytes;
  final VoidCallback onTap;

  bool get _isImage {
    final lower = name.toLowerCase();
    return bytes != null &&
        (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp'));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.financeSurfaceLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.financeLine),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.financeLine),
                ),
                child: _isImage
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.badge_rounded,
                        color: AppColors.financePrimary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Government Document',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name.isEmpty ? 'Upload passport, NID or any official document' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.financeMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.upload_file_rounded, color: AppColors.financePrimary),
            ],
          ),
        ),
      ),
    );
  }
}
