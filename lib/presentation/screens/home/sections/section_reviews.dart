import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/providers/review_provider.dart';

class ReviewsCarouselSection extends StatefulWidget {
  final ReviewsCarouselData data;
  const ReviewsCarouselSection({super.key, required this.data});

  @override
  State<ReviewsCarouselSection> createState() => _ReviewsCarouselSectionState();
}

class _ReviewsCarouselSectionState extends State<ReviewsCarouselSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewProvider>().loadStoreReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, rp, _) {
        final loading = rp.loadingStore;
        final reviews = rp.storeReviews;
        final title = widget.data.sectionTitle.isNotEmpty
            ? widget.data.sectionTitle
            : 'Customer Reviews';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
              child: Text(title, style: AppTextStyles.headlineLarge),
            ),
            16.height,
            if (loading)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: AppConstants.cardSpacing),
                  itemBuilder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(width: 260, height: 200, color: Colors.white),
                  ),
                ),
              )
            else if (reviews.isNotEmpty)
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppConstants.cardSpacing),
                  itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) => Icon(
              i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 14,
              color: AppColors.rating,
            )),
          ),
          8.height,
          if (review.title != null && review.title!.isNotEmpty) ...[
            Text(
              review.title!,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary, letterSpacing: 0.2, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            4.height,
          ],
          Expanded(
            child: Text(
              review.body,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.55),
              overflow: TextOverflow.fade,
              maxLines: 6,
            ),
          ),
          10.height,
          Row(
            children: [
              _AvatarCircle(name: review.reviewerName),
              8.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 10, color: AppColors.teal),
                        3.width,
                        Text('Verified Buyer',
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.teal, fontSize: 9)),
                        if (review.formattedDate.isNotEmpty)
                          Text('  ·  ${review.formattedDate}',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  const _AvatarCircle({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 30, height: 30,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
