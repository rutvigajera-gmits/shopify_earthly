# Earthly Jewels — Customer App Flow Plan

---

## 1. App Launch Flow

```
User opens app
       │
       ▼
main.dart → EarthlyApp
       │
       ▼
MultiProvider (registers all providers)
  ├── ProductProvider
  ├── CartProvider
  ├── ShopProvider
  ├── ReviewProvider
  └── CustomerProvider
       │
       ▼
_AppShell (IndexedStack)
       │
       ├── CustomerProvider.init()       ← restores saved login session
       │       └── SharedPreferences → reads "customer_token"
       │               ├── token found  → fetchCustomer() → stay logged in
       │               └── no token     → guest mode
       │
       └── ShopProvider.initialize()     ← loads all store content
               └── (all run in parallel)
                   ├── fetchShopBrand()
                   ├── fetchBanners()
                   ├── fetchFeatureBanner()
                   ├── fetchBrandValues()
                   ├── fetchAnnouncements()
                   ├── fetchMainMenu()
                   ├── fetchOccasionCollections()
                   ├── fetchCtaBanner()
                   └── fetchSectionTitles()
```

---

## 2. Bottom Navigation

```
┌────────┬────────┬────────┬────────┬────────┐
│  Home  │  Shop  │ Search │  Cart  │Account │
│  [0]   │  [1]   │  [2]   │  [3]   │  [4]   │
└────────┴────────┴────────┴────────┴────────┘
    │         │        │        │        │
    ▼         ▼        ▼        ▼        ▼
 Home      Products  Search   Cart   Account
 Screen    Screen    Screen   Screen  Screen
                   (route)  (route)
```

---

## 3. Home Screen Flow

```
Home Screen
│
├── AnnouncementBar        ← API: metaobject "announcement" → hidden if none
│
├── AppHeader              ← API: shop brand logo / store name
│
├── ─────────────────────────────────────────────────
│   SECTION 1: Hero Banner Carousel
│   ─────────────────────────────────────────────────
│   API: metaobject "hero_banner"
│   Fallback: collection cover images
│   Hidden: if no banners + no collections
│   Shows: image, title, subtitle, CTA button
│
├── ─────────────────────────────────────────────────
│   SECTION 2: Feature / Second Banner
│   ─────────────────────────────────────────────────
│   API: metaobject "feature_banner"
│   Hidden: if not configured in Shopify Admin
│   Shows: full-width image with overlay text
│
├── ─────────────────────────────────────────────────
│   SECTION 3: Category Nav Chips
│   ─────────────────────────────────────────────────
│   API: store main menu (main-menu / header-menu)
│   Hidden: if no menu items
│   Tap: navigates to Shop tab
│
├── ─────────────────────────────────────────────────
│   SECTION 4: Why Earthly
│   ─────────────────────────────────────────────────
│   API: metaobject "why_earthly"
│   Hidden: if not configured in Shopify Admin
│   Shows: icon + title + description rows
│
├── ─────────────────────────────────────────────────
│   SECTION 5: Customer Reviews
│   ─────────────────────────────────────────────────
│   Source 1: metaobject "review" (Shopify Admin)
│   Source 2: Judge.me public API (if installed)
│   Source 3: Shopify SPR legacy endpoint
│   Hidden: if all 3 sources return nothing
│   Shows: star rating, review text, reviewer name
│
├── ─────────────────────────────────────────────────
│   SECTION 6: Most Loved Pieces
│   ─────────────────────────────────────────────────
│   API: products(first: 12) — NO extra setup needed
│   Shows: horizontal scrollable product cards
│   Tap card → Product Detail Screen
│   "View All" → Shop tab
│
├── ─────────────────────────────────────────────────
│   SECTION 7: Shop by Category
│   ─────────────────────────────────────────────────
│   API: collections(first: 8) — NO extra setup needed
│   Hidden: if collections have no cover images
│   Shows: 2-column image grid
│   Tap → Shop tab
│
├── ─────────────────────────────────────────────────
│   SECTION 8: Occasions
│   ─────────────────────────────────────────────────
│   API: collections by handle
│         (engagement, wedding, anniversary, birthday)
│   Hidden: if handles don't exist in store
│   Shows: horizontal scrollable tiles
│
├── ─────────────────────────────────────────────────
│   SECTION 9: CTA Banner
│   ─────────────────────────────────────────────────
│   API: metaobject "cta"
│   Hidden: if not configured
│   Shows: dark block or image background with button
│
└── ─────────────────────────────────────────────────
    SECTION 10: Footer
    ─────────────────────────────────────────────────
    API: shop brand + main menu items
    Shows: store name, nav links, copyright year
```

---

## 4. Product Flow

```
Products Screen
│
├── Loads: ProductProvider.loadCollections()
├── Shows: collection tabs / filter chips
│
├── Product Grid
│   └── ProductCard (image, title, price, compare price)
│           │
│           ▼ tap
│
Product Detail Screen
│
├── Image gallery (swipe)
├── Title, price, vendor
├── Variant selector (size, material, etc.)
├── Description
├── Review summary
│
└── "ADD TO CART" button
        │
        ▼
   CartProvider.addToCart()
        │
        ▼ success
   Cart icon badge updates
```

---

## 5. Cart & Checkout Flow

```
Cart Screen
│
├── Shows: CartProvider.lines (all items)
│   └── CartLineCard
│       ├── Product image, title, variant
│       ├── Price
│       ├── Quantity +/- buttons
│       │       └── CartProvider.updateCartLine()
│       └── Remove button
│               └── CartProvider.removeFromCart()
│
├── Order summary (subtotal)
│
└── "CHECKOUT" button
        │
        ▼
   Opens: cart.checkoutUrl (Shopify hosted checkout)
        │
        ▼ (in browser / webview)
   Customer fills shipping + payment
        │
        ▼ order confirmed
   Order appears in Account → My Orders
```

---

## 6. Search Flow

```
Search Screen
│
├── Text input field
│       │ user types (debounced)
│       ▼
│   ProductProvider.search(query)
│       └── Shopify API: products(query: "...")
│
├── Loading state (shimmer)
├── Empty state ("No results for X")
│
└── Results grid
        └── ProductCard
                │ tap
                ▼
        Product Detail Screen
```

---

## 7. Account Screen Flow

```
Account Screen
│
├── ─── NOT LOGGED IN ──────────────────────────────
│   Shows:
│   ├── Guest avatar (person icon)
│   ├── "Welcome!" message
│   ├── "Sign in to view orders, wishlist & deals"
│   └── SIGN IN button
│           │
│           ▼
│       Login Screen
│
└── ─── LOGGED IN ──────────────────────────────────
    Shows:
    ├── Initials avatar (black circle)
    ├── Customer full name
    ├── Email address
    ├── Phone (if set)
    │
    ├── My Orders ──────────────► Orders Screen
    ├── Wishlist ───────────────► (pending)
    ├── Saved Addresses ────────► (pending)
    ├── Earthly Elite Membership► (pending)
    │
    ├── Book Store Visit ───────► (link/external)
    ├── Virtual Consultation ───► (link/external)
    ├── FAQ ────────────────────► (link/external)
    ├── Contact Us ─────────────► (link/external)
    ├── Privacy Policy ─────────► (link/external)
    ├── Terms & Conditions ─────► (link/external)
    │
    ├── Sign Out
    │   └── Confirmation dialog
    │           └── Yes → CustomerProvider.logout()
    │                       ├── calls customerAccessTokenDelete
    │                       ├── clears token from memory
    │                       └── removes from SharedPreferences
    │
    └── Store Info (if configured in Shopify Admin)
        ├── Address
        ├── Hours
        ├── Phone
        └── Email
```

---

## 8. Login / Register Flow

```
Login Screen
│
├── TAB 1: SIGN IN
│   │
│   ├── Email field
│   ├── Password field (eye toggle)
│   ├── "Forgot password?" link
│   │       └── CustomerProvider.sendPasswordReset(email)
│   │               └── Shopify sends reset email
│   │
│   └── SIGN IN button
│           │
│           ▼
│       CustomerProvider.login(email, password)
│           │
│           ├── API: customerAccessTokenCreate mutation
│           │       ├── ERROR → show red error banner
│           │       └── SUCCESS → token received
│           │
│           ├── API: fetchCustomer(token)
│           │       └── loads name, email, phone
│           │
│           ├── SharedPreferences.save("customer_token")
│           │
│           └── screen pops → Account tab refreshes
│
└── TAB 2: CREATE ACCOUNT
    │
    ├── First Name field
    ├── Last Name field
    ├── Email field
    ├── Password field (eye toggle)
    │
    └── CREATE ACCOUNT button
            │
            ▼
        CustomerProvider.register(...)
            │
            ├── API: customerCreate mutation
            │       ├── ERROR → show red error banner
            │       └── SUCCESS → account created
            │
            ├── auto-login (calls login internally)
            │
            └── screen pops → Account tab refreshes
```

---

## 9. Orders Screen Flow

```
Account → My Orders
│
└── Orders Screen
        │
        ├── initState → CustomerProvider.loadOrders()
        │       └── API: customer { orders(first: 20) }
        │
        ├── LOADING STATE
        │   └── Shimmer (5 skeleton cards)
        │
        ├── EMPTY STATE
        │   └── "No orders yet" + bag icon
        │
        └── ORDER LIST (reverse chronological)
                │
                └── OrderCard
                    ├── Product thumbnail (first item image)
                    ├── Order number (#1001)
                    ├── Order date (formatted)
                    ├── Items (title + variant + qty, max 2 lines)
                    ├── Total price
                    └── Status Badge
                        ├── FULFILLED          → 🟢 Delivered
                        ├── UNFULFILLED        → 🟠 Processing
                        ├── PARTIALLY_FULFILLED→ 🔵 Partially Delivered
                        └── other              → ⚪ In Progress
```

---

## 10. API Data Flow (How sections get data)

```
ShopifyService (singleton)
│
├── _query(gql)           ← standard queries (no auth needed)
│   └── POST /api/2024-10/graphql.json
│       Header: X-Shopify-Storefront-Access-Token
│
└── _queryWithVars(gql, vars) ← customer auth mutations
    └── same endpoint, adds "variables" to body (secure, no string interpolation)


Section          →  API Call                  →  Fallback
─────────────────────────────────────────────────────────
Banners          →  metaobjects(hero_banner)  →  collections with images
Feature Banner   →  metaobjects(feature_banner) → hidden
Announcements    →  metaobjects(announcement) →  shop metafield → hidden
Why Earthly      →  metaobjects(why_earthly)  →  hidden
Reviews          →  metaobjects(review)       →  Judge.me → SPR → hidden
Products         →  products(first:12)        →  shimmer → hidden
Collections      →  collections(first:8)      →  hidden
Occasions        →  collectionByHandle(x4)    →  hidden (if handles missing)
CTA              →  metaobjects(cta)          →  hidden
Nav Menu         →  menu(main-menu)           →  hidden
Store Info       →  shop metafields(custom.*) →  hidden
Section Labels   →  shop metafields(section.*)->  no label shown
```

---

## 11. Shopify Admin Setup (What to configure)

### Step 1 — Get Storefront API Token
```
earthlyjewels.co/admin
  → Settings → Apps → Develop apps
  → Open your app → Configuration tab
  → Enable Storefront API scopes:
      ✅ unauthenticated_read_product_listings
      ✅ unauthenticated_read_collection_listings
      ✅ unauthenticated_read_content
      ✅ unauthenticated_read_metaobjects
      ✅ unauthenticated_read_customers
      ✅ unauthenticated_write_customers
  → Save → API credentials tab → copy token
  → Paste into app_constants.dart
```

### Step 2 — Create Metaobjects (for content sections)
```
earthlyjewels.co/admin → Content → Metaobjects → Add definition

┌─────────────────┬──────────────────────────────────────────┐
│ Type name       │ Fields                                   │
├─────────────────┼──────────────────────────────────────────┤
│ announcement    │ text (single line)                       │
│ hero_banner     │ image (file), title, subtitle, cta_text  │
│ feature_banner  │ image (file), title, subtitle, cta_text  │
│ why_earthly     │ icon (text), title, body (multi-line)    │
│ review          │ rating (integer), body, reviewer_name,   │
│                 │ title                                    │
│ cta             │ title, subtitle, cta_text, image (opt.)  │
└─────────────────┴──────────────────────────────────────────┘

After creating each type → Add entries with real content
⚠️ Enable "Storefront API access" on each metaobject type
```

### Step 3 — Create Shop Metafields (for labels & store info)
```
earthlyjewels.co/admin → Settings → Custom data → Shop → Add field

┌──────────────┬──────────────────────┬──────────────────────┐
│ Namespace    │ Key                  │ Purpose              │
├──────────────┼──────────────────────┼──────────────────────┤
│ section      │ featured_products    │ "Most Loved Pieces"  │
│ section      │ why_earthly          │ "Why Earthly Jewels" │
│ section      │ why_earthly_subtitle │ Section subtitle     │
│ section      │ reviews              │ "What They Say"      │
│ section      │ categories           │ "Shop by Category"   │
│ section      │ occasions            │ "Shop by Occasion"   │
│ custom       │ store_address        │ Account → Visit Us   │
│ custom       │ store_hours          │ Account → Visit Us   │
│ custom       │ store_phone          │ Account → Visit Us   │
│ custom       │ store_email          │ Account → Visit Us   │
└──────────────┴──────────────────────┴──────────────────────┘

⚠️ Enable "Storefront API access" on each metafield
⚠️ Fill in values after creating
```

---

## 12. Current Build Status

```
SCREENS
✅ Home Screen          — all 10 sections, dynamic data
✅ Products Screen      — collection filter + product grid
✅ Product Detail       — images, variants, add to cart
✅ Cart Screen          — line items, quantity, checkout link
✅ Search Screen        — live product search
✅ Account Screen       — guest + logged-in states
✅ Login Screen         — sign in + register tabs
✅ Orders Screen        — order history with status badges

FEATURES
✅ Dynamic home content — from Shopify API
✅ Announcement bar     — from metaobjects
✅ Hero banner slider   — metaobjects + collection fallback
✅ Customer login       — Shopify Storefront API auth
✅ Customer register    — with auto-login
✅ Forgot password      — Shopify customerRecover
✅ Session persistence  — SharedPreferences token
✅ Order history        — with status badges + thumbnails
✅ Cart management      — add, update, remove, checkout
✅ Product search       — live search
✅ Shimmer loading      — all major sections
✅ Zero console logging — no API call logs in production

PENDING
⬜ Wishlist             — needs customer metafield for saved products
⬜ Saved Addresses      — needs customerAddressCreate mutation
⬜ Product filtering    — by price, category, tag
⬜ Push notifications   — needs Firebase FCM
⬜ Book Store Visit     — needs booking URL or app
⬜ Virtual Consultation — needs video call booking URL
⬜ Membership           — needs custom loyalty logic
```

---

## 13. Environment / Config File

`lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // ── Shopify API ──────────────────────────────────────
  static const String shopDomain           = 'earthlyjewels.co';
  static const String storefrontApiVersion = '2024-10';
  static const String storefrontApiUrl     =
      'https://$shopDomain/api/$storefrontApiVersion/graphql.json';
  static const String storefrontAccessToken = 'PASTE_YOUR_TOKEN_HERE';

  // ── Layout ───────────────────────────────────────────
  static const double horizontalPadding = 16.0;
  static const double sectionSpacing    = 40.0;
  static const double cardSpacing       = 12.0;
  static const double borderRadius      = 4.0;

  // ── Occasion collection handles ──────────────────────
  static const List<String> occasionHandles = [
    'engagement', 'wedding', 'anniversary', 'birthday'
  ];
}
```

---

*Last updated: 2026-09-02*
