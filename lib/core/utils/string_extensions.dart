import 'package:demo_earthly/core/theme/app_colors.dart';
import 'package:demo_earthly/store/appstore.dart';
import 'package:flutter/material.dart';

extension strEtx on String {
  Widget iconImage({double? size, Color? color, BoxFit? fit}) {
    final iconColor =
        color ?? (appStore.isDarkMode ? Colors.white : AppColors.textSecondary);
    return Image.asset(
      this,
      height: size ?? 24,
      width: size ?? 24,
      fit: fit ?? BoxFit.cover,
      color: iconColor,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.image_not_supported_outlined,
          size: size ?? 24,
          color: iconColor,
        );
      },
    );
  }
}
