/// Base exception for all app-level errors.
/// Carry a human-readable [message] and an optional machine-readable [code].
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Shopify Storefront API returned a GraphQL or HTTP error.
class ShopifyException extends AppException {
  const ShopifyException(super.message, {super.code});
}

/// Network-level failure (no internet, timeout, DNS).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Authentication error (expired token, wrong credentials, 401).
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Stripe payment failure (card declined, user cancelled, etc.).
class PaymentException extends AppException {
  const PaymentException(super.message, {super.code});
}
