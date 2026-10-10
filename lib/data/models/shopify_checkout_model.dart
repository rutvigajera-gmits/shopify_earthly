class ShopifyCheckout {
  final String id;
  final String webUrl;
  final double totalPrice;
  final String currencyCode;
  final String? orderName;

  const ShopifyCheckout({
    required this.id,
    required this.webUrl,
    required this.totalPrice,
    required this.currencyCode,
    this.orderName,
  });

  factory ShopifyCheckout.fromCreateJson(Map<String, dynamic> json) {
    final checkout = json['checkout'] as Map<String, dynamic>? ?? json;
    final price = checkout['totalPriceV2'] as Map<String, dynamic>? ?? {};
    return ShopifyCheckout(
      id: checkout['id'] as String? ?? '',
      webUrl: checkout['webUrl'] as String? ?? '',
      totalPrice: double.tryParse(price['amount'] as String? ?? '0') ?? 0,
      currencyCode: price['currencyCode'] as String? ?? 'INR',
    );
  }

  // Parses the cartCreate mutation response (Storefront API 2022-10+).
  factory ShopifyCheckout.fromCartJson(Map<String, dynamic> json) {
    final cart = json['cart'] as Map<String, dynamic>? ?? json;
    final total = (cart['cost'] as Map?)?['totalAmount'] as Map? ?? {};
    return ShopifyCheckout(
      id: cart['id'] as String? ?? '',
      webUrl: cart['checkoutUrl'] as String? ?? '',
      totalPrice: double.tryParse(total['amount'] as String? ?? '0') ?? 0,
      currencyCode: total['currencyCode'] as String? ?? 'INR',
    );
  }

  factory ShopifyCheckout.fromCompleteJson(Map<String, dynamic> json) {
    final checkout = json['checkout'] as Map<String, dynamic>? ?? json;
    final price = checkout['totalPriceV2'] as Map<String, dynamic>? ?? {};
    final orderName = (checkout['order'] as Map?)?['name'] as String?;
    return ShopifyCheckout(
      id: checkout['id'] as String? ?? '',
      webUrl: checkout['webUrl'] as String? ?? '',
      totalPrice: double.tryParse(price['amount'] as String? ?? '0') ?? 0,
      currencyCode: price['currencyCode'] as String? ?? 'INR',
      orderName: orderName,
    );
  }
}
