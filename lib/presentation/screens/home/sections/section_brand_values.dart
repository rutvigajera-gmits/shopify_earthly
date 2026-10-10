import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';

class BrandValuesSection extends StatelessWidget {
  final BrandValuesData data;
  const BrandValuesSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty) Text(data.title, style: AppTextStyles.headlineLarge),
        16.height,
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: data.values.length.clamp(0, 4),
            itemBuilder: (_, i) {
              final v = data.values[i];
              return Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceCream,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (v.icon.isNotEmpty) Text(v.icon, style: const TextStyle(fontSize: 22)),
                    8.height,
                    Text(v.title, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                    4.height,
                    Text(
                      v.body,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
    ).paddingSymmetric(horizontal: AppConstants.horizontalPadding);
  }
}
