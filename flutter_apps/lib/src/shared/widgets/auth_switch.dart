import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';

class AuthSwitch extends StatelessWidget {
  const AuthSwitch({
    required this.text,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: AppColors.financePrimary),
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
