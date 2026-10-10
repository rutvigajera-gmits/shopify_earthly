import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../simple_web_screen.dart';
import '../../../../core/config/api_config.dart';
import '../../../../data/services/shopify_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/review_provider.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.title, style: AppTextStyles.displaySmall),
        12.height,

        // Price row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(price,
                style: AppTextStyles.priceLarge.copyWith(color: AppColors.teal)),
            if (compareAt != null) ...[
              8.width,
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
        4.height,
        Text('MRP Incl. of all taxes',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        10.height,

        // Star rating
        Consumer<ReviewProvider>(builder: (context, rp, _) {
          final summary = rp.productReviews(product.handle);
          if (summary == null || summary.totalCount == 0) {
            return const SizedBox.shrink();
          }
          return Row(
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
              6.width,
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
          ).paddingOnly(bottom: 10);
        }),

        // Virtual Try-On
        Builder(builder: (ctx) {
          final sku = selectedVariant?.sku ?? '';
          final customerId =
              ctx.read<CustomerProvider>().customer?.id ?? '';
          final slug =
              sku.contains('-') ? sku.split('-').first : sku;
          final numericId = customerId.contains('/')
              ? customerId.split('/').last
              : customerId;

          return GestureDetector(
            onTap: () async {
              var selectionId = product.vtryonSelectionId ?? '';
              debugPrint('[VTryOn] handle       : ${product.handle}');
              debugPrint('[VTryOn] tags          : ${product.tags}');
              debugPrint('[VTryOn] selectionId   : '
                  '${selectionId.isEmpty ? "(empty — will scrape)" : selectionId}');
              debugPrint('[VTryOn] sku           : $sku');
              debugPrint('[VTryOn] slug          : $slug');
              debugPrint('[VTryOn] numericId     : $numericId');

              // Kick off live-page scraping now so it runs while the user
              // responds to the camera permission dialog (free latency).
              final scrapeFuture = selectionId.isEmpty
                  ? ShopifyService.instance
                      .scrapeVTryOnSelectionId(product.handle)
                      .timeout(const Duration(seconds: 8),
                          onTimeout: () => null)
                  : Future<String?>.value(selectionId);

              // Ensure OS-level camera permission before opening WebView
              final status = await Permission.camera.request();
              debugPrint('[VTryOn] camera status : $status');
              if (status.isPermanentlyDenied) {
                if (ctx.mounted) openAppSettings();
                return;
              }

              // Collect scrape result (often already done by this point)
              if (selectionId.isEmpty) {
                selectionId = await scrapeFuture ?? '';
                debugPrint('[VTryOn] scraped       : '
                    '${selectionId.isEmpty ? "(empty)" : selectionId}');
              }

              final params = <String, String>{
                'shop': VTryOnConfig.shopDomain,
                if (selectionId.isNotEmpty) 'selectionId': selectionId,
                if (sku.isNotEmpty) 'variantSku': sku,
                if (slug.isNotEmpty) 'variantSlug': slug,
                if (numericId.isNotEmpty) 'user_id': numericId,
              };
              final tryOnUrl = Uri.parse(VTryOnConfig.baseUrl)
                  .replace(queryParameters: params)
                  .toString();
              debugPrint('[VTryOn] opening url   : $tryOnUrl');

              if (!ctx.mounted) return;
              Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => SimpleWebScreen(
                  title: 'Virtual Try-On',
                  url: tryOnUrl,
                ),
              ));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 22),
                  12.width,
                  Text('Virtual Try-On',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Colors.white, size: 22),
                ],
              ),
            ),
          );
        }),
        14.height,

        // Trust badges — horizontal scroll
        const _TrustBadgesGrid(),
        16.height,
      ],
    ).paddingOnly(
      left: AppConstants.horizontalPadding,
      top: 16,
      right: AppConstants.horizontalPadding,
    );
  }

  void _showBreakup(BuildContext context, String total) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Breakup', style: AppTextStyles.headlineSmall),
            16.height,
            _BreakupRow('Diamond Price', total),
            const _BreakupRow('Making Charges', 'Included'),
            const _BreakupRow('3% GST', 'Included'),
            const Divider(),
            _BreakupRow('Total', total, bold: true),
            12.height,
          ]).paddingAll(20),
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: s),
      Text(value, style: s),
    ]).paddingSymmetric(vertical: 6);
  }
}

class _TrustBadgesGrid extends StatelessWidget {
  const _TrustBadgesGrid();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const _TrustBadge(
              icon: Icons.verified_outlined,
              label: 'IGI/SGL certified',
              color: AppColors.success),
          8.width,
          const _TrustBadge(
              icon: Icons.workspace_premium_outlined,
              label: 'BIS hallmarked',
              color: AppColors.teal),
          8.width,
          const _TrustBadge(
              icon: Icons.local_shipping_outlined,
              label: 'Free Insured shipping',
              color: AppColors.success),
          8.width,
          const _TrustBadge(
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
        6.width,
        Flexible(
          child: Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textPrimary, fontSize: 11)),
        ),
      ]),
    );
  }
}
