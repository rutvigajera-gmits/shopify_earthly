import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/providers/customer_provider.dart';
import '../../widgets/app_header.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(showBack: true, title: 'My Orders'),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (_, auth, __) {
                if (auth.ordersLoading) {
                  return _OrdersShimmer();
                }
                if (auth.orders.isEmpty) {
                  return _EmptyOrders();
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: auth.orders.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) => _OrderCard(order: auth.orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final CustomerOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final firstItem =
        order.lineItems.isNotEmpty ? order.lineItems.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
        vertical: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          _Thumbnail(imageUrl: firstItem?.imageUrl),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.name,
                        style: AppTextStyles.labelLarge),
                    Text(order.formattedTotal,
                        style: AppTextStyles.labelLarge),
                  ],
                ),
                const SizedBox(height: 4),
                Text(order.formattedDate,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),

                // Items summary
                if (order.lineItems.isNotEmpty) ...[
                  Text(
                    order.lineItems
                        .map((i) =>
                            '${i.title}${i.variantTitle != null && i.variantTitle != 'Default Title' ? ' — ${i.variantTitle}' : ''} ×${i.quantity}')
                        .join(', '),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Status badge
                _StatusBadge(order: order),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? imageUrl;
  const _Thumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.cardBackground,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.image_outlined,
                      color: AppColors.textLight, size: 28),
            )
          : const Icon(Icons.shopping_bag_outlined,
              color: AppColors.textLight, size: 28),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CustomerOrder order;
  const _StatusBadge({required this.order});

  Color get _color {
    switch (order.fulfillmentStatus.toUpperCase()) {
      case 'FULFILLED':
        return const Color(0xFF2E7D32);
      case 'PARTIALLY_FULFILLED':
        return const Color(0xFF1565C0);
      case 'UNFULFILLED':
        return const Color(0xFFE65100);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        order.displayFulfillmentStatus,
        style: AppTextStyles.labelSmall.copyWith(color: _color),
      ),
    );
  }
}

// ─── Empty & Loading states ───────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 56, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('No orders yet', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Your order history will appear here.',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _OrdersShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: 5,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                  width: 72, height: 72, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 120,
                        color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 80,
                        color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
