import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_strings.dart';
import '../models/cart_model.dart';
import '../models/customer_model.dart';

class LocalOrderService {
  const LocalOrderService._();
  static const LocalOrderService instance = LocalOrderService._();

  Future<void> saveOrder({
    required String transactionId,
    required List<CartLineItem> items,
    required double total,
    required String currencyCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(AppStrings.localOrdersKey) ?? [];

    final shortId = transactionId.length > 8
        ? transactionId.substring(transactionId.length - 8).toUpperCase()
        : transactionId.toUpperCase();

    final order = CustomerOrder(
      id: 'local_$transactionId',
      name: '#STR-$shortId',
      orderNumber: 0,
      fulfillmentStatus: 'UNFULFILLED',
      financialStatus: 'PAID',
      totalPrice: total,
      currencyCode: currencyCode,
      processedAt: DateTime.now(),
      lineItems: items
          .map((item) => OrderLineItem(
                title: item.productTitle,
                quantity: item.quantity,
                variantTitle: item.variantTitle.isNotEmpty &&
                        item.variantTitle != 'Default Title'
                    ? item.variantTitle
                    : null,
                imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
                price: item.price,
                currencyCode: currencyCode,
              ))
          .toList(),
    );

    existing.insert(0, jsonEncode(order.toJson()));
    await prefs.setStringList(AppStrings.localOrdersKey, existing);
  }

  Future<List<CustomerOrder>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(AppStrings.localOrdersKey) ?? [];
    return stored
        .map((s) {
          try {
            return CustomerOrder.fromLocalJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<CustomerOrder>()
        .toList();
  }
}
