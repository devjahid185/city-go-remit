import 'package:flutter/material.dart';
import 'package:flutter_apps/src/core/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      loading ? 'Please wait...' : label,
      style: const TextStyle(fontWeight: FontWeight.w500),
    );

    return SizedBox(
      height: 52,
      child: icon == null && !loading
          ? FilledButton(
              onPressed: onPressed,
              style: _style(),
              child: labelWidget,
            )
          : FilledButton.icon(
              onPressed: loading ? null : onPressed,
              style: _style(),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon),
              label: labelWidget,
            ),
    );
  }

  ButtonStyle _style() {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.financePrimary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.financePrimary.withValues(alpha: .65),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
