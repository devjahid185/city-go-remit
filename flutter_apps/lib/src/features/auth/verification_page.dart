import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_apps/src/features/auth/congratulations_page.dart';
import 'package:flutter_apps/src/features/auth/models/geo_location.dart';
import 'package:flutter_apps/src/services/auth_api.dart';
import 'package:flutter_apps/src/shared/utils/snackbars.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.fatherName,
    required this.motherName,
    required this.phone,
    required this.address,
    required this.location,
    required this.documentName,
    this.documentBytes,
    required this.password,
    required this.referralCode,
    required this.source,
    super.key,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String fatherName;
  final String motherName;
  final String phone;
  final String address;
  final GeoLocation location;
  final String documentName;
  final List<int>? documentBytes;
  final String password;
  final String referralCode;
  final String source;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _api = AuthApi();

  // Premium Fintech Colors (Consistent with the app)
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _primaryColor = Color(0xFF00503A);
  static const Color _textColor = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _verifyAndCreate();
  }

  Future<void> _verifyAndCreate() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    final result = await _api.kycRegister(
      email: widget.email,
      firstName: widget.firstName,
      lastName: widget.lastName,
      dateOfBirth: widget.dateOfBirth,
      fatherName: widget.fatherName,
      motherName: widget.motherName,
      phone: widget.phone,
      address: widget.address,
      countryName: widget.location.countryName,
      countryCode: widget.location.dialCode,
      countryFlag: widget.location.flag,
      documentName: widget.documentName,
      documentBytes: widget.documentBytes == null
          ? null
          : Uint8List.fromList(widget.documentBytes!),
      password: widget.password,
      passwordConfirmation: widget.password,
      source: widget.source,
      referralCode: widget.referralCode,
    );

    if (!mounted) return;
    if (!result.ok) {
      showAppMessage(context, result.message);
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            CongratulationsPage(name: '${widget.firstName} ${widget.lastName}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12), // Geometric border
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Secure Loading Indicator Container
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3EF), // Light brand color
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5, // Thinner, modern stroke
                          color: _primaryColor, // Solid brand color
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Trust-inspiring Header
                    const Text(
                      'Verifying Information',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Clear, professional subtitle
                    Text(
                      'Please wait while we securely review your identity details. This may take a few moments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Encrypted Connection Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          '256-bit Secure Connection',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
