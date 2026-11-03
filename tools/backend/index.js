/**
 * GoKwik + Shopify Admin API backend proxy.
 * Also handles FCM push notifications for order events.
 *
 * DEPLOYMENT OPTIONS (pick one):
 *   A. Firebase Cloud Functions — see README section below
 *   B. Vercel Serverless         — rename file to api/resolve-customer.js
 *   C. Railway / Render / Fly.io — run as an Express server with: node index.js
 *
 * REQUIRED ENVIRONMENT VARIABLES:
 *   GOKWIK_API_KEY           — GoKwik API key
 *   GOKWIK_MERCHANT_ID       — GoKwik merchant ID (19g6im8tsh89q)
 *   SHOPIFY_ADMIN_TOKEN      — Shopify Admin API access token
 *   SHOPIFY_SHOP_DOMAIN      — y7srws-f4.myshopify.com
 *   SHOPIFY_WEBHOOK_SECRET   — Webhook signing secret (Shopify Admin → Settings → Notifications → Webhooks)
 *   FIREBASE_SERVICE_ACCOUNT — JSON string of Firebase service account key
 *                              (Firebase Console → Project Settings → Service Accounts → Generate new private key)
 *
 * SHOPIFY WEBHOOK SETUP (after deploying):
 *   Shopify Admin → Settings → Notifications → Webhooks → Create webhook:
 *     Event: Order creation   → URL: https://<your-domain>/shopify/webhook
 *     Event: Order payment    → URL: https://<your-domain>/shopify/webhook
 *     Event: Fulfillment creation → URL: https://<your-domain>/shopify/webhook
 *     Event: Order cancellation  → URL: https://<your-domain>/shopify/webhook
 */

'use strict';

const https  = require('https');
const crypto = require('crypto');

// ── Rate limiter ─────────────────────────────────────────────────────────────
// In-memory: max 20 requests per 15 minutes per IP.
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
const GOKWIK_API_BASE    = 'https://api.gokwik.co';
const GOKWIK_VERIFY_PATH = '/v1/merchant/customer/details';
const SHOPIFY_API_VERSION = '2024-07';

// ── FCM token store (email → fcmToken) ───────────────────────────────────────
// In-memory — resets on restart. Replace with Redis/DB for production.
const _tokenStore = new Map();

// ── Firebase Admin SDK ────────────────────────────────────────────────────────
let _messaging = null;
try {
  const admin   = require('firebase-admin');
  const svcJson = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (svcJson) {
    const svc = JSON.parse(svcJson);
    admin.initializeApp({ credential: admin.credential.cert(svc) });
    _messaging = admin.messaging();
    console.log('[backend] Firebase Admin initialized');
  } else {
    console.warn('[backend] FIREBASE_SERVICE_ACCOUNT not set — push notifications disabled');
  }
} catch (e) {
  console.warn('[backend] Firebase Admin not available:', e.message);
}

// ── Express server ────────────────────────────────────────────────────────────
let app;
try {
  const express = require('express');
  app = express();

  // Webhook MUST be registered before express.json() — needs raw body for HMAC.
  app.post('/shopify/webhook', express.raw({ type: 'application/json' }), webhookHandler);
  app.post('/register-token', express.json({ limit: '2kb' }), registerTokenHandler);

  app.use(express.json({ limit: '10kb' }));
  app.post('/resolve-customer', handler);
  app.post('/update-cart', updateCartHandler);

  const port = process.env.PORT || 3000;
  app.listen(port, () => console.log(`[backend] listening on port ${port}`));
} catch (_) {
  // Express not installed — used as a Cloud Function / Vercel module instead.
}

// ── Firebase Cloud Functions entry point ─────────────────────────────────────
try {
  const functions = require('firebase-functions');
  exports.resolveCustomer = functions.https.onRequest(handler);
} catch (_) {}

// ── Vercel entry point ───────────────────────────────────────────────────────
module.exports = handler;

// ── POST /register-token ──────────────────────────────────────────────────────
// Called by the Flutter app on login + when FCM token refreshes.
// Body: { email: string, fcmToken: string }

async function registerTokenHandler(req, res) {
  const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || 'unknown';
  if (!_checkRate(ip)) return res.status(429).json({ error: 'Too many requests' });

  const { email, fcmToken } = req.body || {};
  if (!email || !fcmToken) {
    return res.status(400).json({ error: 'Missing email or fcmToken' });
  }

  _tokenStore.set(email.trim().toLowerCase(), fcmToken);
  console.log(`[backend] FCM token registered — email=${email}`);
  return res.status(200).json({ success: true });
}

// ── POST /shopify/webhook ─────────────────────────────────────────────────────
// Receives Shopify order webhooks and sends FCM push notifications.
// Shopify sends X-Shopify-Hmac-Sha256 header for HMAC verification.

async function webhookHandler(req, res) {
  // HMAC verification (skip if SHOPIFY_WEBHOOK_SECRET not set — dev only)
  const secret = process.env.SHOPIFY_WEBHOOK_SECRET;
  if (secret) {
    const hmacHeader = req.headers['x-shopify-hmac-sha256'];
    if (!hmacHeader) return res.status(401).json({ error: 'Missing HMAC' });
    const computed = crypto.createHmac('sha256', secret).update(req.body).digest('base64');
    try {
      if (!crypto.timingSafeEqual(Buffer.from(computed), Buffer.from(hmacHeader))) {
        return res.status(401).json({ error: 'Invalid HMAC' });
      }
    } catch (_) {
      return res.status(401).json({ error: 'HMAC check failed' });
    }
  }

  const topic = req.headers['x-shopify-topic'] || '';
  let order;
  try {
    order = JSON.parse(req.body.toString());
  } catch (_) {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }

  // Acknowledge immediately — Shopify expects a 200 within 5 seconds.
  res.status(200).json({ received: true });

  const email = (order.email || order.customer?.email || '').trim().toLowerCase();
  const orderName = order.name || `#${order.order_number || order.id}`;

  if (!email) {
    console.warn(`[backend] Webhook ${topic}: no customer email in payload`);
    return;
  }

  const fcmToken = _tokenStore.get(email);
  if (!fcmToken) {
    console.log(`[backend] Webhook ${topic}: no FCM token for ${email}`);
    return;
  }

  const notification = _buildNotification(topic, orderName);
  if (!notification) {
    console.log(`[backend] Webhook: unhandled topic "${topic}"`);
    return;
  }

  await _sendFcm(fcmToken, notification.title, notification.body, {
    topic,
    orderName,
    orderId: String(order.id || ''),
  });
}

function _buildNotification(topic, orderName) {
  switch (topic) {
    case 'orders/create':
      return { title: 'Order Confirmed', body: `Your order ${orderName} has been placed` };
    case 'orders/paid':
      return { title: 'Payment Confirmed', body: `Payment received for order ${orderName}` };
    case 'orders/fulfilled':
      return { title: 'Order Shipped', body: `Your order ${orderName} is on its way!` };
    case 'orders/partially_fulfilled':
      return { title: 'Partial Shipment', body: `Part of your order ${orderName} has shipped` };
    case 'orders/cancelled':
      return { title: 'Order Cancelled', body: `Your order ${orderName} has been cancelled` };
    default:
      return null;
  }
}

async function _sendFcm(token, title, body, data = {}) {
  if (!_messaging) {
    console.warn('[backend] FCM not initialized — notification skipped');
    return;
  }
  try {
    const result = await _messaging.send({
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: { channelId: 'earthly_jewels_orders', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
    console.log(`[backend] FCM sent — messageId=${result}`);
  } catch (e) {
    console.error('[backend] FCM send error:', e.message);
  }
}

// ── POST /resolve-customer ────────────────────────────────────────────────────

async function handler(req, res) {
  const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || 'unknown';
  if (!_checkRate(ip)) {
    return res.status(429).json({ error: 'Too many requests' });
  }

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

      const payload = gokwikData.data || gokwikData;
      phone             = payload.phone            || payload.mobile          || '';
      shopifyCustomerId = payload.shopify_customer_id
                       || payload.customer_id
                       || payload.shopifyCustomerId
                       || '';

      console.log(`[backend] GoKwik resolved — phone=${phone} shopifyId=${shopifyCustomerId}`);
    } catch (gkErr) {
      console.warn('[backend] GoKwik API error (will try phone fallback):', gkErr.message);
    }

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

// ── POST /update-cart ─────────────────────────────────────────────────────────

async function updateCartHandler(req, res) {
  const ip = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || 'unknown';
  if (!_checkRate(ip)) return res.status(429).json({ error: 'Too many requests' });

  const origin = req.headers['origin'];
  if (origin) {
    if (!_allowedOrigins.has(origin)) return res.status(403).json({ error: 'Forbidden' });
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  }
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { customerId, cartItems } = req.body || {};
  if (!customerId || !Array.isArray(cartItems)) {
    return res.status(400).json({ error: 'Missing customerId or cartItems' });
  }

  const adminToken = process.env.SHOPIFY_ADMIN_TOKEN;
  const shopDomain = process.env.SHOPIFY_SHOP_DOMAIN;
  if (!adminToken || !shopDomain) {
    return res.status(500).json({ error: 'Server misconfigured' });
  }

  try {
    const numericId = String(customerId).replace(/\D/g, '');
    const url = `https://${shopDomain}/admin/api/${SHOPIFY_API_VERSION}/customers/${numericId}/metafields.json`;
    const body = JSON.stringify({
      metafield: {
        namespace: 'flutter_app',
        key: 'cart_items',
        value: JSON.stringify(cartItems),
        type: 'json',
      },
    });
    await shopifyPost(url, adminToken, body);
    console.log(`[backend] cart metafield saved — customerId=${numericId} items=${cartItems.length}`);
    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('[backend] updateCart error:', err.message);
    return res.status(500).json({ error: err.message });
  }
}

// ── HTTP helpers ──────────────────────────────────────────────────────────────

function shopifyPost(url, token, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = https.request(
      {
        hostname: u.hostname,
        path:     u.pathname + u.search,
        method:   'POST',
        headers: {
          'X-Shopify-Access-Token': token,
          'Content-Type':           'application/json',
          'Content-Length':         Buffer.byteLength(body),
        },
      },
      res => {
        let data = '';
        res.on('data', chunk => (data += chunk));
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            if (res.statusCode >= 400) {
              reject(new Error(`Shopify ${res.statusCode}: ${data.slice(0, 200)}`));
            } else {
              resolve(parsed);
            }
          } catch (e) {
            reject(new Error(`Shopify parse error: ${data.slice(0, 200)}`));
          }
        });
      },
    );
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

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
