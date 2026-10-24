import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/customer_model.dart';

class BackendCustomerResult {
  final String shopifyId;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final List<CustomerOrder> orders;
  final List<CustomerAddress> addresses;

  const BackendCustomerResult({
    required this.shopifyId,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.orders,
    required this.addresses,
  });
}

class GoKwikBackendService {
  GoKwikBackendService._();
  static final GoKwikBackendService instance = GoKwikBackendService._();

  static const _timeout = Duration(seconds: 20);

  Future<BackendCustomerResult?> resolveCustomer(String kwiksessiontoken) async {
    if (kwiksessiontoken.isEmpty) return null;
    if (ApiConfig.backendUrl.isEmpty || ApiConfig.backendUrl.contains('TODO')) {
      debugPrint('[GoKwikBackend] backendUrl not configured — skipping');
      return null;
    }
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.backendUrl}/resolve-customer'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'kwiksessiontoken': kwiksessiontoken}),
          )
          .timeout(_timeout);

      debugPrint('[GoKwikBackend] resolveCustomer status=${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[GoKwikBackend] error body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] != null) {
        debugPrint('[GoKwikBackend] API error: ${data['error']}');
        return null;
      }

      final ordersList = (data['orders'] as List? ?? [])
          .map((e) => CustomerOrder.fromStorefrontJson(e as Map<String, dynamic>))
          .toList();

      final addressesList = (data['addresses'] as List? ?? [])
          .map((e) => CustomerAddress.fromStorefrontJson(e as Map<String, dynamic>))
          .toList();

      debugPrint('[GoKwikBackend] resolved: id=${data['shopifyId']} '
          'orders=${ordersList.length} addresses=${addressesList.length}');

      return BackendCustomerResult(
        shopifyId: data['shopifyId'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        orders: ordersList,
        addresses: addressesList,
      );
    } catch (e) {
      debugPrint('[GoKwikBackend] resolveCustomer error: $e');
      return null;
    }
  }
}
