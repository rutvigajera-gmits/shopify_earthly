import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/shape_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AllShapesScreen extends StatelessWidget {
  // API-provided handles override the fallback handles in kAllShapes.
  final Map<String, String> apiHandles;

  const AllShapesScreen({super.key, this.apiHandles = const {}});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Shop by Shape', style: AppTextStyles.headlineSmall),
        centerTitle: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75,
        ),
        itemCount: kAllShapes.length,
        itemBuilder: (context, i) {
          final (name, svg, fallbackHandle) = kAllShapes[i];
          final handle = apiHandles[name.toLowerCase()] ?? fallbackHandle;
          return _ShapeGridTile(
            label: name,
            svgPath: svg,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.shapeProducts,
              arguments: {'shapeName': name, 'handle': handle},
            ),
          )
              .animate(delay: Duration(milliseconds: 60 + i * 40))
              .fadeIn(duration: 280.ms)
              .slideY(begin: 0.25, end: 0, duration: 280.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _ShapeGridTile extends StatelessWidget {
  final String label;
  final String svgPath;
  final VoidCallback onTap;

  const _ShapeGridTile({
    required this.label,
    required this.svgPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(18),
            child: SvgPicture.asset(
              svgPath,
              colorFilter: const ColorFilter.mode(AppColors.teal, BlendMode.srcIn),
            ),
          ),
          5.height,
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
