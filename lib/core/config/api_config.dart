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
  // Replace with the live key (pk_live_...) from the Earthly Jewels Stripe account.
  // The Stripe account here must match the one configured as the payment gateway
  // in the Shopify admin (Settings → Payments → Stripe).
  // The secret key is no longer needed in the app — Shopify uses it server-side.
  static const String stripePublishableKey = 'pk_live_REPLACE_WITH_EARTHLY_JEWELS_LIVE_KEY';
  static const String stripeCurrency = 'inr';
}
