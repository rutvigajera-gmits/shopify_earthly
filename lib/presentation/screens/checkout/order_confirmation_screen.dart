import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/cart_model.dart';
import '../../providers/order_provider.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, order, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Success header ──────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: AppColors.teal, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text('Order Placed!',
                            style: AppTextStyles.displaySmall
                                .copyWith(color: AppColors.teal)),
                        const SizedBox(height: 6),
                        Text(
                          'Thank you, ${order.customerName.split(' ').first}!',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your jewellery is being prepared.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Order meta card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Transaction ID',
                          value: order.transactionId ?? '—',
                        ),
                        const Divider(height: 20),
                        const _InfoRow(
                          label: 'Estimated Delivery',
                          value: '7–10 Business Days',
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          label: 'Total Paid',
                          value: FormatUtils.formatPrice(order.total),
                          valueColor: AppColors.teal,
                        ),
                      ],
                    ),
                  ),

                  // ── Items ordered ───────────────────────────────────────
                  const SizedBox(height: 28),
                  Text('Items Ordered', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 12),
                  Container(
                    decoration:
                        BoxDecoration(border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        for (int i = 0; i < order.items.length; i++) ...[
                          _ConfirmationItem(item: order.items[i]),
                          if (i < order.items.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),

                  // ── Delivery address ────────────────────────────────────
                  if (order.deliveryAddress.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('Delivery Address',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName,
                              style: AppTextStyles.labelLarge),
                          const SizedBox(height: 4),
                          Text(order.deliveryAddress,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Continue Shopping ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        'CONTINUE SHOPPING',
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Confirmation Item ─────────────────────────────────────────────────────────

class _ConfirmationItem extends StatelessWidget {
  final CartLineItem item;
  const _ConfirmationItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            color: AppColors.cardBackground,
            child: item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 20),
                  )
                : const Icon(Icons.image_not_supported_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productTitle,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.variantTitle.isNotEmpty &&
                    item.variantTitle != 'Default Title')
                  Text(item.variantTitle, style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Text(
                  'Qty ${item.quantity}  ·  ${item.formattedLineTotal}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
