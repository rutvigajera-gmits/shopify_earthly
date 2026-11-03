'use strict';

/**
 * LOCAL TEST SERVER — runs on your PC for free testing.
 * Use ngrok to expose it publicly so Shopify can send webhooks.
 *
 * SETUP:
 *   1. Download service account key:
 *      Firebase Console → Project Settings → Service Accounts → Generate new private key
 *      Save as: functions/service-account.json
 *
 *   2. Run this server:
 *      cd functions && node local-server.js
 *
 *   3. In a new terminal run ngrok:
 *      ngrok http 3000
 *
 *   4. Copy the ngrok URL (e.g. https://abc123.ngrok.io)
 *      Update Shopify webhook URL to: https://abc123.ngrok.io/shopifyWebhook
 */

const express = require('express');
const admin   = require('firebase-admin');
const crypto  = require('crypto');

// ── Firebase Admin init ───────────────────────────────────────────────────────
const serviceAccount = require('./service-account.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const app = express();

// Webhook needs raw body for HMAC verification.
app.post('/shopifyWebhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const secret = process.env.SHOPIFY_WEBHOOK_SECRET;
  if (secret) {
    const hmac = req.headers['x-shopify-hmac-sha256'];
    const computed = crypto.createHmac('sha256', secret).update(req.body).digest('base64');
    try {
      if (!hmac || !crypto.timingSafeEqual(Buffer.from(computed), Buffer.from(hmac))) {
        return res.status(401).send('Invalid HMAC');
      }
    } catch (_) {
      return res.status(401).send('HMAC check failed');
    }
  }

  const topic = req.headers['x-shopify-topic'] || '';
  let order;
  try {
    order = JSON.parse(req.body.toString());
  } catch (_) {
    return res.status(400).send('Invalid JSON');
  }

  // Acknowledge immediately — Shopify needs 200 within 5 seconds.
  res.status(200).json({ received: true });

  const email     = (order.email || order.customer?.email || '').trim().toLowerCase();
  const orderName = order.name || `#${order.order_number || order.id}`;

  console.log(`[webhook] ${topic} — order=${orderName} email=${email}`);

  if (!email) {
    console.log('[webhook] No customer email in payload');
    return;
  }

  // Read FCM token from Firestore.
  let token;
  try {
    const doc = await admin.firestore().collection('fcm_tokens').doc(email).get();
    if (!doc.exists) {
      console.log(`[webhook] No FCM token in Firestore for: ${email}`);
      return;
    }
    token = doc.data().token;
  } catch (e) {
    console.error('[webhook] Firestore error:', e.message);
    return;
  }

  const notification = _buildNotification(topic, orderName);
  if (!notification) {
    console.log(`[webhook] Unhandled topic: ${topic}`);
    return;
  }

  // Send FCM notification.
  try {
    const messageId = await admin.messaging().send({
      token,
      notification: { title: notification.title, body: notification.body },
      data: { topic, orderName, orderId: String(order.id || '') },
      android: {
        priority: 'high',
        notification: { channelId: 'earthly_jewels_orders', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
    console.log(`[webhook] Notification sent — messageId=${messageId}`);
  } catch (e) {
    console.error('[webhook] FCM error:', e.message);
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n✅ Local webhook server running on port ${PORT}`);
  console.log('   Now run: ngrok http 3000');
  console.log('   Then update Shopify webhook URL to: https://YOUR-NGROK-URL/shopifyWebhook\n');
});
