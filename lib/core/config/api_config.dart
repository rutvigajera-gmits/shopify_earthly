import 'api_secrets.dart';

class ApiConfig {
  ApiConfig._();

  static const String shopDomain = 'earthlyjewels.co';
  static const String storefrontApiVersion = '2026-07';
  static const String storefrontApiUrl =
      'https://$shopDomain/api/$storefrontApiVersion/graphql.json';

  // Public storefront token — safe to commit (read-only, no admin access).
  static const String storefrontAccessToken = 'f0a6b56aed212f4ea6a306e9909e3fac';

  // Judge.me public read-only token — safe to commit.
  static const String judgeMePublicToken = '1lo-Qc8pmxTOpzmH2b36IiheWrg';
  static const String judgeMeShopDomain = 'gold-rate-update.myshopify.com';

  // Stripe publishable key — public-facing, safe to commit.
  static const String stripePublishableKey = 'pk_live_REPLACE_WITH_EARTHLY_JEWELS_LIVE_KEY';
  static const String stripeCurrency = 'inr';

  // Groq — key lives in api_secrets.dart (gitignored), never committed.
  static const String groqApiKey = ApiSecrets.groqApiKey;
  static const String groqModel = 'openai/gpt-oss-20b';
}
