import 'dart:io';
import 'package:flutter_stripe/flutter_stripe.dart';

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
