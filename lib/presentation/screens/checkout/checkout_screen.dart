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
import '../../../data/models/customer_model.dart';
import '../../../data/services/shopify_service.dart';
import '../../../data/services/stripe_service.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contact
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _processing = false;
  bool _cardComplete = false;

  // Address management (used when logged in)
  CustomerAddress? _selectedAddress;
  bool _showAddressForm = false; // true = "add new" mode even if addresses exist
  bool _saveAddress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

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

  // ── Pre-fill ──────────────────────────────────────────────────────────────

  void _prefill() {
    final auth = context.read<CustomerProvider>();
    if (!auth.isLoggedIn) return;

    final c = auth.customer!;
    _nameController.text = c.displayName;
    _emailController.text = c.email;
    if (c.phone != null && c.phone!.isNotEmpty) {
      _phoneController.text = c.phone!;
    }

    auth.loadAddresses().then((_) {
      if (!mounted) return;
      final addrs = context.read<CustomerProvider>().addresses;
      if (addrs.isNotEmpty) {
        setState(() {
          _selectedAddress = addrs.first;
          _fillFromAddress(addrs.first);
        });
      }
    });
  }

  void _fillFromAddress(CustomerAddress addr) {
    _addressController.text = addr.address1 ?? '';
    _cityController.text = addr.city ?? '';
    _stateController.text = addr.province ?? '';
    _pincodeController.text = addr.zip ?? '';
    if (addr.phone != null && addr.phone!.isNotEmpty) {
      _phoneController.text = addr.phone!;
    }
    final addrName =
        '${addr.firstName ?? ''} ${addr.lastName ?? ''}'.trim();
    if (addrName.isNotEmpty) _nameController.text = addrName;
  }

  // ── Payment ───────────────────────────────────────────────────────────────

  Future<void> _pay(CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_cardComplete) {
      _showError('Please complete your card details.');
      return;
    }

    setState(() => _processing = true);
    final orderProvider = context.read<OrderProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final navigator = Navigator.of(context);

    try {
      // 1. Tokenise the card entered in the CardField widget.
      final stripeToken = await StripeService.instance
          .createCardToken(cardholderName: _nameController.text.trim());

      // 2. Build the Shopify mailing-address map.
      final nameParts = _nameController.text.trim().split(' ');
      final addressMap = <String, String>{
        'firstName': nameParts.first,
        'lastName':
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'address1': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _stateController.text.trim(),
        'zip': _pincodeController.text.trim(),
        'country': 'India',
        'phone': _phoneController.text.trim(),
      };

      // 3. Create the Shopify checkout (links to customer if logged in).
      final checkout = await ShopifyService.instance.createCheckout(
        lineItems: cartProvider.cart.lines,
        email: _emailController.text.trim(),
        shippingAddress: addressMap,
        customerAccessToken: customerProvider.accessToken,
      );

      // 4. Complete the checkout — Shopify charges via its Stripe gateway.
      String? orderName = await ShopifyService.instance
          .checkoutCompleteWithToken(
        checkoutId: checkout.id,
        amount: checkout.totalPrice.toStringAsFixed(2),
        currencyCode: checkout.currencyCode,
        stripeToken: stripeToken,
        billingAddress: addressMap,
      );

      // 5. Poll until Shopify confirms the order (usually 1–2 retries).
      orderName ??=
          await ShopifyService.instance.pollCheckoutOrder(checkout.id);

      // 6. Optionally persist the new address to the customer's account.
      if (mounted &&
          customerProvider.isLoggedIn &&
          _saveAddress &&
          _showAddressForm) {
        await customerProvider.addAddress(addressMap);
      }

      if (mounted) {
        final addressString =
            '${_addressController.text.trim()}, ${_cityController.text.trim()}, '
            '${_stateController.text.trim()} — ${_pincodeController.text.trim()}';

        orderProvider.setOrder(
          transactionId: orderName ?? checkout.id,
          items: cartProvider.cart.lines,
          total: checkout.totalPrice,
          customerName: _nameController.text.trim(),
          deliveryAddress: addressString,
        );

        // Invalidate so My Orders re-fetches live Shopify data.
        customerProvider.invalidateOrders();
        await cartProvider.clearCart();
        navigator.pushReplacementNamed(AppRoutes.orderConfirmation);
      }
    } on StripeException catch (e) {
      if (mounted) _showError(e.error.localizedMessage ?? 'Card error. Please try again.');
    } catch (e) {
      if (mounted) _showError(FormatUtils.trimException(e));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return AppScaffold(
          backgroundColor: AppColors.background,
          isLoading: _processing,
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
                // Order summary
                Text('Order Summary', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _OrderSummaryCard(cartProvider: cartProvider),
                const SizedBox(height: 28),

                // Contact info
                Text('Contact', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _buildContactFields(),
                const SizedBox(height: 28),

                // Delivery address
                Text('Delivery Address', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _buildAddressSection(),
                const SizedBox(height: 28),

                // Card entry
                Text('Card Details', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _buildCardSection(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          bottomNavigationBar: _PayButton(
            cartProvider: cartProvider,
            processing: _processing,
            cardComplete: _cardComplete,
            onPay: () => _pay(cartProvider),
          ),
        );
      },
    );
  }

  // ── Contact fields ────────────────────────────────────────────────────────

  Widget _buildContactFields() {
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
      ],
    );
  }

  // ── Address section ───────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    return Consumer<CustomerProvider>(
      builder: (_, auth, __) {
        final hasAddresses =
            auth.isLoggedIn && auth.addresses.isNotEmpty;

        if (hasAddresses && !_showAddressForm) {
          // Saved address selected — show tile + change button.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SavedAddressTile(
                address: _selectedAddress ?? auth.addresses.first,
                onChangeTap: () => _openAddressPicker(auth.addresses),
              ),
            ],
          );
        }

        // Manual address form.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAddresses) ...[
              GestureDetector(
                onTap: () => _openAddressPicker(auth.addresses),
                child: Text(
                  '← Use a saved address',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.teal,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _Field(
                label: 'Street Address',
                controller: _addressController,
                validator: _required),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _Field(
                        label: 'City',
                        controller: _cityController,
                        validator: _required)),
                const SizedBox(width: 12),
                Expanded(
                    child: _Field(
                        label: 'State',
                        controller: _stateController,
                        validator: _required)),
              ],
            ),
            const SizedBox(height: 14),
            _Field(
                label: 'Pincode',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                validator: _required),
            if (auth.isLoggedIn) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _saveAddress,
                    activeColor: AppColors.teal,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) =>
                        setState(() => _saveAddress = v ?? false),
                  ),
                  Text('Save address to my account',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  void _openAddressPicker(List<CustomerAddress> addresses) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddressSelectorSheet(
        addresses: addresses,
        selected: _selectedAddress,
        onSelect: (addr) {
          setState(() {
            _selectedAddress = addr;
            _showAddressForm = false;
            _fillFromAddress(addr);
          });
          Navigator.pop(context);
        },
        onAddNew: () {
          setState(() {
            _showAddressForm = true;
            _selectedAddress = null;
            _addressController.clear();
            _cityController.clear();
            _stateController.clear();
            _pincodeController.clear();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Card section ──────────────────────────────────────────────────────────

  Widget _buildCardSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
            color: _cardComplete ? AppColors.teal : AppColors.border,
            width: _cardComplete ? 1.5 : 1),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card_outlined,
                  color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              Text('Enter card details',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          CardField(
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.white,
              filled: true,
            ),
            onCardChanged: (card) =>
                setState(() => _cardComplete = card?.complete ?? false),
          ),
        ],
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ── Saved Address Tile ────────────────────────────────────────────────────────

class _SavedAddressTile extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onChangeTap;
  const _SavedAddressTile(
      {required this.address, required this.onChangeTap});

  @override
  Widget build(BuildContext context) {
    final lines = address.lines;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.teal, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined,
              color: AppColors.teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address.displayName,
                    style: AppTextStyles.labelLarge),
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lines.join(', '),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeTap,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text('Change',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }
}

// ── Address Selector Sheet ────────────────────────────────────────────────────

class _AddressSelectorSheet extends StatelessWidget {
  final List<CustomerAddress> addresses;
  final CustomerAddress? selected;
  final ValueChanged<CustomerAddress> onSelect;
  final VoidCallback onAddNew;

  const _AddressSelectorSheet({
    required this.addresses,
    required this.selected,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Address', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            ...addresses.map((addr) {
              final isSelected = addr.id == selected?.id;
              return GestureDetector(
                onTap: () => onSelect(addr),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.teal : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.teal
                            : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(addr.displayName,
                                style: AppTextStyles.labelMedium),
                            Text(
                              addr.lines.join(', '),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 20),
            GestureDetector(
              onTap: onAddNew,
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text('Add New Address',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
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
                  style:
                      AppTextStyles.priceText.copyWith(color: AppColors.teal),
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
                    : const Icon(Icons.image_not_supported_outlined,
                        size: 20),
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

// ── Shared Form Field ─────────────────────────────────────────────────────────

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
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
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
  final bool cardComplete;
  final VoidCallback onPay;

  const _PayButton({
    required this.cartProvider,
    required this.processing,
    required this.cardComplete,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final canPay = !processing && cardComplete;
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
                onPressed: canPay ? onPay : null,
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
                        style: AppTextStyles.button
                            .copyWith(color: Colors.white),
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
                Text('Secured by Stripe via Shopify',
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
