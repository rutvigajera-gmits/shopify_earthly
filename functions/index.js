'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin  = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
setGlobalOptions({ region: 'us-central1' });

// ── POST /shopifyWebhook ──────────────────────────────────────────────────────
// Shopify sends an HTTP POST here for every order event you subscribe to.
// Reads the customer FCM token from Firestore and sends a push notification.
//
// Deploy:  firebase deploy --only functions
// URL:     https://us-central1-<PROJECT_ID>.cloudfunctions.net/shopifyWebhook
//
// Required Firebase config (set once before deploying):
//   firebase functions:config:set shopify.webhook_secret="<secret from Shopify>"
//
// How to get the webhook secret:
//   Shopify Admin → Settings → Notifications → Webhooks
//   After creating the first webhook, Shopify shows the signing secret at the top.

exports.shopifyWebhook = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).send('Method not allowed');
  }

  // ── HMAC verification ────────────────────────────────────────────────────
  const secret = process.env.SHOPIFY_WEBHOOK_SECRET
               || (require('firebase-functions').config().shopify || {}).webhook_secret;

  if (secret) {
    const hmacHeader = req.headers['x-shopify-hmac-sha256'];
    if (!hmacHeader) {
      return res.status(401).send('Missing HMAC header');
    }
    // Cloud Functions provides req.rawBody as a Buffer for HMAC verification.
    const computed = crypto
      .createHmac('sha256', secret)
      .update(req.rawBody)
      .digest('base64');
    try {
      if (!crypto.timingSafeEqual(Buffer.from(computed), Buffer.from(hmacHeader))) {
        return res.status(401).send('Invalid HMAC');
      }
    } catch (_) {
      return res.status(401).send('HMAC check failed');
    }
  }

  const topic = req.headers['x-shopify-topic'] || '';
  const order = req.body;

  // Acknowledge immediately — Shopify expects 200 within 5 seconds.
  res.status(200).json({ received: true });

  const email = (order.email || order.customer?.email || '').trim().toLowerCase();
  const orderName = order.name || `#${order.order_number || order.id}`;

  if (!email) {
    console.log(`[webhook] ${topic}: no customer email in payload`);
    return;
  }

  // ── Look up FCM token from Firestore ─────────────────────────────────────
  const doc = await admin.firestore().collection('fcm_tokens').doc(email).get();
  if (!doc.exists) {
    console.log(`[webhook] ${topic}: no FCM token for ${email}`);
    return;
  }

  const { token } = doc.data();
  if (!token) return;

  // ── Build notification content ───────────────────────────────────────────
  const notification = _buildNotification(topic, orderName);
  if (!notification) {
    console.log(`[webhook] Unhandled topic: ${topic}`);
    return;
  }

  // ── Send via FCM ─────────────────────────────────────────────────────────
  try {
    const messageId = await admin.messaging().send({
      token,
      notification: {
        title: notification.title,
        body:  notification.body,
      },
      data: {
        topic,
        orderName,
        orderId: String(order.id || ''),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'earthly_jewels_orders',
          sound:     'default',
        },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
    console.log(`[webhook] Notification sent — email=${email} topic=${topic} messageId=${messageId}`);
  } catch (e) {
    console.error(`[webhook] FCM send error: ${e.message}`);
  }
});

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
