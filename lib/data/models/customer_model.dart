class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  factory Customer.fromStorefrontJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class OrderLineItem {
  final String title;
  final int quantity;
  final String? variantTitle;
  final String? imageUrl;
  final double price;
  final String currencyCode;

  const OrderLineItem({
    required this.title,
    required this.quantity,
    this.variantTitle,
    this.imageUrl,
    required this.price,
    required this.currencyCode,
  });

  factory OrderLineItem.fromStorefrontJson(Map<String, dynamic> json) {
    final variant = json['variant'] as Map<String, dynamic>?;
    final priceObj = variant?['price'] as Map<String, dynamic>?;
    return OrderLineItem(
      title: json['title'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variantTitle: variant?['title'] as String?,
      imageUrl: (variant?['image'] as Map?)?['url'] as String?,
      price: double.tryParse(priceObj?['amount'] as String? ?? '0') ?? 0,
      currencyCode: priceObj?['currencyCode'] as String? ?? 'INR',
    );
  }

  String get formattedPrice {
    final symbol = currencyCode == 'INR' ? '₹' : currencyCode;
    return '$symbol${price.toStringAsFixed(0)}';
  }
}

class CustomerOrder {
  final String id;
  final String name;
  final int orderNumber;
  final String fulfillmentStatus;
  final String financialStatus;
  final double totalPrice;
  final String currencyCode;
  final DateTime processedAt;
  final List<OrderLineItem> lineItems;

  const CustomerOrder({
    required this.id,
    required this.name,
    required this.orderNumber,
    required this.fulfillmentStatus,
    required this.financialStatus,
    required this.totalPrice,
    required this.currencyCode,
    required this.processedAt,
    required this.lineItems,
  });

  factory CustomerOrder.fromStorefrontJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;
    final totalPriceObj = node['totalPrice'] as Map<String, dynamic>?;

    DateTime processedAt = DateTime.now();
    try {
      processedAt = DateTime.parse(node['processedAt'] as String? ?? '');
    } catch (_) {}

    final lineEdges = (node['lineItems']?['edges'] as List?) ?? [];
    final lineItems = lineEdges
        .map((e) =>
            OrderLineItem.fromStorefrontJson(e['node'] as Map<String, dynamic>))
        .toList();

    return CustomerOrder(
      id: node['id'] as String? ?? '',
      name: node['name'] as String? ?? '',
      orderNumber: (node['orderNumber'] as num?)?.toInt() ?? 0,
      fulfillmentStatus: node['fulfillmentStatus'] as String? ?? '',
      financialStatus: node['financialStatus'] as String? ?? '',
      totalPrice:
          double.tryParse(totalPriceObj?['amount'] as String? ?? '0') ?? 0,
      currencyCode: totalPriceObj?['currencyCode'] as String? ?? 'INR',
      processedAt: processedAt,
      lineItems: lineItems,
    );
  }

  String get formattedTotal {
    final symbol = currencyCode == 'INR' ? '₹' : currencyCode;
    return '$symbol${totalPrice.toStringAsFixed(0)}';
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${processedAt.day} ${months[processedAt.month - 1]} ${processedAt.year}';
  }

  String get displayFulfillmentStatus {
    switch (fulfillmentStatus.toUpperCase()) {
      case 'FULFILLED':
        return 'Delivered';
      case 'PARTIALLY_FULFILLED':
        return 'Partially Delivered';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'UNFULFILLED':
        return 'Processing';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'ON_HOLD':
        return 'On Hold';
      default:
        return fulfillmentStatus.isNotEmpty ? fulfillmentStatus : 'Pending';
    }
  }

  bool get isDelivered => fulfillmentStatus.toUpperCase() == 'FULFILLED';
}
