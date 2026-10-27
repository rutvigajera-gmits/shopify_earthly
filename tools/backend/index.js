/**
 * GoKwik + Shopify Admin API backend proxy.
 *
 * Receives the KWIKSESSIONTOKEN from the Flutter app after KwikPass OTP,
 * verifies it with GoKwik's Merchant API, then fetches the customer's full
 * profile, orders, and addresses from the Shopify Admin API.
 *
 * DEPLOYMENT OPTIONS (pick one):
 *   A. Firebase Cloud Functions — see README section below
 *   B. Vercel Serverless         — rename file to api/resolve-customer.js
 *   C. Railway / Render / Fly.io — run as an Express server with: node index.js
 *
 * REQUIRED ENVIRONMENT VARIABLES:
 *   GOKWIK_API_KEY      — GoKwik API key (from GoKwik Dashboard → API Settings)
 *   GOKWIK_MERCHANT_ID  — GoKwik merchant ID (19g6im8tsh89q)
 *   SHOPIFY_ADMIN_TOKEN — Shopify Admin API access token (from Custom App)
 *   SHOPIFY_SHOP_DOMAIN — y7srws-f4.myshopify.com
 *
 * SHOPIFY ADMIN TOKEN SETUP:
 *   1. Shopify Admin → Settings → Apps and sales channels → Develop apps
 *   2. Create app → Configure Admin API scopes:
 *      - read_customers
 *      - read_orders
 *   3. Install app → copy the "Admin API access token" (shown once only)
 *
 * GOKWIK API KEY SETUP:
 *   GoKwik Dashboard → Developer / API Settings → copy API Key / Secret
 *   ⚠ Confirm the exact endpoint path from your GoKwik dashboard docs.
 *     The placeholder below uses the most likely path. Update GOKWIK_VERIFY_PATH
 *     if your dashboard shows a different route.
 */

'use strict';

const https = require('https');

// ── Rate limiter ─────────────────────────────────────────────────────────────
// In-memory: max 20 requests per 15 minutes per IP (no extra dependency).
const _rateMap = new Map();
function _checkRate(ip) {
  const now = Date.now();
  const windowMs = 15 * 60 * 1000;
  const max = 20;
  let entry = _rateMap.get(ip);
  if (!entry || now > entry.resetAt) {
    entry = { count: 0, resetAt: now + windowMs };
  }
  entry.count++;
  _rateMap.set(ip, entry);
  return entry.count <= max;
}

// ── Allowed CORS origins ─────────────────────────────────────────────────────
const _allowedOrigins = new Set(['https://earthlyjewels.co']);

// ── Configuration ────────────────────────────────────────────────────────────

const GOKWIK_API_BASE   = 'https://api.gokwik.co';
// TODO: Confirm this path from GoKwik Dashboard → Developer → API Reference.
// Common variants: /v1/merchant/customer/details  |  /v1/merchant/verify-session
const GOKWIK_VERIFY_PATH = '/v1/merchant/customer/details';

const SHOPIFY_API_VERSION = '2024-07';

// ── Express server (for Railway / Render / Fly.io) ───────────────────────────

let app;
try {
  const express = require('express');
  app = express();
  app.use(express.json({ limit: '10kb' }));
  app.post('/resolve-customer', handler);
  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`[backend] listening on port ${port}`));
} catch (_) {
  // Express not installed — used as a Cloud Function / Vercel module instead.
}

// ── Firebase Cloud Functions entry point ─────────────────────────────────────

try {
  const functions = require('firebase-functions');
  exports.resolveCustomer = functions.https.onRequest(handler);
} catch (_) {
  // firebase-functions not installed — not running as a Cloud Function.
}

// ── Vercel entry point ───────────────────────────────────────────────────────

module.exports = handler;

// ── Main handler ─────────────────────────────────────────────────────────────

async function handler(req, res) {
  // Rate limiting.
  const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || 'unknown';
  if (!_checkRate(ip)) {
    return res.status(429).json({ error: 'Too many requests' });
  }

  // CORS — restrict to known web origin; mobile Flutter clients send no Origin.
  const origin = req.headers['origin'];
  if (origin) {
    if (!_allowedOrigins.has(origin)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Vary', 'Origin');
  }

  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { kwiksessiontoken } = req.body || {};
  if (!kwiksessiontoken) {
    return res.status(400).json({ error: 'Missing kwiksessiontoken' });
  }

  const gokwikKey  = process.env.GOKWIK_API_KEY;
  const merchantId = process.env.GOKWIK_MERCHANT_ID;
  const adminToken = process.env.SHOPIFY_ADMIN_TOKEN;
  const shopDomain = process.env.SHOPIFY_SHOP_DOMAIN;

  if (!gokwikKey || !adminToken || !shopDomain) {
    console.error('[backend] Missing required environment variables');
    return res.status(500).json({ error: 'Server misconfigured' });
  }

  try {
    // ── Step 1: Verify KWIKSESSIONTOKEN with GoKwik Merchant API ─────────────
    let phone = '';
    let shopifyCustomerId = '';

    try {
      const gokwikBody = JSON.stringify({
        token:       kwiksessiontoken,
        merchant_id: merchantId,
      });
      const gokwikData = await httpPost(
        `${GOKWIK_API_BASE}${GOKWIK_VERIFY_PATH}`,
        {
          'x-merchant-id':  merchantId,
          'x-api-key':      gokwikKey,
          'Content-Type':   'application/json',
          'Content-Length': Buffer.byteLength(gokwikBody),
        },
        gokwikBody,
      );

      // GoKwik may return customer data nested under .data or at the top level.
      const payload = gokwikData.data || gokwikData;
      phone           = payload.phone            || payload.mobile          || '';
      shopifyCustomerId = payload.shopify_customer_id
                       || payload.customer_id
                       || payload.shopifyCustomerId
                       || '';

      console.log(`[backend] GoKwik resolved — phone=${phone} shopifyId=${shopifyCustomerId}`);
    } catch (gkErr) {
      console.warn('[backend] GoKwik API error (will try phone fallback):', gkErr.message);
    }

    // ── Step 2: Resolve Shopify customer ID ───────────────────────────────────
    let customerId = String(shopifyCustomerId || '').replace(/\D/g, '');

    if (!customerId && phone) {
      const searchUrl =
        `https://${shopDomain}/admin/api/${SHOPIFY_API_VERSION}/customers/search.json` +
        `?query=phone:${encodeURIComponent(phone)}&fields=id&limit=1`;
      const searchRes = await shopifyGet(searchUrl, adminToken);
      customerId = String(searchRes.customers?.[0]?.id || '');
      console.log(`[backend] Shopify phone search → customerId=${customerId}`);
    }

    if (!customerId) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // ── Step 3: Fetch profile + orders + addresses in parallel ────────────────
    const base = `https://${shopDomain}/admin/api/${SHOPIFY_API_VERSION}/customers/${customerId}`;
    const [profileRes, ordersRes, addressesRes] = await Promise.all([
      shopifyGet(`${base}.json`, adminToken),
      shopifyGet(`${base}/orders.json?status=any&limit=20`, adminToken),
      shopifyGet(`${base}/addresses.json`, adminToken),
    ]);

    const profile   = profileRes.customer || {};
    const orders    = normalizeOrders(ordersRes.orders || [], profile.currency || 'INR');
    const addresses = normalizeAddresses(
      addressesRes.addresses || [],
      profile.default_address?.id,
    );

    return res.status(200).json({
      shopifyId: customerId,
      email:     profile.email      || '',
      phone:     profile.phone      || phone,
      firstName: profile.first_name || '',
      lastName:  profile.last_name  || '',
      orders,
      addresses,
    });
  } catch (err) {
    console.error('[backend] resolveCustomer error:', err.message);
    return res.status(500).json({ error: err.message });
  }
}

// ── Normalizers ───────────────────────────────────────────────────────────────
// Transform Shopify Admin API responses into the Storefront API format
// that the Flutter app's CustomerOrder / CustomerAddress models expect.

function normalizeOrders(adminOrders, storeCurrency) {
  return adminOrders.map(o => ({
    node: {
      id:                `gid://shopify/Order/${o.id}`,
      name:              o.name,
      orderNumber:       o.order_number,
      fulfillmentStatus: (o.fulfillment_status || 'UNFULFILLED').toUpperCase(),
      financialStatus:   (o.financial_status   || '').toUpperCase(),
      totalPrice: {
        amount:       o.total_price,
        currencyCode: o.currency || storeCurrency,
      },
      processedAt: o.created_at,
      lineItems: {
        edges: (o.line_items || []).slice(0, 5).map(item => ({
          node: {
            title:    item.title,
            quantity: item.quantity,
            variant: item.variant_id ? {
              title: item.variant_title || '',
              price: {
                amount:       item.price,
                currencyCode: o.currency || storeCurrency,
              },
              image: null,
            } : null,
          },
        })),
      },
    },
  }));
}

function normalizeAddresses(adminAddresses, defaultAddressId) {
  return adminAddresses.map(a => ({
    id: `gid://shopify/MailingAddress/${a.id}?model_name=CustomerAddress&customer_id=${a.customer_id}`,
    firstName: a.first_name || '',
    lastName:  a.last_name  || '',
    company:   a.company    || '',
    address1:  a.address1   || '',
    address2:  a.address2   || '',
    city:      a.city       || '',
    province:  a.province   || '',
    country:   a.country    || '',
    zip:       a.zip        || '',
    phone:     a.phone      || '',
    isDefault: a.id === defaultAddressId,
  }));
}

// ── HTTP helpers ──────────────────────────────────────────────────────────────

function shopifyGet(url, token) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, {
      headers: {
        'X-Shopify-Access-Token': token,
        'Content-Type':           'application/json',
      },
    }, res => {
      let body = '';
      res.on('data', chunk => (body += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 400) {
            reject(new Error(`Shopify ${res.statusCode}: ${body.slice(0, 200)}`));
          } else {
            resolve(parsed);
          }
        } catch (e) {
          reject(new Error(`Shopify parse error: ${body.slice(0, 200)}`));
        }
      });
    });
    req.on('error', reject);
  });
}

function httpPost(url, headers, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(
      {
        hostname: u.hostname,
        path:     u.pathname + u.search,
        method:   'POST',
        headers,
      },
      res => {
        let data = '';
        res.on('data', chunk => (data += chunk));
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            if (res.statusCode >= 400) {
              reject(new Error(`GoKwik ${res.statusCode}: ${data.slice(0, 200)}`));
            } else {
              resolve(parsed);
            }
          } catch (e) {
            reject(new Error(`GoKwik parse error: ${data.slice(0, 200)}`));
          }
        });
      },
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}
