import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

/// Centralised HTTP client for all Shopify Storefront GraphQL requests.
/// Both [ShopifyService] and [StorefrontHomeService] delegate here so the
/// transport logic lives in one place — mirroring the network_utils pattern.
class ShopifyClient {
  ShopifyClient._();
  static final ShopifyClient instance = ShopifyClient._();

  static const _timeout = Duration(seconds: 30);

  static const _headers = {
    'Content-Type': 'application/json',
    'X-Shopify-Storefront-Access-Token': ApiConfig.storefrontAccessToken,
  };

  /// Executes a GraphQL query and returns the `data` map.
  /// Throws an [Exception] on HTTP errors or GraphQL errors.
  Future<Map<String, dynamic>> query(String gql) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.storefrontApiUrl),
          headers: _headers,
          body: jsonEncode({'query': gql}),
        )
        .timeout(_timeout);

    _log(response);

    if (response.statusCode != 200) {
      throw Exception('Shopify API ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['errors'] != null) {
      throw Exception('GraphQL: ${body['errors']}');
    }
    return body['data'] as Map<String, dynamic>;
  }

  /// Same as [query] but swallows all errors and returns an empty map.
  /// Used by home-screen parallel fetches where a single failing section
  /// should not abort the entire page load.
  Future<Map<String, dynamic>> safeQuery(String gql) async {
    try {
      return await query(gql);
    } catch (e) {
      debugPrint('[ShopifyClient] safeQuery error: $e');
      return {};
    }
  }

  void _log(http.Response res) {
    if (!kDebugMode) return;
    debugPrint(
        '┌─── Shopify GraphQL ─────────────────────────────────────────────');
    debugPrint('│ Status : ${res.statusCode}');
    if (res.statusCode != 200) {
      final snippet = res.body.substring(0, res.body.length.clamp(0, 300));
      debugPrint('│ Body   : $snippet');
    }
    debugPrint(
        '└────────────────────────────────────────────────────────────────');
  }
}
