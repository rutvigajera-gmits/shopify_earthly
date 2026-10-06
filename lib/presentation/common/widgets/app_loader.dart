import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  final double size;
  const AppLoader({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
        ),
      ),
    );
  }
}
