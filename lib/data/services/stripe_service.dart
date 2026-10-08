import 'dart:convert';
import 'dart:io';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  /// Creates a Stripe card vault token (tok_xxxx) from the card details
  /// currently entered in the [CardField] widget on screen.
  ///
  /// The token is passed to Shopify's
  /// `checkoutCompleteWithTokenizedPaymentV3` mutation so Shopify can
  /// charge the card via its configured Stripe gateway.
  Future<String> createCardToken({required String cardholderName}) async {
    final token = await Stripe.instance.createToken(
      CreateTokenParams.card(
        params: CardTokenParams(
          type: TokenType.Card,
          name: cardholderName,
        ),
      ),
    );
    if (token.id.isEmpty) throw Exception('Failed to tokenise card.');
    return token.id; // tok_xxxx
  }

  /// Creates a Stripe card vault token via the Stripe REST API using raw card
  /// details entered in a custom card UI (no CardField widget required).
  Future<String> createCardTokenFromDetails({
    required String number,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/tokens'),
      headers: {
        'Authorization': 'Bearer ${ApiConfig.stripePublishableKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'card[number]': number,
        'card[exp_month]': expMonth.toString(),
        'card[exp_year]': expYear.toString(),
        'card[cvc]': cvc,
        'card[name]': name,
      },
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final msg = ((body?['error'] as Map?)?['message'] as String?) ??
          'Card tokenization failed';
      throw Exception(msg);
    }
    final token =
        (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String?;
    if (token == null || token.isEmpty) throw Exception('Failed to tokenise card.');
    return token;
  }

  /// Call once from main() after setting [Stripe.publishableKey].
  static Future<void> applySettings() async {
    Stripe.merchantIdentifier = 'merchant.com.earthlyjewels';
    if (Platform.isAndroid) {
      // Google Pay — live environment; set testEnv: true for Stripe test keys.
      // Configured in checkout_screen via CardField; no extra setup needed here.
    }
    await Stripe.instance.applySettings();
  }
}
