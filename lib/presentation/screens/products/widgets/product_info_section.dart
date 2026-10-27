import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../component/loader_widget.dart';
import '../../simple_web_screen.dart';
import '../../../../core/config/api_config.dart';
import '../../../../data/services/shopify_service.dart';
import '../../../../data/services/secure_storage_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../data/models/product_model.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/review_provider.dart';

class ProductInfoSection extends StatelessWidget {
  final Product product;
  final ProductVariant? selectedVariant;

  const ProductInfoSection(
      {super.key, required this.product, required this.selectedVariant});

  @override
  Widget build(BuildContext context) {
    final price = selectedVariant != null
        ? FormatUtils.formatRsPrice(selectedVariant!.price)
        : product.formattedMinPrice;
    final compareAt = selectedVariant?.hasDiscount == true
        ? FormatUtils.formatRsPrice(selectedVariant!.compareAtPrice!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.title, style: AppTextStyles.displaySmall),
        12.height,

        // Price row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(price,
                style:
                    AppTextStyles.priceLarge.copyWith(color: AppColors.teal)),
            if (compareAt != null) ...[
              8.width,
              Text(compareAt, style: AppTextStyles.priceStrikethrough),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => _showBreakup(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('+ Price Breakup',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
        4.height,
        Text('MRP Incl. of all taxes',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        10.height,

        // Star rating
        Consumer<ReviewProvider>(builder: (context, rp, _) {
          final summary = rp.productReviews(product.handle);
          if (summary == null || summary.totalCount == 0) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              ...List.generate(5, (i) {
                final r = summary.averageRating;
                return Icon(
                  i < r.floor()
                      ? Icons.star
                      : (i < r ? Icons.star_half : Icons.star_border),
                  size: 18,
                  color: AppColors.gold,
                );
              }),
              6.width,
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(AppStrings.reviewsUrl);
                  if (await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  '${summary.averageRating.toStringAsFixed(1)} / 5  (Google Reviews)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.teal,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ).paddingOnly(bottom: 10);
        }),

        // Virtual Try-On
        Builder(builder: (ctx) {
          final sku = selectedVariant?.sku ?? '';
          final slug = sku.contains('-') ? sku.split('-').first : sku;
          final carat = _extractCarat(selectedVariant);

          return GestureDetector(
            onTap: () async {
              final auth = ctx.read<CustomerProvider>();
              if (auth.customer == null) {
                toast('Please sign in to use Virtual Try-On', bgColor: AppColors.textLight.withValues(alpha: 0.9));
                return;
              }

              // Read customer ID at tap time so it's always current.
              final customerId = auth.customer?.id ?? '';
              var numericId = customerId.contains('/')
                  ? customerId.split('/').last
                  : customerId;

              var selectionId = product.vtryonSelectionId ?? '';

              final prefs = await SharedPreferences.getInstance();

              // Check SharedPreferences cache populated by the JS intercept
              // on a previous VTryOn session for this product.
              if (selectionId.isEmpty) {
                selectionId =
                    prefs.getString(SimpleWebScreen.prefKey(product.handle)) ??
                        '';
                if (kDebugMode && selectionId.isNotEmpty) {
                  debugPrint('[VTryOn] selectionId from cache: $selectionId');
                }
              }

              // Supplement numericId from the globally cached userId.
              // Only use if it's a Shopify numeric ID — reject stale GoKwik UUIDs.
              if (numericId.isEmpty) {
                final cached = await SecureStorageService.instance.read('vtryon_shopify_user_id') ?? '';
                if (RegExp(r'^\d{8,}$').hasMatch(cached)) numericId = cached;
              }

              // Read Shopify session cookies from the WebView store.
              // Used for both numericId resolution and authenticating HTTP scrape.
              String cookieHeader = '';
              try {
                final shopifyCookies = await CookieManager.instance()
                    .getCookies(url: WebUri('https://earthlyjewels.co'));
                cookieHeader = shopifyCookies
                    .where((c) => c.value != null &&
                        (c.value?.isNotEmpty ?? false))
                    .map((c) => '${c.name}=${c.value}')
                    .join('; ');

                if (numericId.isEmpty) {
                  for (final c in shopifyCookies) {
                    if (c.name == 'kp_user_id') {
                      final val = c.value?.toString() ?? '';
                      debugPrint('[VTryOn] kp_user_id raw="${val.isEmpty ? "(empty)" : val}"');
                      if (val.isNotEmpty && RegExp(r'^\d{8,}$').hasMatch(val)) {
                        numericId = val;
                        await SecureStorageService.instance.write('vtryon_shopify_user_id', numericId);
                        if (kDebugMode) debugPrint('[VTryOn] numericId from kp_user_id: $numericId');
                        break;
                      }
                    }
                  }
                }
              } catch (_) {}

              // Final fallback: fetch customer ID from /account.json using the
              // Shopify session cookies. Handles KwikPass sessions where the OTP
              // JS flow couldn't extract a numeric Shopify customer ID.
              if (numericId.isEmpty && cookieHeader.isNotEmpty) {
                try {
                  final fetchedId = await ShopifyService.instance
                      .fetchCustomerIdWithCookies(cookieHeader);
                  if (fetchedId != null && fetchedId.isNotEmpty) {
                    numericId = fetchedId;
                    await SecureStorageService.instance.write('vtryon_shopify_user_id', numericId);
                    if (kDebugMode) debugPrint('[VTryOn] numericId from account.json: $numericId');
                  }
                } catch (_) {}
              }

              if (kDebugMode) {
                debugPrint('[VTryOn] tap — handle=${product.handle} selectionId=$selectionId numericId=$numericId');
              }

              final originalImageUrl = product.primaryImage?.url ?? '';
              final cdnUrl = ShopifyService.vtryonCdnUrl(originalImageUrl);
              if (kDebugMode) debugPrint('[VTryOn] imageUrl=$originalImageUrl cdnUrl=$cdnUrl');

              // Ensure OS-level camera permission before opening WebView.
              final status = await Permission.camera.request();
              if (status.isPermanentlyDenied) {
                if (ctx.mounted) openAppSettings();
                return;
              }

              // Always re-fetch the selectionId when we have a user ID so the
              // POST includes product_type — required for VTryOn to set
              // photoGroup="HAND" for rings. Without it, try-on shows "not
              // supported". VTryOn returns fast (cached) if the CDN URL is known.
              if (numericId.isNotEmpty) {
                final sid = await ShopifyService.instance
                    .scrapeVTryOnSelectionId(
                      product.handle,
                      sku: sku,
                      imageUrl: originalImageUrl,
                      customerId: numericId,
                      productTitle: product.title,
                      productType: product.productType ?? '',
                    )
                    .catchError((_) => null as String?);
                if (sid != null && sid.isNotEmpty) {
                  selectionId = sid;
                  await prefs.setString(
                      SimpleWebScreen.prefKey(product.handle), sid);
                  if (kDebugMode) debugPrint('[VTryOn] scrape found: $sid');
                }
              }

              if (kDebugMode) {
                debugPrint('[VTryOn] selectionId=$selectionId numericId=$numericId');
              }
              // Confirmed URL format from live site DevTools inspection:
              // ?selectionId=UUID&variantSku=SKU&variantSlug=SLUG&variantCarat=CARAT
              //   &shop=y7srws-f4.myshopify.com&user_id=NUMERIC_ID
              final params = <String, String>{
                'shop': VTryOnConfig.shopDomain,
                if (selectionId.isNotEmpty) 'selectionId': selectionId,
                if (sku.isNotEmpty) 'variantSku': sku,
                if (slug.isNotEmpty) 'variantSlug': slug,
                if (carat.isNotEmpty) 'variantCarat': carat,
                if (numericId.isNotEmpty) 'user_id': numericId,
              };
              final tryOnUrl = Uri.parse(VTryOnConfig.baseUrl)
                  .replace(queryParameters: params)
                  .toString();
              if (kDebugMode) debugPrint('[VTryOn] opening url   : $tryOnUrl');

              if (!ctx.mounted) return;
              Navigator.of(ctx).push(MaterialPageRoute(
                builder: (_) => SimpleWebScreen(
                  title: 'Virtual Try-On',
                  url: tryOnUrl,
                  vtryonProductHandle: product.handle,
                  vtryonCdnUrl: cdnUrl,
                ),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 22),
                  12.width,
                  Text('Virtual Try-On',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      color: Colors.white, size: 22),
                ],
              ),
            ),
          );
        }),
        14.height,

        // Trust badges — horizontal scroll
        const _TrustBadgesGrid(),
        16.height,
      ],
    ).paddingOnly(
      left: AppConstants.horizontalPadding,
      top: 16,
      right: AppConstants.horizontalPadding,
    );
  }

  // ignore: unused_element
  static Future<Map<String, String?>> _fetchSelectionIdHeadless(
      String handle, String cdnUrl, String prefHandle,
      {String originalImageUrl = '', String rawCdnUrl = ''}) async {
    if (cdnUrl.isEmpty && originalImageUrl.isEmpty && rawCdnUrl.isEmpty) return {};
    final selCompleter = Completer<String?>();
    final userCompleter = Completer<String?>();
    final escapedUrl = cdnUrl.replaceAll("'", r"\'");
    final escapedOrigUrl = originalImageUrl.replaceAll("'", r"\'");
    final escapedRawUrl = rawCdnUrl.replaceAll("'", r"\'");
    bool jsInjected = false;
    // Synchronous guards prevent "Bad state: Future already completed" when
    // multiple JS callHandler calls arrive before the first async callback
    // finishes awaiting SharedPreferences.
    bool selDone = false;
    bool userDone = false;
    HeadlessInAppWebView? hw;

    hw = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://earthlyjewels.co/products/$handle'),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      ),
      // Intercepts the fetch/XHR call that vtryon-storefront.js makes to
      // https://vtryon.earthlyjewels.co/api/tryon/selection at page load to
      // resolve the product's selectionId. Injected before any script runs so
      // the patch is in place before the VTryOn embed script executes.
      initialUserScripts: UnmodifiableListView([
        UserScript(
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          source: r'''
(function() {
  function extractSid(d) {
    if (!d) return null;
    return d.selectionId || d.selection_id ||
      (d.selection && (d.selection.id || d.selection.selectionId)) ||
      (d.data && (d.data.selectionId || d.data.id)) || null;
  }
  function isVtryonApi(url) {
    return typeof url === 'string' && url.includes('vtryon') && url.includes('selection');
  }
  // Patch fetch
  try {
    var _f = window.fetch;
    window.fetch = function() {
      var args = arguments;
      var url = String(args[0] && args[0].url ? args[0].url : args[0] || '');
      var p = _f.apply(this, args);
      if (isVtryonApi(url)) {
        p.then(function(r) { return r.clone().json(); })
         .then(function(d) {
           var sid = extractSid(d);
           if (sid) {
             console.log('[VTryOn] headless intercept selectionId: ' + sid);
             window.flutter_inappwebview.callHandler('VTryOnHeadless', String(sid));
           }
         }).catch(function() {});
      }
      return p;
    };
  } catch(_) {}
  // Patch XHR
  try {
    var _XHR = window.XMLHttpRequest;
    window.XMLHttpRequest = function() {
      var xhr = new _XHR();
      var _open = xhr.open.bind(xhr);
      var _url = '';
      xhr.open = function(m, u) { _url = String(u || ''); return _open.apply(xhr, arguments); };
      xhr.addEventListener('load', function() {
        try {
          if (isVtryonApi(_url)) {
            var sid = extractSid(JSON.parse(xhr.responseText));
            if (sid) {
              console.log('[VTryOn] headless XHR selectionId: ' + sid);
              window.flutter_inappwebview.callHandler('VTryOnHeadless', String(sid));
            }
          }
        } catch(_) {}
      });
      return xhr;
    };
    window.XMLHttpRequest.prototype = _XHR.prototype;
  } catch(_) {}
})();
''',
        ),
      ]),
      onWebViewCreated: (c) {
        c.addJavaScriptHandler(
          handlerName: 'VTryOnHeadless',
          callback: (args) async {
            final id = args.isNotEmpty ? args.first as String? : null;
            if (id != null && id.isNotEmpty && !selDone) {
              selDone = true; // synchronous guard before any await
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(SimpleWebScreen.prefKey(prefHandle), id);
              debugPrint('[VTryOn] headless selectionId: $id');
              try { if (!selCompleter.isCompleted) selCompleter.complete(id); } catch (_) {}
            }
            return null;
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'ShopifyUserId',
          callback: (args) async {
            final id = args.isNotEmpty ? args.first as String? : null;
            if (id != null && id.isNotEmpty && !userDone) {
              // VTryOn requires the Shopify numeric customer ID (all digits, ≥8 chars).
              // Reject GoKwik UUIDs (hex-dash format like 01a13892-237e-...).
              final isShopifyNumericId = RegExp(r'^\d{8,}$').hasMatch(id);
              if (!isShopifyNumericId) {
                debugPrint('[VTryOn] headless userId rejected (not numeric Shopify ID): $id');
                return null;
              }
              userDone = true; // synchronous guard before any await
              await SecureStorageService.instance.write('vtryon_shopify_user_id', id);
              if (kDebugMode) debugPrint('[VTryOn] headless userId: $id');
              try { if (!userCompleter.isCompleted) userCompleter.complete(id); } catch (_) {}
            }
            return null;
          },
        );
      },
      onConsoleMessage: (_, msg) {
        debugPrint('[VTryOn][JS] ${msg.message}');
      },
      onLoadStop: (c, url) async {
        final host = url?.host ?? '';
        // Skip JS on external domains — GoKwik / 3rd-party login redirects
        if (!host.contains('earthlyjewels.co')) {
          debugPrint('[VTryOn] headless external redirect: $url');
          return;
        }
        // Inject only once — guard against multiple onLoadStop fires
        if (jsInjected) return;
        jsInjected = true;
        debugPrint('[VTryOn] headless page: $url');

        await c.evaluateJavascript(source: '''
          (function() {
            console.log('[VTryOn] JS on: ' + location.href);

            // ── selectionId ─────────────────────────────────────────────────

            // L0: scan anchor links to vtryon.earthlyjewels.co — most reliable.
            // The VTryOn Shopify app block renders
            // <a href="https://vtryon...?selectionId=...&user_id=<shopify_customer_id>">
            // Shopify Liquid sets user_id to the numeric customer.id (e.g. 31298404581597).
            try {
              var links = document.querySelectorAll('a[href*="vtryon"]');
              for (var li = 0; li < links.length; li++) {
                var lh = links[li].href || links[li].getAttribute('href') || '';
                var lm = lh.match(/[?&]selectionId=([^&]+)/);
                if (lm && lm[1]) {
                  var lv = decodeURIComponent(lm[1]);
                  console.log('[VTryOn] L0 selectionId: ' + lv);
                  window.flutter_inappwebview.callHandler('VTryOnHeadless', lv);
                  // Also extract the Shopify numeric user_id from the same link.
                  var lum = lh.match(/[?&]user_id=([^&]+)/);
                  if (lum && lum[1]) {
                    var luv = decodeURIComponent(lum[1]);
                    console.log('[VTryOn] L0 user_id: ' + luv);
                    window.flutter_inappwebview.callHandler('ShopifyUserId', luv);
                  }
                  break;
                }
              }
            } catch(el0) { console.log('[VTryOn] L0 err: '+el0); }

            // S0: data-attribute scan on VTryOn-related elements
            try {
              var el = document.querySelector(
                '[data-vtryon-selection-id],[data-selection-id],[data-vtryon-id],[data-product-selection-id]'
              );
              if (el) {
                var dv = el.getAttribute('data-vtryon-selection-id')||el.getAttribute('data-selection-id')
                         ||el.getAttribute('data-vtryon-id')||el.getAttribute('data-product-selection-id');
                if (dv && dv.length > 4) { console.log('[VTryOn] S0 attr: '+dv); window.flutter_inappwebview.callHandler('VTryOnHeadless', dv); }
              }
            } catch(es0) { console.log('[VTryOn] S0 err: '+es0); }

            // S0b: inline script scan
            try {
              var scripts = document.querySelectorAll('script:not([src])');
              for (var si = 0; si < scripts.length; si++) {
                var t = scripts[si].textContent;
                var m = t.match(/"selectionId"\\s*:\\s*"([^"]{6,})"/)
                     || t.match(/selectionId\\s*[=:]\\s*['"]([^'"]{6,})['"]/)
                     || t.match(/selection_id\\s*[=:]\\s*['"]([^'"]{6,})['"]/);
                if (m && m[1]) { console.log('[VTryOn] S0b: '+m[1]); window.flutter_inappwebview.callHandler('VTryOnHeadless', m[1]); break; }
              }
            } catch(es0b) { console.log('[VTryOn] S0b err: '+es0b); }

            // S0c: VTryOn global objects
            try {
              var vg = window.VTryOn||window.vtryonConfig||window.vtryonData||window.VTRYON||window.vtryon;
              if (vg) { var vs=vg.selectionId||vg.selection_id; if(vs){console.log('[VTryOn] S0c: '+vs);window.flutter_inappwebview.callHandler('VTryOnHeadless',vs);} }
            } catch(_) {}

            // S1: App Proxy — try converted CDN URL, original URL, and raw CDN URL.
            // Each attempt tries: GET (query params) → POST (query params) →
            // POST (form body) since VTryOn's own widget POSTs with a form body.
            function extractSid(d) {
              if(!d) return null;
              return d.selectionId || d.selection_id ||
                (d.selection && (d.selection.id || d.selection.selectionId)) ||
                (d.data && (d.data.selectionId || d.data.id || d.data.selection_id)) ||
                null;
            }
            function tryProxy(cdnParam, label) {
              var qStr = 'cdn=' + encodeURIComponent(cdnParam)
                + '&shop=${VTryOnConfig.shopDomain}';
              var urlQ = '${VTryOnConfig.tryOnApiUrl}?' + qStr;
              console.log('[VTryOn] '+label+' GET cdn='+cdnParam);
              fetch(urlQ, {credentials:'include'})
                .then(function(r){
                  var ct=r.headers.get('content-type')||'';
                  console.log('[VTryOn] '+label+' GET st='+r.status+' ct='+ct);
                  if(r.type==='opaqueredirect') throw new Error('redirect');
                  if(!ct.includes('json')) throw new Error('not-json:'+r.status);
                  return r.json();
                })
                .then(function(d){
                  console.log('[VTryOn] '+label+' GET resp='+JSON.stringify(d));
                  var sid=extractSid(d);
                  if(sid) window.flutter_inappwebview.callHandler('VTryOnHeadless',String(sid));
                  else throw new Error('no-sid');
                })
                .catch(function(e){
                  console.log('[VTryOn] '+label+' GET err='+e+' -> POST');
                  fetch(urlQ, {method:'POST',credentials:'include'})
                    .then(function(r2){
                      var ct2=r2.headers.get('content-type')||'';
                      console.log('[VTryOn] '+label+' POST st='+r2.status+' ct='+ct2);
                      if(!ct2.includes('json')) throw new Error('not-json');
                      return r2.json();
                    })
                    .then(function(d2){
                      console.log('[VTryOn] '+label+' POST resp='+JSON.stringify(d2));
                      var sid2=extractSid(d2);
                      if(sid2) window.flutter_inappwebview.callHandler('VTryOnHeadless',String(sid2));
                      else throw new Error('no-sid');
                    })
                    .catch(function(e2){
                      console.log('[VTryOn] '+label+' POST err='+e2+' -> POSTBODY');
                      fetch('${VTryOnConfig.tryOnApiUrl}',{
                        method:'POST',credentials:'include',
                        headers:{'Content-Type':'application/x-www-form-urlencoded'},
                        body:qStr
                      })
                      .then(function(r3){return r3.json();})
                      .then(function(d3){
                        console.log('[VTryOn] '+label+' POSTBODY resp='+JSON.stringify(d3));
                        var sid3=extractSid(d3);
                        if(sid3) window.flutter_inappwebview.callHandler('VTryOnHeadless',String(sid3));
                      })
                      .catch(function(e3){console.log('[VTryOn] '+label+' POSTBODY err='+e3);});
                    });
                });
            }
            tryProxy('$escapedUrl', 'S1-cdn');
            if('$escapedOrigUrl' && '$escapedOrigUrl' !== '$escapedUrl') tryProxy('$escapedOrigUrl', 'S1-orig');
            if('$escapedRawUrl' && '$escapedRawUrl' !== '$escapedUrl' && '$escapedRawUrl' !== '$escapedOrigUrl') tryProxy('$escapedRawUrl', 'S1-raw');

            // S2 (delayed 2 s): re-scan after VTryOn's own scripts have run
            setTimeout(function() {
              try {
                var vg2=window.VTryOn||window.vtryonConfig||window.vtryonData||window.VTRYON||window.vtryon;
                if(vg2){var vs2=vg2.selectionId||vg2.selection_id;if(vs2){console.log('[VTryOn] S2 global: '+vs2);window.flutter_inappwebview.callHandler('VTryOnHeadless',vs2);}}
              } catch(_) {}
              try {
                var links2=document.querySelectorAll('a[href*="vtryon"]');
                for(var l2i=0;l2i<links2.length;l2i++){
                  var l2h=links2[l2i].href||'';var l2m=l2h.match(/[?&]selectionId=([^&]+)/);
                  if(l2m&&l2m[1]){
                    console.log('[VTryOn] S2 selectionId: '+decodeURIComponent(l2m[1]));
                    window.flutter_inappwebview.callHandler('VTryOnHeadless',decodeURIComponent(l2m[1]));
                    var l2um=l2h.match(/[?&]user_id=([^&]+)/);
                    if(l2um&&l2um[1]){console.log('[VTryOn] S2 user_id: '+decodeURIComponent(l2um[1]));window.flutter_inappwebview.callHandler('ShopifyUserId',decodeURIComponent(l2um[1]));}
                    break;
                  }
                }
              } catch(_) {}
            }, 2000);

            // ── userId ──────────────────────────────────────────────────────

            // U0: ShopifyAnalytics.meta.page.customerId — authoritative numeric ID.
            // Shopify injects this on all authenticated pages; always a numeric id.
            try {
              var saId=(window.ShopifyAnalytics&&window.ShopifyAnalytics.meta&&window.ShopifyAnalytics.meta.page&&window.ShopifyAnalytics.meta.page.customerId)||(window.meta&&window.meta.page&&window.meta.page.customerId)||(window.__st&&window.__st.v&&window.__st.v.customerId);
              console.log('[VTryOn] U0 ShopifyAnalytics: '+(saId||'null'));
              if(saId&&/^\\d{8,}\$/.test(String(saId))){console.log('[VTryOn] U0 match: '+String(saId));window.flutter_inappwebview.callHandler('ShopifyUserId',String(saId));return;}
            } catch(_) {}

            // U1: window.Shopify.customer.id
            try {
              var sc = window.Shopify && window.Shopify.customer;
              console.log('[VTryOn] Shopify.customer=' + JSON.stringify(sc));
              if (sc && sc.id) { console.log('[VTryOn] U1: '+sc.id); window.flutter_inappwebview.callHandler('ShopifyUserId', String(sc.id)); return; }
            } catch(_) {}

            // U2: HTML scan for customer id
            try {
              var html = document.documentElement.innerHTML;
              var pats = [
                /gid:\\/\\/shopify\\/Customer\\/(\\d+)/,
                /"customer"\\s*:\\s*\\{[^}]*?"id"\\s*:\\s*(\\d{8,})/,
                /customer_id['":\\s]+(\\d{8,})/i,
                /"id"\\s*:\\s*(\\d{10,})\\s*,\\s*"email"/,
                /Shopify\\.customer(?:Id)?['":\\s=]+(\\d{8,})/,
              ];
              for(var j=0;j<pats.length;j++){var mu=html.match(pats[j]);if(mu&&mu[1]){console.log('[VTryOn] U2['+j+']: '+mu[1]);window.flutter_inappwebview.callHandler('ShopifyUserId',mu[1]);return;}}
            } catch(_) {}

            // U3: /account.json
            fetch('/account.json',{credentials:'include',headers:{'Accept':'application/json','X-Requested-With':'XMLHttpRequest'}})
            .then(function(r){
              var ct=r.headers.get('content-type')||'';
              console.log('[VTryOn] U3 st='+r.status+' ct='+ct);
              if(!ct.includes('json')) throw new Error('html:'+r.status);
              return r.json();
            })
            .then(function(d){
              console.log('[VTryOn] U3 id='+(d&&d.customer?d.customer.id:'none'));
              if(d&&d.customer&&d.customer.id) window.flutter_inappwebview.callHandler('ShopifyUserId',String(d.customer.id));
            })
            .catch(function(e){console.log('[VTryOn] U3 err: '+e);});

            // U4: JS-accessible cookies (non-httpOnly) — kp_user_id set by KwikPass
            try {
              var jsCk=document.cookie;
              console.log('[VTryOn] U4 js-cookies: '+jsCk);
              var kpM=jsCk.match(/(?:^|;\\s*)kp_user_id=([^;]+)/);
              if(kpM&&kpM[1].trim()){
                console.log('[VTryOn] U4 kp_user_id: '+kpM[1].trim());
                window.flutter_inappwebview.callHandler('ShopifyUserId',kpM[1].trim());
              }
            } catch(_) {}

            // U5: GoKwik / KwikPass global objects (sync check)
            try {
              var gkKeys=['__gkConfig','gkConfig','gokwik','GoKwik','_gk','gk','__kwik','kwikpass','KwikPass','_kwikConfig','gkData','__goKwik'];
              for(var gki=0;gki<gkKeys.length;gki++){
                var gkO=window[gkKeys[gki]];
                if(!gkO) continue;
                var gku=gkO.userId||gkO.user_id||gkO.customerId||gkO.customer_id||(gkO.customer&&gkO.customer.id);
                if(gku){console.log('[VTryOn] U5 '+gkKeys[gki]+': '+gku);window.flutter_inappwebview.callHandler('ShopifyUserId',String(gku));break;}
                console.log('[VTryOn] U5 '+gkKeys[gki]+' keys='+Object.keys(gkO).join(',').substring(0,120));
              }
            } catch(_) {}

            // U6: delayed 4s ShopifyAnalytics + GoKwik scan
            setTimeout(function(){
              try {
                var saId6=(window.ShopifyAnalytics&&window.ShopifyAnalytics.meta&&window.ShopifyAnalytics.meta.page&&window.ShopifyAnalytics.meta.page.customerId)||(window.meta&&window.meta.page&&window.meta.page.customerId)||(window.__st&&window.__st.v&&window.__st.v.customerId);
                if(saId6&&/^\\d{8,}\$/.test(String(saId6))){console.log('[VTryOn] U6 ShopifyAnalytics: '+String(saId6));window.flutter_inappwebview.callHandler('ShopifyUserId',String(saId6));return;}
                var gkKeys2=['__gkConfig','gkConfig','gokwik','GoKwik','_gk','gk','__kwik','kwikpass','KwikPass','_kwikConfig','gkData','__goKwik'];
                for(var gki2=0;gki2<gkKeys2.length;gki2++){
                  var gkO2=window[gkKeys2[gki2]];
                  if(!gkO2) continue;
                  var gku2=gkO2.userId||gkO2.user_id||gkO2.customerId||gkO2.customer_id||(gkO2.customer&&gkO2.customer.id);
                  if(gku2){console.log('[VTryOn] U6 '+gkKeys2[gki2]+': '+gku2);window.flutter_inappwebview.callHandler('ShopifyUserId',String(gku2));return;}
                  console.log('[VTryOn] U6 '+gkKeys2[gki2]+' keys='+Object.keys(gkO2).join(',').substring(0,120));
                }
                // re-check kp_user_id cookie after KwikPass may have set it
                var kpM2=document.cookie.match(/(?:^|;\\s*)kp_user_id=([^;]+)/);
                if(kpM2&&kpM2[1].trim()){console.log('[VTryOn] U6 kp_user_id: '+kpM2[1].trim());window.flutter_inappwebview.callHandler('ShopifyUserId',kpM2[1].trim());}
                else console.log('[VTryOn] U6 no userId found');
              } catch(_) {}
            },4000);
          })();
        ''');
      },
    );

    final cookies = await CookieManager.instance()
        .getCookies(url: WebUri('https://earthlyjewels.co'));
    debugPrint('[VTryOn] cookies: ${cookies.map((c) => c.name).join(', ')}');

    try {
      await hw.run();

      String? selectionId, userId;
      try {
        selectionId =
            await selCompleter.future.timeout(const Duration(seconds: 45));
      } catch (_) {
        debugPrint('[VTryOn] headless selectionId timeout for $handle');
      }
      try {
        userId =
            await userCompleter.future.timeout(const Duration(seconds: 20));
      } catch (_) {
        debugPrint('[VTryOn] headless userId timeout');
      }

      return {'selectionId': selectionId, 'userId': userId};
    } finally {
      await hw.dispose();
    }
  }

  // Extracts the diamond carat value from variant options or SKU.
  // Checks selectedOptions for a key containing "carat", "diamond", or "weight",
  // then falls back to the last SKU segment matching the pattern {digits}ct.
  String _extractCarat(ProductVariant? variant) {
    if (variant == null) return '';
    for (final entry in variant.selectedOptions.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('carat') ||
          key.contains('diamond') ||
          key.contains('weight')) {
        return entry.value;
      }
    }
    if (variant.sku.contains('-')) {
      final last = variant.sku.split('-').last;
      if (RegExp(r'^\d+(\.\d+)?ct$', caseSensitive: false).hasMatch(last)) {
        return last;
      }
    }
    return '';
  }

  // Guard against double-tap pushing duplicate routes.
  static bool _breakupOpen = false;

  void _showBreakup(BuildContext context) {
    if (_breakupOpen) return;
    _breakupOpen = true;
    final numericVariantId = selectedVariant?.id.split('/').last ?? '';
    final url = 'https://earthlyjewels.co/products/${product.handle}'
        '${numericVariantId.isNotEmpty ? '?variant=$numericVariantId' : ''}';
    // Use Navigator.push instead of showModalBottomSheet.
    // showModalBottomSheet installs a drag gesture recognizer that intercepts
    // vertical touch events before they reach the InAppWebView, breaking scroll.
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => _PriceBreakupSheet(url: url),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    )).whenComplete(() => _breakupOpen = false);
  }
}

// Injected via evaluateJavascript in onLoadStop — AFTER Cloudflare challenge
// has cleared and Shopify theme JS has fully initialised the page components.
// The Flutter Opacity(0) overlay hides the WebView until DrawerReady fires.
const String _kPriceBreakupScript = r'''
(function() {
  // Guard: only run once per page load.
  if (window.__pbRunning) return;
  window.__pbRunning = true;

  console.log('[PB] eval url=' + location.href.substring(0,80) + ' title=' + document.title.substring(0,40));

  // Hide body immediately so the raw page isn't visible when Flutter
  // switches Opacity from 0→1 at DrawerReady.
  document.body.style.setProperty('visibility','hidden','important');
  document.documentElement.style.setProperty('visibility','hidden','important');

  // ── Selectors ─────────────────────────────────────────────────────────────
  var BTN_SELS = [
    '.price-breakup-button',
    '[aria-controls="PriceBreakupDrawer"]',
    '.price-breakdown-button',
    '[data-target="PriceBreakupDrawer"]',
    '[data-modal-target="PriceBreakupDrawer"]',
    '[data-drawer-target="PriceBreakupDrawer"]',
    'button[id*="price-breakup"]',
    'button[id*="price-breakdown"]',
    '[class*="price-breakup"]',
    '[class*="price_breakup"]',
  ];
  var DRAWER_SELS = [
    '#PriceBreakupDrawer',
    '#price-breakup-drawer',
    '#PriceBreakdownDrawer',
    '#price-breakdown-drawer',
    '[id*="PriceBreakup"]',
    '[id*="price_breakup"]',
    '[id*="price-breakdown"]',
    '.price-breakup-drawer',
    '.price-breakdown-drawer',
  ];

  function findButton() {
    for (var i = 0; i < BTN_SELS.length; i++) {
      try { var b = document.querySelector(BTN_SELS[i]); if (b) { console.log('[PB] btn:' + BTN_SELS[i]); return b; } } catch(_) {}
    }
    // Text-content fallback — works for any theme.
    try {
      var all = document.querySelectorAll('button,a,summary,[role="button"]');
      for (var j = 0; j < all.length; j++) {
        var txt = (all[j].textContent || '').toLowerCase().trim();
        if (txt.indexOf('price break') > -1) {
          console.log('[PB] btn-txt:' + all[j].tagName + ' "' + txt.substring(0,30) + '"');
          return all[j];
        }
      }
    } catch(_) {}
    return null;
  }

  function findOpenDrawer() {
    for (var i = 0; i < DRAWER_SELS.length; i++) {
      try {
        var d = document.querySelector(DRAWER_SELS[i]);
        if (!d) continue;
        if (!d.hasAttribute('hidden') && d.getAttribute('aria-hidden') !== 'true' && d.style.display !== 'none') {
          console.log('[PB] drawer:' + DRAWER_SELS[i]);
          return d;
        }
      } catch(_) {}
    }
    // <details open> accordion fallback
    try {
      var dets = document.querySelectorAll('details[open]');
      for (var di = 0; di < dets.length; di++) {
        var t = (dets[di].textContent || '').toLowerCase();
        if (t.indexOf('price') > -1 && (t.indexOf('metal') > -1 || t.indexOf('breakup') > -1 || t.indexOf('breakdown') > -1)) {
          console.log('[PB] details-open');
          return dets[di];
        }
      }
    } catch(_) {}
    return null;
  }

  function injectScrollCSS(sel) {
    if (document.getElementById('_pb_fix')) return;
    var s = document.createElement('style');
    s.id = '_pb_fix';
    s.textContent =
      sel + '{overflow-y:auto!important;-webkit-overflow-scrolling:touch!important;}' +
      sel + ' *{-webkit-overflow-scrolling:touch!important;}' +
      sel + ' [class*=inner],' + sel + ' [class*=content],' +
      sel + ' [class*=body],' + sel + ' [class*=scroll]{overflow-y:auto!important;max-height:none!important;}' +
      sel + ' button,' + sel + ' a,' + sel + ' [role=button],' + sel + ' summary{-webkit-tap-highlight-color:transparent!important;}';
    (document.head || document.documentElement).appendChild(s);
  }

  function watchDrawerClose(drawer) {
    var done = false;
    function close() {
      if (done) return; done = true; obs.disconnect();
      try { window.flutter_inappwebview.callHandler('DrawerClosed'); } catch(_) {}
    }
    var obs = new MutationObserver(function(muts) {
      for (var i = 0; i < muts.length; i++) {
        var m = muts[i];
        if (m.attributeName === 'hidden' && drawer.hasAttribute('hidden')) { close(); return; }
        if (m.attributeName === 'aria-hidden' && drawer.getAttribute('aria-hidden') === 'true') { close(); return; }
        if (m.attributeName === 'style' && drawer.style.display === 'none') { close(); return; }
        if (m.attributeName === 'class') {
          var cls = drawer.className || '';
          if (cls.indexOf('is-closed') > -1 || cls.indexOf('--closed') > -1) { close(); return; }
        }
      }
    });
    obs.observe(drawer, { attributes: true, attributeFilter: ['hidden','aria-hidden','style','class'] });
  }

  function onDrawerOpen(drawer) {
    var sel = drawer.id ? '#' + drawer.id : ('.' + (drawer.className || 'pb').split(' ')[0]);
    injectScrollCSS(sel);
    document.body.style.setProperty('background','white','important');
    document.body.style.setProperty('visibility','hidden','important');
    document.documentElement.style.setProperty('visibility','visible','important');
    drawer.style.setProperty('visibility','visible','important');
    watchDrawerClose(drawer);
    setTimeout(function() {
      try { window.flutter_inappwebview.callHandler('DrawerReady'); } catch(_) {}
    }, 350);
  }

  // Page is already loaded — try button immediately first.
  var btn = findButton();
  if (btn) {
    btn.click();
  } else {
    console.log('[PB] btn not found on load, will retry');
  }

  // Poll for open drawer (also handles async button click animation delay).
  var tries = 0;
  var btnRetries = 0;
  var poll = setInterval(function() {
    tries++;
    var d = findOpenDrawer();
    if (d) { clearInterval(poll); onDrawerOpen(d); return; }

    // Retry button click every 500ms for up to 5s (handles lazy-rendered buttons)
    if (!btn && tries % 5 === 0 && btnRetries < 10) {
      btnRetries++;
      btn = findButton();
      if (btn) btn.click();
    }

    if (tries === 30) {
      // 3s diagnostic
      var els = document.querySelectorAll('[id*="price"],[class*="price"],[id*="drawer"],[class*="drawer"]');
      var inf = [];
      for (var k = 0; k < Math.min(els.length, 15); k++) {
        inf.push(els[k].tagName + '#' + (els[k].id||'') + '.' + (els[k].className||'').split(' ')[0].substring(0,25));
      }
      console.log('[PB] 3s diag: ' + (inf.length ? inf.join('; ') : 'EMPTY'));
      if (!inf.length) {
        // Log ALL buttons with text to help identify the right selector
        var btns = document.querySelectorAll('button,a,summary,[role="button"]');
        var binfo = [];
        for (var bi = 0; bi < Math.min(btns.length, 20); bi++) {
          var txt2 = (btns[bi].textContent||'').trim().substring(0,25);
          if (txt2) binfo.push(btns[bi].tagName + ':"' + txt2 + '"');
        }
        console.log('[PB] all-btns: ' + (binfo.length ? binfo.join('; ') : 'NONE'));
      }
    }

    if (tries >= 100) {
      clearInterval(poll);
      console.log('[PB] timeout 10s title="' + document.title + '"');
      try { window.flutter_inappwebview.callHandler('DrawerError'); } catch(_) {}
    }
  }, 100);
})();
''';

class _PriceBreakupSheet extends StatefulWidget {
  final String url;
  const _PriceBreakupSheet({required this.url});

  @override
  State<_PriceBreakupSheet> createState() => _PriceBreakupSheetState();
}

class _PriceBreakupSheetState extends State<_PriceBreakupSheet> {
  bool _ready = false;
  bool _error = false;
  InAppWebViewController? _wvc;

  void _reload() {
    if (!mounted) return;
    setState(() { _ready = false; _error = false; });
    _wvc?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.92;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // IgnorePointer prevents invisible WebView receiving taps while loading.
              IgnorePointer(
                ignoring: !_ready,
                child: Opacity(
                  opacity: _ready ? 1.0 : 0.0,
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      // Block only images (not JS/CSS) so onLoadStop fires as soon
                      // as Shopify theme scripts finish — without waiting for images.
                      blockNetworkImage: true,
                      userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                          '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
                    ),
                    // No initialUserScripts — injecting at AT_DOCUMENT_START runs
                    // before Cloudflare's JS challenge can complete, which means our
                    // script sees the empty challenge page instead of the real Shopify
                    // product page.  We inject after onLoadStop instead.
                    onWebViewCreated: (c) {
                      _wvc = c;
                      c.addJavaScriptHandler(
                        handlerName: 'DrawerReady',
                        callback: (_) {
                          if (mounted) setState(() { _ready = true; _error = false; });
                          return null;
                        },
                      );
                      c.addJavaScriptHandler(
                        handlerName: 'DrawerClosed',
                        callback: (_) {
                          if (mounted) Navigator.of(context).pop();
                          return null;
                        },
                      );
                      c.addJavaScriptHandler(
                        handlerName: 'DrawerError',
                        callback: (_) {
                          if (mounted) setState(() => _error = true);
                          return null;
                        },
                      );
                    },
                    onLoadStart: (_, url) {
                      // Reset error on each new navigation (Cloudflare redirects,
                      // manual retries) so we don't get stuck on a stale error state.
                      if (mounted && !_ready) setState(() => _error = false);
                      if (kDebugMode) debugPrint('[PriceBreakup] loadStart: $url');
                    },
                    onLoadStop: (c, url) async {
                      // Page is fully loaded. Cloudflare challenge (if any) is done.
                      // Shopify theme JS has run and registered all components.
                      // Only inject on the product page — not on challenge redirects.
                      final host = url?.host ?? '';
                      if (!host.contains('earthlyjewels')) return;
                      if (kDebugMode) debugPrint('[PriceBreakup] loadStop: $url');
                      await c.evaluateJavascript(source: _kPriceBreakupScript);
                    },
                    onConsoleMessage: (_, msg) {
                      if (kDebugMode) debugPrint('[PriceBreakup][JS] ${msg.message}');
                    },
                    onReceivedError: (_, request, __) {
                      if (mounted && !_ready && (request.isForMainFrame ?? false)) {
                        setState(() => _error = true);
                      }
                    },
                    onReceivedHttpError: (_, req, res) {
                      if (mounted && !_ready && (req.isForMainFrame ?? false) &&
                          (res.statusCode ?? 0) >= 500) {
                        setState(() => _error = true);
                      }
                    },
                  ),
                ),
              ),
              // Loading overlay
              if (!_ready && !_error)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(child: LoaderWidget(size: 32)),
                  ),
                ),
              // Error overlay with retry
              if (_error)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: Colors.black26),
                        const SizedBox(height: 12),
                        const Text('Could not load price breakdown',
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _reload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TrustBadgesGrid extends StatelessWidget {
  const _TrustBadgesGrid();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const _TrustBadge(
              icon: Icons.verified_outlined,
              label: 'IGI/SGL certified',
              color: AppColors.success),
          8.width,
          const _TrustBadge(
              icon: Icons.workspace_premium_outlined,
              label: 'BIS hallmarked',
              color: AppColors.teal),
          8.width,
          const _TrustBadge(
              icon: Icons.local_shipping_outlined,
              label: 'Free Insured shipping',
              color: AppColors.success),
          8.width,
          const _TrustBadge(
              icon: Icons.security_outlined,
              label: 'Secure Pay',
              color: AppColors.teal),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        6.width,
        Flexible(
          child: Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textPrimary, fontSize: 11)),
        ),
      ]),
    );
  }
}
