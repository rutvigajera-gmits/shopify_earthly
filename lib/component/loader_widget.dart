import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../core/theme/app_colors.dart';

class LoaderWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoaderWidget({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return SpinKitChasingDots(
      color: color ?? AppColors.primary,
      size: size,
    );
  }
}
