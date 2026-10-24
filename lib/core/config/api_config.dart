import 'api_secrets.dart';

const APP_NAME = 'Ubukule - Provider';
const DEFAULT_LANGUAGE = 'en';

class ApiConfig {
  ApiConfig._();

  static const String shopDomain = 'earthlyjewels.co';
  static const String storefrontApiVersion = '2026-07';
  static const String storefrontApiUrl =
      'https://$shopDomain/api/$storefrontApiVersion/graphql.json';

  // Public storefront token — safe to commit (read-only, no admin access).
  static const String storefrontAccessToken =
      'f0a6b56aed212f4ea6a306e9909e3fac';

  // Backend proxy URL for the GoKwik ↔ Shopify Admin API bridge.
  // Deploy tools/backend/ and replace the placeholder with the live URL.
  // Example: 'https://your-project.cloudfunctions.net'
  static const String backendUrl =
      'https://TODO-replace-with-your-backend-url.com';

  // Judge.me public read-only token — safe to commit.
  static const String judgeMePublicToken = '1lo-Qc8pmxTOpzmH2b36IiheWrg';
  static const String judgeMeShopDomain = 'gold-rate-update.myshopify.com';

  // Stripe publishable key — public-facing, safe to commit.
  static const String stripePublishableKey =
      'pk_live_REPLACE_WITH_EARTHLY_JEWELS_LIVE_KEY';
  static const String stripeCurrency = 'inr';

  // Groq — key lives in api_secrets.dart (gitignored), never committed.
  static const String groqApiKey = ApiSecrets.groqApiKey;
  static const String groqModel = 'openai/gpt-oss-20b';
}

// Virtual Try-On (vtryon.earthlyjewels.co) configuration.
// Once you find the metafield in Shopify Admin → Products → [any product] →
// Metafields, update metafieldNamespace and metafieldKey below.
// Also ensure the metafield is exposed to the Storefront API (Admin →
// Settings → Custom data → Storefronts → enable the metafield).
class VTryOnConfig {
  VTryOnConfig._();

  static const String baseUrl = 'https://vtryon.earthlyjewels.co/';
  // The internal myshopify.com domain shown in the try-on URL's ?shop= param.
  static const String shopDomain = 'y7srws-f4.myshopify.com';
  // VTryOn's own API endpoint (confirmed from vtryon-storefront.js page script).
  // vtryon-storefront.js calls this to resolve a product's selectionId at page load.
  static const String tryOnApiUrl =
      'https://vtryon.earthlyjewels.co/api/tryon/selection';
  // ── Update these after finding the metafield in Shopify Admin ──────────────
  static const String metafieldNamespace = 'custom';
  static const String metafieldKey = 'vtryon_selection_id';
}

// GoKwik KwikPass configuration.
class GoKwikConfig {
  GoKwikConfig._();

  static String get merchantId => ApiSecrets.goKwikMerchantId;

  // KwikPass is a JS widget injected into the Shopify storefront — it has no
  // standalone hosted URL. We open the live store's account/login page in a
  // WebView so GoKwik's scripts run exactly as they do on the website.
  // After OTP verification the URL changes to /account; we then inject JS
  // to extract the Shopify customerAccessToken GoKwik stored.
  static const String loginUrl = 'https://earthlyjewels.co/account/login';

  // Paths that indicate a successful post-login redirect.
  static const List<String> postLoginPaths = ['/account', '/'];
}
