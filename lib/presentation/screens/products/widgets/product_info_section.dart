import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/providers/review_provider.dart';

class ProductInfoSection extends StatelessWidget {
  final Product product;
  final ProductVariant? selectedVariant;

  const ProductInfoSection(
      {super.key, required this.product, required this.selectedVariant});

  @override
  Widget build(BuildContext context) {
    final price = selectedVariant != null
        ? FormatUtils.formatRsPrice(selectedVariant!.price)
        : product.formattedMinPrice;
    final compareAt = selectedVariant?.hasDiscount == true
        ? FormatUtils.formatRsPrice(selectedVariant!.compareAtPrice!)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding, 16, AppConstants.horizontalPadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.title, style: AppTextStyles.displaySmall),
          const SizedBox(height: 12),

          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(price,
                  style: AppTextStyles.priceLarge.copyWith(color: AppColors.teal)),
              if (compareAt != null) ...[
                const SizedBox(width: 8),
                Text(compareAt, style: AppTextStyles.priceStrikethrough),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _showBreakup(context, price),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('+ Price Breakup',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textPrimary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('MRP Incl. of all taxes',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 10),

          // Star rating
          Consumer<ReviewProvider>(builder: (context, rp, _) {
            final summary = rp.productReviews(product.handle);
            if (summary == null || summary.totalCount == 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ...List.generate(5, (i) {
                    final r = summary.averageRating;
                    return Icon(
                      i < r.floor()
                          ? Icons.star
                          : (i < r ? Icons.star_half : Icons.star_border),
                      size: 18,
                      color: AppColors.gold,
                    );
                  }),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(AppStrings.reviewsUrl);
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      '${summary.averageRating.toStringAsFixed(1)} / 5  (Google Reviews)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.teal,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Virtual Try-On
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Virtual Try-On coming soon!')),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text('Virtual Try-On',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Trust badges — horizontal scroll
          const _TrustBadgesGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showBreakup(BuildContext context, String total) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price Breakup', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              _BreakupRow('Diamond Price', total),
              const _BreakupRow('Making Charges', 'Included'),
              const _BreakupRow('3% GST', 'Included'),
              const Divider(),
              _BreakupRow('Total', total, bold: true),
              const SizedBox(height: 12),
            ]),
      ),
    );
  }
}

class _BreakupRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _BreakupRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final s = bold
        ? AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)
        : AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: s),
        Text(value, style: s),
      ]),
    );
  }
}

class _TrustBadgesGrid extends StatelessWidget {
  const _TrustBadgesGrid();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _TrustBadge(
              icon: Icons.verified_outlined,
              label: 'IGI/SGL certified',
              color: AppColors.success),
          SizedBox(width: 8),
          _TrustBadge(
              icon: Icons.workspace_premium_outlined,
              label: 'BIS hallmarked',
              color: AppColors.teal),
          SizedBox(width: 8),
          _TrustBadge(
              icon: Icons.local_shipping_outlined,
              label: 'Free Insured shipping',
              color: AppColors.success),
          SizedBox(width: 8),
          _TrustBadge(
              icon: Icons.security_outlined,
              label: 'Secure Pay',
              color: AppColors.teal),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textPrimary, fontSize: 11)),
        ),
      ]),
    );
  }
}
