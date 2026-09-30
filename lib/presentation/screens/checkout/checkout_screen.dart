import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/order_provider.dart';
import '../../../data/services/stripe_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pay(CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);
    try {
      final transactionId = await StripeService.instance.pay(
        totalAmount: cartProvider.cart.subtotal,
        customerEmail: _emailController.text.trim(),
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
      );

      final address =
          '${_addressController.text.trim()}, ${_cityController.text.trim()}, '
          '${_stateController.text.trim()} — ${_pincodeController.text.trim()}';

      if (mounted) {
        context.read<OrderProvider>().setOrder(
              transactionId: transactionId,
              items: cartProvider.cart.lines,
              total: cartProvider.cart.subtotal,
              customerName: _nameController.text.trim(),
              deliveryAddress: address,
            );
        cartProvider.clearCart();
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.orderConfirmation);
      }
    } on StripeException catch (e) {
      if (mounted && e.error.code != FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e.error.localizedMessage ?? 'Payment failed. Try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(FormatUtils.trimException(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(),
        ));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text('Checkout', style: AppTextStyles.headlineSmall),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18),
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.textPrimary,
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.horizontalPadding),
              children: [
                Text('Order Summary', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _OrderSummaryCard(cartProvider: cartProvider),
                const SizedBox(height: 28),
                Text('Delivery Address', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _buildAddressForm(),
                const SizedBox(height: 28),
                Text('Payment Method', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                const _PaymentMethodTile(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          bottomNavigationBar: _PayButton(
            cartProvider: cartProvider,
            processing: _processing,
            onPay: () => _pay(cartProvider),
          ),
        );
      },
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
        _Field(
          label: 'Full Name',
          controller: _nameController,
          validator: _required,
        ),
        const SizedBox(height: 14),
        _Field(
          label: 'Email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _Field(
          label: 'Phone',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: _required,
        ),
        const SizedBox(height: 14),
        _Field(
          label: 'Address',
          controller: _addressController,
          validator: _required,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'City',
                controller: _cityController,
                validator: _required,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'State',
                controller: _stateController,
                validator: _required,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Field(
          label: 'Pincode',
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          validator: _required,
        ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ── Order Summary Card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  final CartProvider cartProvider;
  const _OrderSummaryCard({required this.cartProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          ...cartProvider.cart.lines
              .map((item) => _OrderItemRow(item: item, showDivider: true)),
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: AppTextStyles.labelLarge
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(
                  cartProvider.cart.formattedSubtotal,
                  style: AppTextStyles.priceText
                      .copyWith(color: AppColors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartLineItem item;
  final bool showDivider;
  const _OrderItemRow({required this.item, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
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
                      Text(item.variantTitle,
                          style: AppTextStyles.bodySmall),
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
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

// ── Payment Method Tile ───────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.teal, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_outlined,
              color: AppColors.teal, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Credit / Debit Card',
                  style: AppTextStyles.labelLarge),
              Text('Powered by Stripe',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
          const Spacer(),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: AppColors.teal, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ── Form Field ────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// ── Pay Button ────────────────────────────────────────────────────────────────

class _PayButton extends StatelessWidget {
  final CartProvider cartProvider;
  final bool processing;
  final VoidCallback onPay;

  const _PayButton({
    required this.cartProvider,
    required this.processing,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppConstants.horizontalPadding, 12,
            AppConstants.horizontalPadding, 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: processing ? null : onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.neutral300,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                child: processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'PAY  ${cartProvider.cart.formattedSubtotal}',
                        style:
                            AppTextStyles.button.copyWith(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Secured by Stripe',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
