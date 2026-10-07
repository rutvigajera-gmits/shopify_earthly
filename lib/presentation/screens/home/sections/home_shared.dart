import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// Centered outlined pill button — border only, no fill
class HomePillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HomePillBtn({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// White outlined button — used on dark/image backgrounds
class HomeOutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const HomeOutlineBtn({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppTextStyles.button.copyWith(color: Colors.white, letterSpacing: 1.5)),
    );
  }
}

// Solid dark inline button
class HomeDarkBtn extends StatelessWidget {
  final String label;

  const HomeDarkBtn({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      color: AppColors.primary,
      child: Text(label, style: AppTextStyles.button.copyWith(color: AppColors.textWhite, letterSpacing: 1.5)),
    );
  }
}
