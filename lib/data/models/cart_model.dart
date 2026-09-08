class CartLineItem {
  final String lineId;
  final String variantId;
  final String productId;
  final String productTitle;
  final String variantTitle;
  final String imageUrl;
  final int quantity;
  final double price;

  const CartLineItem({
    required this.lineId,
    required this.variantId,
    required this.productId,
    required this.productTitle,
    required this.variantTitle,
    required this.imageUrl,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => price * quantity;

  String get formattedPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₹$formatted';
  }

  String get formattedLineTotal {
    final formatted = lineTotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₹$formatted';
  }

  CartLineItem copyWith({int? quantity}) {
    return CartLineItem(
      lineId: lineId,
      variantId: variantId,
      productId: productId,
      productTitle: productTitle,
      variantTitle: variantTitle,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      price: price,
    );
  }

  factory CartLineItem.fromStorefrontJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;
    final merchandise = node['merchandise'] ?? {};
    final priceV2 = node['estimatedCost']?['totalAmount'] ??
        merchandise['priceV2'] ??
        {'amount': '0'};

    final qty = node['quantity'] as int? ?? 1;
    final totalAmount = double.tryParse(priceV2['amount'] as String? ?? '0') ?? 0;

    return CartLineItem(
      lineId: node['id'] as String? ?? '',
      variantId: merchandise['id'] as String? ?? '',
      productId: merchandise['product']?['id'] as String? ?? '',
      productTitle: merchandise['product']?['title'] as String? ?? '',
      variantTitle: merchandise['title'] as String? ?? '',
      imageUrl: merchandise['image']?['url'] as String? ?? '',
      quantity: qty,
      price: qty > 0 ? totalAmount / qty : totalAmount,
    );
  }
}

class Cart {
  final String? id;
  final String? checkoutUrl;
  final List<CartLineItem> lines;
  final double subtotal;

  const Cart({
    this.id,
    this.checkoutUrl,
    this.lines = const [],
    this.subtotal = 0,
  });

  int get totalQuantity => lines.fold(0, (sum, item) => sum + item.quantity);

  String get formattedSubtotal {
    final formatted = subtotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₹$formatted';
  }

  Cart copyWith({
    String? id,
    String? checkoutUrl,
    List<CartLineItem>? lines,
    double? subtotal,
  }) {
    return Cart(
      id: id ?? this.id,
      checkoutUrl: checkoutUrl ?? this.checkoutUrl,
      lines: lines ?? this.lines,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  factory Cart.fromStorefrontJson(Map<String, dynamic> json) {
    final cartData = json['cart'] ?? json;

    List<CartLineItem> lines = [];
    final linesData = cartData['lines'];
    if (linesData is Map && linesData['edges'] is List) {
      lines = (linesData['edges'] as List)
          .map((e) => CartLineItem.fromStorefrontJson(e as Map<String, dynamic>))
          .toList();
    }

    final cost = cartData['estimatedCost'] ?? cartData['cost'] ?? {};
    final subtotalAmount = cost['subtotalAmount'] ?? cost['totalAmount'] ?? {};
    final subtotal = double.tryParse(
          subtotalAmount['amount'] as String? ?? '0',
        ) ??
        0;

    return Cart(
      id: cartData['id'] as String?,
      checkoutUrl: cartData['checkoutUrl'] as String?,
      lines: lines,
      subtotal: subtotal,
    );
  }
}
