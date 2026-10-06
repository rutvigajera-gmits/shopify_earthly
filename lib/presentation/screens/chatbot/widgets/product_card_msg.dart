import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/format_utils.dart';
import '../../../../../data/models/product_model.dart';

class ProductCarouselMsg extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onAddToCart;

  const ProductCarouselMsg({
    super.key,
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
      child: SizedBox(
        height: 232,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          padding: const EdgeInsets.only(right: 16),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _ProductCard(
            product: products[i],
            onAddToCart: onAddToCart,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product> onAddToCart;

  const _ProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.primaryImage?.url ?? '';
    final price = FormatUtils.formatPrice(
        double.tryParse(product.minPrice) ?? 0);

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.product, arguments: product.handle),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.chatBubbleBot,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: product.availableForSale
                      ? () => onAddToCart(product)
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: product.availableForSale
                        ? AppColors.teal
                        : AppColors.neutral200,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    product.availableForSale ? '+ Add to Cart' : 'Out of Stock',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const ColoredBox(
        color: AppColors.neutral200,
        child: Center(
            child: Icon(Icons.diamond_outlined,
                color: AppColors.neutral300, size: 32)),
      );
}
