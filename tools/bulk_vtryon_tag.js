/**
 * Bulk VTryOn product tagger
 * Usage: node bulk_vtryon_tag.js
 *
 * Reads vtryon_products.csv (handle,selectionId) and adds tag
 * "vtryon:<selectionId>" to each product in Shopify via Admin API.
 *
 * Existing tags are preserved. If a vtryon: tag already exists it is replaced.
 */

const fs = require('fs');
const https = require('https');
const path = require('path');

// ─── CONFIG ───────────────────────────────────────────────────────────────────
const SHOP_DOMAIN = 'y7srws-f4.myshopify.com';
const ADMIN_TOKEN = 'PASTE_YOUR_ADMIN_API_TOKEN_HERE';   // Step 1
const API_VERSION = '2024-01';
const CSV_FILE    = path.join(__dirname, 'vtryon_products.csv');  // Step 3
// ──────────────────────────────────────────────────────────────────────────────

function shopifyRequest(method, endpoint, body) {
  return new Promise((resolve, reject) => {
    const bodyStr = body ? JSON.stringify(body) : '';
    const options = {
      hostname: SHOP_DOMAIN,
      path: `/admin/api/${API_VERSION}${endpoint}`,
      method,
      headers: {
        'X-Shopify-Access-Token': ADMIN_TOKEN,
        'Content-Type': 'application/json',
        ...(bodyStr ? { 'Content-Length': Buffer.byteLength(bodyStr) } : {}),
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error(`JSON parse error: ${data}`)); }
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

function sleep(ms) { return new Promise((r) => setTimeout(r, ms)); }

async function run() {
  if (!fs.existsSync(CSV_FILE)) {
    console.error(`CSV not found: ${CSV_FILE}`);
    process.exit(1);
  }

  const lines = fs.readFileSync(CSV_FILE, 'utf8').trim().split('\n');
  const rows  = lines.slice(1).map((l) => {
    const [handle, selectionId] = l.split(',').map((s) => s.trim());
    return { handle, selectionId };
  }).filter((r) => r.handle && r.selectionId);

  console.log(`Processing ${rows.length} products...\n`);

  let ok = 0, failed = 0;

  for (const { handle, selectionId } of rows) {
    try {
      // 1. Look up product by handle
      const res = await shopifyRequest(
        'GET',
        `/products.json?handle=${encodeURIComponent(handle)}&fields=id,title,tags`
      );
      const products = res.products ?? [];
      if (!products.length) {
        console.log(`  NOT FOUND : ${handle}`);
        failed++;
        continue;
      }

      const product = products[0];
      const existingTags = product.tags
        ? product.tags.split(',').map((t) => t.trim()).filter((t) => t && !t.startsWith('vtryon:'))
        : [];
      const newTag  = `vtryon:${selectionId}`;
      const newTags = [...existingTags, newTag].join(', ');

      // 2. Update the product tags
      await shopifyRequest('PUT', `/products/${product.id}.json`, {
        product: { id: product.id, tags: newTags },
      });

      console.log(`  TAGGED    : ${product.title}`);
      console.log(`              handle=${handle}  tag=${newTag}\n`);
      ok++;

      // Stay under Shopify's rate limit (2 req/s on Basic)
      await sleep(600);
    } catch (err) {
      console.error(`  ERROR     : ${handle} — ${err.message}`);
      failed++;
    }
  }

  console.log(`\nDone. ${ok} tagged, ${failed} failed.`);
}

run();
