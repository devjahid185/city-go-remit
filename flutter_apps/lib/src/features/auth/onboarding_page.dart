import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';
import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/features/auth/verification_page.dart';
import 'package:flutter_apps/src/shared/utils/validators.dart';
import 'package:flutter_apps/src/shared/widgets/app_button.dart';
import 'package:flutter_apps/src/shared/widgets/app_text_field.dart';
import 'package:flutter_apps/src/shared/widgets/info_card.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.location,
    required this.source,
    this.email,
    super.key,
  });

  final GeoLocation location;
  final String source;
  final String? email;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _dob = TextEditingController();
  final _fatherName = TextEditingController();
  final _motherName = TextEditingController();
  final _phone = TextEditingController();
  late final TextEditingController _address;
  late final TextEditingController _countryCode;
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _referralCode = TextEditingController();
  String? _documentName;
  List<int>? _documentBytes;
  int _step = 0;

  static const Color _bgColor = AppColors.financeBackground;
  static const Color _primaryColor = AppColors.financePrimary;
  static const Color _textColor = AppColors.ink;

  static const _stepTitles = [
    'Email Verification',
    'Personal Details',
    'Family Details',
    'Phone & Address',
    'Identity Document',
    'Account Password',
  ];

  bool get _isLastStep => _step == _stepTitles.length - 1;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email ?? '');
    _address = TextEditingController(text: widget.location.addressHint);
    _countryCode = TextEditingController(text: widget.location.dialCode);
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _dob.dispose();
    _fatherName.dispose();
    _motherName.dispose();
    _phone.dispose();
    _address.dispose();
    _countryCode.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _referralCode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor, 
              onPrimary: Colors.white,
              onSurface: _textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    _dob.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDocument() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Document Type',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.financeSurfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book_rounded, color: _primaryColor),
                ),
                title: const Text('Passport', style: TextStyle(fontWeight: FontWeight.w500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () => Navigator.pop(context, 'Passport document'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.financeSurfaceLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.badge_rounded, color: _primaryColor),
                ),
                title: const Text('Government ID', style: TextStyle(fontWeight: FontWeight.w500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () => Navigator.pop(context, 'Government ID document'),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;

    setState(() {
      _documentName = '$selected: ${file.name}';
      _documentBytes = file.bytes;
    });
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_step == 4 && _documentName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a passport or government document.'),
          backgroundColor: AppColors.financePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isLastStep) {
      setState(() => _step += 1);
      return;
    }

    _submit();
  }

  void _previousStep() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
  }

  void _submit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationPage(
          email: _email.text.trim(),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          dateOfBirth: _dob.text.trim(),
          fatherName: _fatherName.text.trim(),
          motherName: _motherName.text.trim(),
          phone: _phone.text.trim(),
          address: _address.text.trim(),
          location: widget.location,
          documentName: _documentName!,
          documentBytes: _documentBytes,
          password: _password.text,
          referralCode: _referralCode.text.trim(),
          source: widget.source,
        ),
      ),
    );
  }

  String get _subtitleForStep {
    return switch (_step) {
      0 => 'Confirm your email before starting identity setup.',
      1 => 'Tell us your legal name and date of birth.',
      2 => 'Add parent information for identity verification.',
      3 => 'Your country code is fixed from IP location.',
      4 => 'Upload a clear document to complete KYC.',
      _ => 'Create a password for secure login.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textColor),
          onPressed: _previousStep,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Header
              Text(
                _stepTitles[_step],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitleForStep,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),

              // Form Card (Solid White, No Shadow)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.financeLine, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: .06),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StepProgress(currentStep: _step, totalSteps: _stepTitles.length),
                    const SizedBox(height: 24),
                    
                    // Show InfoCard only on the first step to reduce visual clutter, 
                    // or adapt as you need. Kept it for all as per your original code.
                    InfoCard(
                      icon: Icons.public_rounded,
                      title: '${widget.location.flag} ${widget.location.countryName}',
                      body: 'Country code fixed as ${widget.location.dialCode}',
                    ),
                    const SizedBox(height: 24),
                    
                    Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStepContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Navigation Buttons placed outside the card for better layout flow
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textColor,
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _step == 0 ? 'Cancel' : 'Back',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppButton(
                      label: _isLastStep ? 'Submit' : 'Continue',
                      // Removed icon for a cleaner, modern look, but you can add it back
                      onPressed: _nextStep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _EmailStep(email: _email, source: widget.source),
      1 => _PersonalStep(
        firstName: _firstName,
        lastName: _lastName,
        dob: _dob,
        pickDate: _pickDate,
      ),
      2 => _FamilyStep(fatherName: _fatherName, motherName: _motherName),
      3 => _ContactStep(
        countryCode: _countryCode,
        phone: _phone,
        address: _address,
        dialCode: widget.location.dialCode,
      ),
      4 => _DocumentStep(
        documentName: _documentName,
        documentBytes: _documentBytes,
        onTap: _selectDocument,
      ),
      _ => _PasswordStep(
        password: _password,
        confirmPassword: _confirmPassword,
        referralCode: _referralCode,
      ),
    };
  }
}

// --- Sub-widgets modified for Fintech aesthetic ---

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: const TextStyle(
                color: AppColors.financePrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4), // Flatter edges
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: AppColors.financePrimary,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({required this.email, required this.source});

  final TextEditingController email;
  final String source;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: email,
      label: source == 'google' ? 'Google Email' : 'Email Address',
      hint: 'your@gmail.com',
      keyboardType: TextInputType.emailAddress,
      validator: requiredEmail,
    );
  }
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep({
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.pickDate,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController dob;
  final VoidCallback pickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: firstName,
          label: 'Legal First Name',
          hint: 'As per your ID',
          validator: requiredField,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: lastName,
          label: 'Legal Last Name',
          hint: 'As per your ID',
          validator: requiredField,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: dob,
          label: 'Date of Birth',
          hint: 'YYYY-MM-DD',
          readOnly: true,
          onTap: pickDate,
          validator: requiredField,
          suffix: IconButton(
            onPressed: pickDate,
            icon: Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600, size: 20),
          ),
        ),
      ],
    );
  }
}

class _FamilyStep extends StatelessWidget {
  const _FamilyStep({required this.fatherName, required this.motherName});

  final TextEditingController fatherName;
  final TextEditingController motherName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: fatherName,
          label: "Father's Full Name",
          hint: 'Enter full name',
          validator: requiredField,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: motherName,
          label: "Mother's Full Name",
          hint: 'Enter full name',
          validator: requiredField,
        ),
      ],
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.countryCode,
    required this.phone,
    required this.address,
    required this.dialCode,
  });

  final TextEditingController countryCode;
  final TextEditingController phone;
  final TextEditingController address;
  final String dialCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: AppTextField(
                controller: countryCode,
                label: 'Code',
                hint: dialCode,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: phone,
                label: 'Phone Number',
                hint: '0000 000 000',
                keyboardType: TextInputType.phone,
                validator: requiredField,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: address,
          label: 'Residential Address',
          hint: 'House, Street, City',
          validator: requiredField,
        ),
      ],
    );
  }
}

class _DocumentStep extends StatelessWidget {
  const _DocumentStep({
    required this.documentName,
    required this.documentBytes,
    required this.onTap,
  });

  final String? documentName;
  final List<int>? documentBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.financeSurfaceLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.financeLine),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppColors.financePrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data is securely encrypted and only used for identity verification.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DocumentTile(
          documentName: documentName,
          documentBytes: documentBytes,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.password,
    required this.confirmPassword,
    required this.referralCode,
  });

  final TextEditingController password;
  final TextEditingController confirmPassword;
  final TextEditingController referralCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: password,
          label: 'Create Password',
          hint: 'Enter password',
          obscureText: true,
          validator: strongPassword,
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: confirmPassword,
          label: 'Confirm Password',
          hint: 'Repeat password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != password.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: referralCode,
          label: 'Referral Code (Optional)',
          hint: 'Enter invite code if you have one',
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.documentName,
    required this.documentBytes,
    required this.onTap,
  });

  final String? documentName;
  final List<int>? documentBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDocument = documentName != null;
    final isImage = _isPreviewableImage(documentName);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDocument
              ? AppColors.financePrimary.withValues(alpha: .08)
              : Colors.white,
          border: Border.all(
            color: hasDocument
                ? AppColors.financePrimary
                : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  hasDocument ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                  color: hasDocument
                      ? AppColors.financePrimary
                      : Colors.grey.shade600,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDocument ? 'Document Selected' : 'Upload ID Document',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: hasDocument
                              ? AppColors.financePrimary
                              : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documentName ?? 'Tap to select Passport or Govt ID',
                        style: TextStyle(
                          color: hasDocument
                              ? AppColors.financePrimary.withValues(alpha: .8)
                              : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.edit_rounded, color: Colors.grey.shade500, size: 20),
              ],
            ),
            if (hasDocument) ...[
              const SizedBox(height: 14),
              Container(
                height: 150,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.financeLine),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isImage && documentBytes != null
                    ? Image.memory(
                        Uint8List.fromList(documentBytes!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: AppColors.financePrimary,
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Document preview ready',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isPreviewableImage(String? value) {
    final lower = value?.toLowerCase() ?? '';
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }
}
