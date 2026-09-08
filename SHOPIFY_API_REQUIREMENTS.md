# Earthly Jewels — Shopify API Requirements
### Share this document with your Shopify Developer

---

## OVERVIEW

**App:** Earthly Jewels Customer Mobile App (Flutter)
**API Type:** Shopify Storefront API (GraphQL)
**Endpoint:** `https://earthlyjewels.co/api/2024-10/graphql.json`

---

## PART A — APIs Already Available (No Setup Needed)

These are built into every Shopify store. Just need a valid Storefront API token with correct scopes.

---

### A1. Products API
**Used for:** Home screen product list, product detail screen, search
```
Query: products(first: 12)
Fields: id, handle, title, description, vendor, availableForSale,
        images, variants (price, compareAtPrice, selectedOptions)
```
**Scope needed:** `unauthenticated_read_product_listings`

---

### A2. Product by Handle API
**Used for:** Product detail screen
```
Query: productByHandle(handle: "ring-name")
Fields: id, handle, title, description, images (up to 8),
        variants, options
```
**Scope needed:** `unauthenticated_read_product_listings`

---

### A3. Collections API
**Used for:** Shop by Category grid on home screen, Shop tab filter chips
```
Query: collections(first: 8)
Fields: id, handle, title, description, image { url }
        products (first 8 per collection)
```
**Scope needed:** `unauthenticated_read_collection_listings`
> ⚠️ Each collection MUST have a cover image set in Shopify Admin

---

### A4. Collection by Handle API
**Used for:** Occasion collections (engagement, wedding, anniversary, birthday)
```
Query: collectionByHandle(handle: "engagement")
       collectionByHandle(handle: "wedding")
       collectionByHandle(handle: "anniversary")
       collectionByHandle(handle: "birthday")
Fields: id, handle, title, image { url }
```
**Scope needed:** `unauthenticated_read_collection_listings`
> ⚠️ Collections with these exact handles must exist in Shopify Admin

---

### A5. Shop Brand API
**Used for:** Store logo, store name, slogan in header and footer
```
Query: shop {
  name
  description
  brand {
    logo { image { url } }
    squareLogo { image { url } }
    slogan
    shortDescription
    coverImage { image { url } }
  }
}
```
**Scope needed:** None (public)
> ⚠️ Brand must be configured in Shopify Admin → Settings → Brand

---

### A6. Navigation Menu API
**Used for:** Category nav chips on home screen, footer links
```
Query: menu(handle: "main-menu")
Fields: items { title, url, type }
```
**Scope needed:** None (public)
> ⚠️ Main menu must exist in Shopify Admin → Content → Navigation

---

### A7. Cart API (Mutations)
**Used for:** Add to cart, update quantity, remove from cart, checkout
```
Mutations:
  cartCreate
  cartLinesAdd(cartId, lines: [{ merchandiseId, quantity }])
  cartLinesUpdate(cartId, lines: [{ id, quantity }])
  cartLinesRemove(cartId, lineIds)
```
**Scope needed:** None (public cart)

---

### A8. Customer Auth API (Mutations)
**Used for:** Login, Register, Logout, Forgot Password
```
Mutations:
  customerCreate(input: { email, password, firstName, lastName })
  customerAccessTokenCreate(input: { email, password })
  customerAccessTokenDelete(customerAccessToken)
  customerRecover(email)

Queries:
  customer(customerAccessToken) {
    id, firstName, lastName, email, phone
  }
```
**Scope needed:**
- `unauthenticated_read_customers`
- `unauthenticated_write_customers`

---

### A9. Customer Orders API
**Used for:** Order history screen
```
Query: customer(customerAccessToken) {
  orders(first: 20, sortKey: PROCESSED_AT, reverse: true) {
    id, name, orderNumber, fulfillmentStatus, financialStatus,
    processedAt, totalPrice { amount, currencyCode }
    lineItems {
      title, quantity
      variant { title, image { url }, price { amount } }
    }
  }
}
```
**Scope needed:** `unauthenticated_read_customers`

---

### A10. Product Search API
**Used for:** Search screen
```
Query: products(first: 20, query: "search term")
Fields: same as Products API (A1)
```
**Scope needed:** `unauthenticated_read_product_listings`

---

---

## PART B — APIs That Need to be Created in Shopify Admin

> ⚠️ These do NOT exist by default.
> Your Shopify developer must create these Metaobjects and Metafields.
> Each one must have **"Storefront API access"** enabled.

---

### B1. Announcement Bar
**Used for:** Scrolling announcement text at top of home screen
**Type:** Metaobject

```
Metaobject Type Name : announcement
Fields to create:
  - text        (Single line text)    ← the announcement message

How to create:
  Shopify Admin → Content → Metaobjects → Add definition
  Type name: announcement
  Add field: key=text, type=Single line text

After creating type:
  → Enable "Storefront API access" on this metaobject type
  → Add 1 to 3 entries with real announcement messages

Example entries:
  "Free shipping on orders above ₹5,000"
  "New collection launching this Diwali ✨"
  "Visit our Mumbai store — Mon to Sat, 10am to 8pm"
```

---

### B2. Hero Banners (Home Screen Slider)
**Used for:** Hero banner carousel — Section 1 on home screen
**Type:** Metaobject

```
Metaobject Type Name : hero_banner
Fields to create:
  - image       (File — image)            ← banner image
  - title       (Single line text)        ← headline text
  - subtitle    (Single line text)        ← sub-headline text
  - cta_text    (Single line text)        ← button label (e.g. "SHOP NOW")

How to create:
  Shopify Admin → Content → Metaobjects → Add definition
  Type name: hero_banner
  Add 4 fields as listed above

After creating type:
  → Enable "Storefront API access"
  → Add 3 to 5 banner entries with high quality images

Note: If this metaobject is empty, the app automatically uses
      collection cover images as a fallback for the banner.
```

---

### B3. Feature / Second Banner
**Used for:** Second full-width banner below the hero slider
**Type:** Metaobject

```
Metaobject Type Name : feature_banner
Fields to create:
  - image       (File — image)
  - title       (Single line text)
  - subtitle    (Single line text)
  - cta_text    (Single line text)

How to create:
  Shopify Admin → Content → Metaobjects → Add definition
  Type name: feature_banner

After creating type:
  → Enable "Storefront API access"
  → Add 1 entry

Note: This section is completely hidden if no entry is added.
```

---

### B4. Why Earthly Section
**Used for:** "Why Earthly Jewels" brand values section on home screen
**Type:** Metaobject

```
Metaobject Type Name : why_earthly
Fields to create:
  - icon        (Single line text)    ← emoji icon e.g. 💍 ✨ 🌿 🚚
  - title       (Single line text)    ← value heading
  - body        (Multi-line text)     ← value description

How to create:
  Shopify Admin → Content → Metaobjects → Add definition
  Type name: why_earthly

After creating type:
  → Enable "Storefront API access"
  → Add 3 to 5 entries

Example entries:
  icon=💎  title="Lab-Grown Diamonds"    body="Certified, conflict-free stones"
  icon=🚚  title="Free Insured Shipping" body="Pan-India delivery, fully insured"
  icon=↩️  title="15-Day Returns"        body="Hassle-free returns, no questions asked"
  icon=🏆  title="Lifetime Warranty"     body="We stand behind every piece forever"
```

---

### B5. Customer Reviews (Home Screen)
**Used for:** Reviews carousel on home screen
**Type:** Metaobject

```
Metaobject Type Name : review
Fields to create:
  - rating          (Integer)            ← value 1 to 5
  - reviewer_name   (Single line text)   ← customer name
  - title           (Single line text)   ← review headline
  - body            (Multi-line text)    ← review text

How to create:
  Shopify Admin → Content → Metaobjects → Add definition
  Type name: review

After creating type:
  → Enable "Storefront API access"
  → Add 5 to 10 real customer reviews

Note: If the store uses Judge.me or Loox review app,
      the app can also pull reviews automatically from those apps.
      If metaobject reviews exist, those are used first.
```

---

### B6. CTA Banner (Call to Action)
**Used for:** Promotional CTA section near bottom of home screen
**Type:** Metaobject

```
Metaobject Type Name : cta
Fields to create:
  - title       (Single line text)    ← main heading
  - subtitle    (Single line text)    ← sub text
  - cta_text    (Single line text)    ← button label
  - image       (File — image)        ← optional background image

How to create:
  Shopify Admin → Content → Metaobjects → Add definition
  Type name: cta

After creating type:
  → Enable "Storefront API access"
  → Add 1 entry

Example:
  title="Design Your Dream Ring"
  subtitle="Book a free virtual consultation"
  cta_text="BOOK NOW"

Note: If no image is added, the section shows a solid dark background.
      This section is hidden if no entry is added.
```

---

### B7. Section Title Labels (Shop Metafields)
**Used for:** Heading text above each home screen section
**Type:** Shop Metafields

```
How to create:
  Shopify Admin → Settings → Custom data → Shop → Add field
  (Create each as: type = Single line text)

Fields to create:

  Namespace : section
  ┌──────────────────────────┬──────────────────────────────┐
  │ Key                      │ Recommended Value            │
  ├──────────────────────────┼──────────────────────────────┤
  │ featured_products        │ Most Loved Pieces            │
  │ why_earthly              │ Why Earthly Jewels           │
  │ why_earthly_subtitle     │ More than just jewellery     │
  │ reviews                  │ What Our Customers Say       │
  │ categories               │ Shop by Category             │
  │ occasions                │ Shop by Occasion             │
  └──────────────────────────┴──────────────────────────────┘

After creating each field:
  → Enable "Storefront API access"
  → Fill in the value

Note: If these metafields are empty, sections still show
      but without a title heading above them.
```

---

### B8. Store Contact Info (Shop Metafields)
**Used for:** "Visit Us" section inside Account screen
**Type:** Shop Metafields

```
How to create:
  Shopify Admin → Settings → Custom data → Shop → Add field
  (Create each as: type = Single line text)

Fields to create:

  Namespace : custom
  ┌──────────────────┬────────────────────────────────────┐
  │ Key              │ Example Value                      │
  ├──────────────────┼────────────────────────────────────┤
  │ store_address    │ 123 Jewel Street, Bandra, Mumbai   │
  │ store_hours      │ Mon–Sat: 10am – 8pm                │
  │ store_phone      │ +91 98765 43210                    │
  │ store_email      │ hello@earthlyjewels.co             │
  └──────────────────┴────────────────────────────────────┘

After creating each field:
  → Enable "Storefront API access"
  → Fill in real store information

Note: This entire section is hidden in the app
      if none of these 4 fields have values.
```

---

---

## PART C — Storefront API Token & Scopes

> Your Shopify developer must generate this token and share it.

### Required API Scopes
```
✅ unauthenticated_read_product_listings
✅ unauthenticated_read_collection_listings
✅ unauthenticated_read_content
✅ unauthenticated_read_metaobjects
✅ unauthenticated_read_customers
✅ unauthenticated_write_customers
✅ unauthenticated_read_customer_tags
```

### How to Generate Token
```
1. Open: earthlyjewels.co/admin/settings/apps
2. Click: Develop apps
3. Open the app (or create new one for mobile app)
4. Tab: Configuration → Storefront API integration
5. Enable all scopes listed above
6. Click Save
7. Tab: API credentials
8. Click: Reveal token once → Copy token
9. Share the token securely with the Flutter developer
```

---

## PART D — Complete Checklist for Shopify Developer

```
STOREFRONT API
[ ] Generate Storefront API token with all required scopes
[ ] Share token securely with Flutter developer

METAOBJECTS (Content → Metaobjects)
[ ] Create type: announcement       (1 field: text)
[ ] Create type: hero_banner        (4 fields: image, title, subtitle, cta_text)
[ ] Create type: feature_banner     (4 fields: image, title, subtitle, cta_text)
[ ] Create type: why_earthly        (3 fields: icon, title, body)
[ ] Create type: review             (4 fields: rating, reviewer_name, title, body)
[ ] Create type: cta                (4 fields: title, subtitle, cta_text, image)
[ ] Enable Storefront API access on ALL metaobject types
[ ] Add real content entries to each type

SHOP METAFIELDS (Settings → Custom data → Shop)
[ ] section / featured_products      → "Most Loved Pieces"
[ ] section / why_earthly            → "Why Earthly Jewels"
[ ] section / why_earthly_subtitle   → subtitle text
[ ] section / reviews                → "What Our Customers Say"
[ ] section / categories             → "Shop by Category"
[ ] section / occasions              → "Shop by Occasion"
[ ] custom  / store_address          → store address
[ ] custom  / store_hours            → store hours
[ ] custom  / store_phone            → phone number
[ ] custom  / store_email            → email address
[ ] Enable Storefront API access on ALL metafields
[ ] Fill in real values for all metafields

COLLECTIONS
[ ] Add cover images to all main collections (Rings, Necklaces, etc.)
[ ] Create collection handle: engagement (with cover image)
[ ] Create collection handle: wedding    (with cover image)
[ ] Create collection handle: anniversary(with cover image)
[ ] Create collection handle: birthday   (with cover image)

NAVIGATION
[ ] Verify main menu exists with handle: main-menu
[ ] Add relevant menu items (Rings, Necklaces, Earrings, etc.)

STORE BRAND
[ ] Shopify Admin → Settings → Brand
[ ] Upload store logo (for app header)
[ ] Add store slogan
[ ] Add short description
```

---

## SUMMARY TABLE

| # | API / Content | Type | Status | Who Creates |
|---|---|---|---|---|
| A1 | Products | Storefront API | ✅ Ready | — |
| A2 | Product Detail | Storefront API | ✅ Ready | — |
| A3 | Collections | Storefront API | ✅ Ready | Need cover images |
| A4 | Occasion Collections | Storefront API | ✅ Ready | Need 4 collection handles |
| A5 | Shop Brand / Logo | Storefront API | ✅ Ready | Need brand configured |
| A6 | Navigation Menu | Storefront API | ✅ Ready | Need menu configured |
| A7 | Cart | Storefront API | ✅ Ready | — |
| A8 | Customer Auth | Storefront API | ✅ Ready | Need scopes enabled |
| A9 | Customer Orders | Storefront API | ✅ Ready | Need scopes enabled |
| A10 | Product Search | Storefront API | ✅ Ready | — |
| B1 | Announcement Bar | Metaobject | ⬜ Create | Shopify Developer |
| B2 | Hero Banners | Metaobject | ⬜ Create | Shopify Developer |
| B3 | Feature Banner | Metaobject | ⬜ Create | Shopify Developer |
| B4 | Why Earthly | Metaobject | ⬜ Create | Shopify Developer |
| B5 | Reviews | Metaobject | ⬜ Create | Shopify Developer |
| B6 | CTA Banner | Metaobject | ⬜ Create | Shopify Developer |
| B7 | Section Labels | Shop Metafields | ⬜ Create | Shopify Developer |
| B8 | Store Contact Info | Shop Metafields | ⬜ Create | Shopify Developer |
| C | Storefront API Token | App Credentials | ⬜ Generate | Shopify Developer |

---

*Document for: Earthly Jewels Shopify Developer*
*App: Customer Mobile App (Flutter)*
*Date: 2026-09-03*
