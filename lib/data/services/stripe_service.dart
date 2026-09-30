import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/stripe_pay_model.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  static const _timeout = Duration(seconds: 30);

  // DEMO ONLY: Creates a PaymentIntent by calling the Stripe API directly.
  // In production: create the PaymentIntent on your backend server so the
  // secret key is never shipped inside the app binary.
  Future<StripePayModel> _createPaymentIntent({
    required int amountInPaise,
    required String customerEmail,
  }) async {
    final response = await http
        .post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          headers: {
            'Authorization': 'Bearer ${ApiConfig.stripeSecretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'amount': amountInPaise.toString(),
            'currency': ApiConfig.stripeCurrency,
            'receipt_email': customerEmail,
            'automatic_payment_methods[enabled]': 'true',
          },
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to create PaymentIntent (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['error'] != null) {
      final msg = (data['error'] as Map)['message'] as String? ?? 'Stripe API error';
      throw Exception(msg);
    }
    return StripePayModel.fromJson(data);
  }

  /// Presents the Stripe Payment Sheet and returns the Stripe PaymentIntent ID
  /// on success. Throws [StripeException] if the user cancels or payment fails.
  Future<String> pay({
    required double totalAmount,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
  }) async {
    final amountInPaise = (totalAmount * 100).toInt();

    final payModel = await _createPaymentIntent(
      amountInPaise: amountInPaise,
      customerEmail: customerEmail,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: payModel.clientSecret,
        merchantDisplayName: 'Earthly Jewels',
        billingDetails: BillingDetails(
          name: customerName,
          email: customerEmail,
          phone: customerPhone,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return payModel.id;
  }
}
