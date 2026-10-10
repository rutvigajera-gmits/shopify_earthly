import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/product_model.dart';

class ProductAccordionsSection extends StatelessWidget {
  final Product product;
  final String sku;
  const ProductAccordionsSection(
      {super.key, required this.product, required this.sku});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Divider(height: 1, color: AppColors.border),
      _AccordionItem(
        title: 'Product Information',
        child: Text(
          product.description?.isNotEmpty == true
              ? product.description!
              : 'Crafted with certified lab-grown diamonds set in premium gold. '
                  'Designed for everyday elegance and long-lasting brilliance.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary, height: 1.7),
        ),
      ),
      const Divider(height: 1, color: AppColors.border),
      _AccordionItem(
        title: 'Payments & Shipping',
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _InfoRow(Icons.credit_card, 'All major credit/debit cards accepted'),
              _InfoRow(Icons.local_shipping_outlined,
                  'Free insured shipping across India'),
              _InfoRow(Icons.replay, '15-day easy returns policy'),
              _InfoRow(Icons.security, 'Secure & encrypted checkout'),
            ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      _AccordionItem(
        title: 'Product Origin & Manufacturer',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (product.vendor?.isNotEmpty == true)
            _SpecRow('Brand', product.vendor!),
          const _SpecRow('Country of Origin', 'India'),
          const _SpecRow('Metal', 'Gold'),
          const _SpecRow('Stone', 'Lab-Grown Diamond'),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      Text.rich(TextSpan(children: [
        TextSpan(
            text: 'SKU : ',
            style:
                AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        TextSpan(
            text: sku,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ])).paddingOnly(
        left: AppConstants.horizontalPadding,
        top: 12,
        right: AppConstants.horizontalPadding,
        bottom: 16,
      ),
    ]);
  }
}

class _AccordionItem extends StatefulWidget {
  final String title;
  final Widget child;
  const _AccordionItem({required this.title, required this.child});

  @override
  State<_AccordionItem> createState() => _AccordionItemState();
}

class _AccordionItemState extends State<_AccordionItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: () => setState(() => _open = !_open),
        behavior: HitTestBehavior.opaque,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title,
                  style: AppTextStyles.labelLarge
                      .copyWith(fontSize: 14, color: AppColors.textPrimary)),
              Icon(_open ? Icons.remove : Icons.add,
                  size: 18, color: AppColors.textPrimary),
            ]).paddingSymmetric(
          horizontal: AppConstants.horizontalPadding,
          vertical: 16,
        ),
      ),
      if (_open)
        widget.child.paddingOnly(
          left: AppConstants.horizontalPadding,
          right: AppConstants.horizontalPadding,
          bottom: 16,
        ),
    ]);
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 120,
        child: Text(label,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      ),
      Expanded(
        child: Text(value,
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ),
    ]).paddingSymmetric(vertical: 4);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      10.width,
      Expanded(
        child: Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ),
    ]).paddingSymmetric(vertical: 5);
  }
}
