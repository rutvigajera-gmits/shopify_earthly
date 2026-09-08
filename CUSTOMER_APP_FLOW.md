# Earthly Jewels — Customer Mobile App
## Complete Flow Document

---

# TABLE OF CONTENTS

1. App Overview
2. App Architecture
3. App Launch & Onboarding Flow
4. Home Screen Flow
5. Product Browsing Flow
6. Product Detail Flow
7. Shopping Cart & Checkout Flow
8. Search Flow
9. Customer Account Flow
10. Login & Registration Flow
11. Order History Flow
12. Wishlist Flow (Planned)
13. Notification Flow (Planned)
14. API & Data Flow
15. Shopify Admin Configuration
16. Screen Inventory
17. Feature Status

---

# 1. APP OVERVIEW

**App Name:** Earthly Jewels
**Platform:** Android & iOS (Flutter)
**Purpose:** Customer-facing mobile shopping app for the Earthly Jewels Shopify store
**Store:** earthlyjewels.co
**Data Source:** Shopify Storefront API (GraphQL) — 100% dynamic, no static content

### Key Principles
- Every piece of content is fetched from the Shopify store
- If the store owner changes anything in Shopify Admin, the app reflects it automatically
- No hardcoded product names, prices, banners, or text
- Session persists across app restarts (user stays logged in)
- Zero API call logs in production console

---

# 2. APP ARCHITECTURE

### Layer Structure
```
Presentation Layer  →  Screens + Widgets
State Layer         →  Providers (ChangeNotifier)
Data Layer          →  Services + Models
```

### State Providers
| Provider | Responsibility |
|---|---|
| ShopProvider | Store brand, banners, menus, metaobjects |
| ProductProvider | Products, collections, search results |
| CartProvider | Cart lines, quantities, checkout URL |
| ReviewProvider | Store-level customer reviews |
| CustomerProvider | Auth token, customer profile, orders |

### Navigation Structure
```
AppShell
  ├── Tab 0 → Home Screen
  ├── Tab 1 → Shop / Products Screen
  ├── Tab 2 → Search Screen (opens as route)
  ├── Tab 3 → Cart Screen (opens as route)
  └── Tab 4 → Account Screen
```

---

# 3. APP LAUNCH & ONBOARDING FLOW

```
┌─────────────────────────────────────┐
│           User Opens App            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│     Initialize All Providers        │
│  ┌─────────────────────────────┐    │
│  │ CustomerProvider.init()     │    │
│  │  └─ Read SharedPreferences  │    │
│  │      ├─ Token found         │    │
│  │      │   └─ Verify token    │    │
│  │      │       ├─ Valid  → Login   │
│  │      │       └─ Invalid → Guest  │
│  │      └─ No token → Guest mode   │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ ShopProvider.initialize()   │    │
│  │  (all run in parallel)      │    │
│  │  ├─ Shop brand & logo       │    │
│  │  ├─ Hero banners            │    │
│  │  ├─ Feature banner          │    │
│  │  ├─ Brand values            │    │
│  │  ├─ Announcements           │    │
│  │  ├─ Navigation menu         │    │
│  │  ├─ Occasion collections    │    │
│  │  ├─ CTA banner              │    │
│  │  └─ Section titles          │    │
│  └─────────────────────────────┘    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│         Home Screen Loads           │
│   (shows shimmer while loading)     │
└─────────────────────────────────────┘
```

---

# 4. HOME SCREEN FLOW

The home screen loads all content dynamically. Each section independently shows, hides, or shows a shimmer skeleton based on its API response.

```
HOME SCREEN
│
│  ┌──────────────────────────────────────────────────┐
│  │  ANNOUNCEMENT BAR (scrolling ticker)             │
│  │  Source: Shopify Metaobject "announcement"       │
│  │  Hidden if: no metaobject entries exist          │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  APP HEADER                                      │
│  │  Left:  Store logo (from Shopify brand API)      │
│  │  Right: Search icon + Cart icon (with badge)     │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 1 — HERO BANNER CAROUSEL                │
│  │  Source: Metaobject "hero_banner"                │
│  │  Fallback: Collection cover images               │
│  │  Hidden if: no banners + no collection images    │
│  │  Features:                                       │
│  │    • Auto-plays every 5 seconds                  │
│  │    • Swipe to navigate                           │
│  │    • Dot indicators at bottom                    │
│  │    • Overlay: title + subtitle + CTA button      │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 2 — FEATURE / SECOND BANNER             │
│  │  Source: Metaobject "feature_banner"             │
│  │  Hidden if: not configured in Shopify Admin      │
│  │  Features:                                       │
│  │    • Full-width image (340px height)             │
│  │    • Gradient overlay with text                  │
│  │    • Optional CTA button                         │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 3 — CATEGORY NAV CHIPS                  │
│  │  Source: Store main navigation menu API          │
│  │  Hidden if: store has no main menu configured    │
│  │  Features:                                       │
│  │    • Horizontal scrollable chips                 │
│  │    • Selected chip highlights in black           │
│  │    • Tap navigates to Shop tab                   │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 4 — WHY EARTHLY                         │
│  │  Source: Metaobject "why_earthly"                │
│  │  Hidden if: no entries configured                │
│  │  Features:                                       │
│  │    • Surface background (#FBF8F3)                │
│  │    • Section title + subtitle from metafield     │
│  │    • Icon + title + description rows             │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 5 — CUSTOMER REVIEWS                    │
│  │  Source 1: Metaobject "review"                   │
│  │  Source 2: Judge.me public API (if installed)    │
│  │  Source 3: Shopify SPR endpoint (legacy)         │
│  │  Hidden if: all 3 sources return nothing         │
│  │  Features:                                       │
│  │    • Star rating (1–5 gold stars)                │
│  │    • Review title + body text                    │
│  │    • Reviewer name + date                        │
│  │    • Product name (gold text)                    │
│  │    • Horizontal scrollable cards                 │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 6 — MOST LOVED PIECES                   │
│  │  Source: Shopify Products API (first 12)         │
│  │  Requires: NO extra Shopify Admin setup          │
│  │  Loading: shimmer skeleton cards                 │
│  │  Features:                                       │
│  │    • Section title from metafield or blank       │
│  │    • Horizontal scrollable product cards         │
│  │    • Product image, name, price, compare price   │
│  │    • "View All" → navigates to Shop tab          │
│  │    • Tap card → Product Detail Screen            │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 7 — SHOP BY CATEGORY                    │
│  │  Source: Shopify Collections API (first 8)       │
│  │  Requires: Collections must have cover images    │
│  │  Features:                                       │
│  │    • 2-column image grid                         │
│  │    • Collection title overlaid on image          │
│  │    • Tap → navigates to Shop tab                 │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 8 — SHOP BY OCCASION                    │
│  │  Source: Collections by specific handle          │
│  │    (engagement, wedding, anniversary, birthday)  │
│  │  Hidden if: these collection handles don't exist │
│  │  Features:                                       │
│  │    • Horizontal scrollable tiles (140px wide)    │
│  │    • Occasion name overlaid on image             │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 9 — CTA BANNER                          │
│  │  Source: Metaobject "cta"                        │
│  │  Hidden if: not configured in Shopify Admin      │
│  │  Features:                                       │
│  │    • With image: full-width photo background     │
│  │    • Without image: solid dark block             │
│  │    • Title + subtitle + outline button           │
│  └──────────────────────────────────────────────────┘
│
│  ┌──────────────────────────────────────────────────┐
│  │  SECTION 10 — FOOTER                             │
│  │  Source: Shop brand API + main menu              │
│  │  Features:                                       │
│  │    • Store name (uppercase, letter-spaced)       │
│  │    • Store slogan (italic)                       │
│  │    • Store description                           │
│  │    • Navigation links (from menu API)            │
│  │    • Auto copyright year                         │
│  └──────────────────────────────────────────────────┘
```

---

# 5. PRODUCT BROWSING FLOW

```
┌────────────────────┐
│   Shop Tab (Tab 1) │
└─────────┬──────────┘
          │
          ▼
┌────────────────────────────────────────────┐
│  Products Screen                           │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ Collection filter chips (horizontal) │  │
│  │  All | Rings | Necklaces | Earrings  │  │
│  │         Source: Collections API      │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  Product Grid (2 columns)            │  │
│  │  ┌──────────┐  ┌──────────┐         │  │
│  │  │ Product  │  │ Product  │         │  │
│  │  │  Image   │  │  Image   │         │  │
│  │  │  Title   │  │  Title   │         │  │
│  │  │  Price   │  │  Price   │         │  │
│  │  └──────────┘  └──────────┘         │  │
│  │                                      │  │
│  │  Source: Products API / Collection   │  │
│  │  Loading: shimmer grid               │  │
│  └──────────────────────────────────────┘  │
└────────────────┬───────────────────────────┘
                 │ tap product card
                 ▼
        Product Detail Screen
```

---

# 6. PRODUCT DETAIL FLOW

```
┌─────────────────────────────────────────────────────┐
│  Product Detail Screen                              │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Image Gallery                                │  │
│  │  (horizontal swipe, up to 8 images)           │  │
│  │  Dot indicator below images                   │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  Product Title                                      │
│  Vendor / Brand Name                                │
│  Price    Compare-at Price (strikethrough)          │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Variant Selector                             │  │
│  │  (e.g. Size: 5 | 6 | 7 | 8 | 9)             │  │
│  │  (e.g. Material: Gold | Silver | Rose Gold)   │  │
│  │  Selected variant highlights in black         │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Quantity Selector   [−]  1  [+]              │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │         ADD TO CART (dark button)             │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  Product Description (expandable)                   │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Customer Reviews (for this product)          │  │
│  │  Rating summary + individual reviews          │  │
│  └───────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────┘
                       │ tap ADD TO CART
                       ▼
            ┌─────────────────────┐
            │  CartProvider       │
            │  addToCart()        │
            │  variantId, qty     │
            └──────────┬──────────┘
                       │
                       ▼
            Cart icon badge updates (+1)
            Success snackbar shows
```

---

# 7. SHOPPING CART & CHECKOUT FLOW

```
┌──────────────────────────────────────────────────┐
│  Cart Screen                                     │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  Cart Item Card (per line item)            │  │
│  │  ┌──────┐                                  │  │
│  │  │Image │  Product Title                   │  │
│  │  │      │  Variant (Size 7, Gold)           │  │
│  │  │      │  Price per item                  │  │
│  │  └──────┘  [−] Quantity [+]    🗑 Remove   │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  Order Summary                             │  │
│  │  Subtotal:              ₹ X,XXX            │  │
│  │  Shipping:              Calculated at      │  │
│  │                         checkout           │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │          PROCEED TO CHECKOUT               │  │
│  └──────────────────┬─────────────────────────┘  │
└─────────────────────┼────────────────────────────┘
                      │
                      ▼
         Opens: Shopify Hosted Checkout
         (cart.checkoutUrl in browser / webview)
                      │
                      ▼
         ┌────────────────────────┐
         │  Customer enters:      │
         │  • Contact info        │
         │  • Shipping address    │
         │  • Shipping method     │
         │  • Payment details     │
         └───────────┬────────────┘
                     │ order placed
                     ▼
         Order confirmation email sent
                     │
                     ▼
         Order appears in Account → My Orders


CART ACTIONS
─────────────────────────────────────────────────
Increase qty  →  CartProvider.updateCartLine()
Decrease qty  →  CartProvider.updateCartLine()
               (if qty reaches 0 → removes item)
Remove item   →  CartProvider.removeFromCart()
Empty cart    →  Shows empty state illustration
```

---

# 8. SEARCH FLOW

```
┌─────────────────────────────────────────────┐
│  Search Screen                              │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  🔍  Search jewellery...            │    │
│  └──────────────┬──────────────────────┘    │
│                 │ user types                │
│                 ▼                           │
│     ProductProvider.search(query)           │
│     → API: products(query: "...")           │
│                 │                           │
│       ┌─────────┴──────────┐               │
│       │                    │               │
│  Loading state        Results grid         │
│  (shimmer)            (2 columns)          │
│                            │               │
│                    tap product card        │
│                            │               │
└────────────────────────────┼───────────────┘
                             ▼
                   Product Detail Screen


SEARCH STATES
──────────────────────────────────────────────
Empty input   →  Show recent searches / blank
Loading       →  Shimmer skeleton grid
No results    →  "No results for 'xyz'"
Has results   →  Product grid (image, name, price)
```

---

# 9. CUSTOMER ACCOUNT FLOW

```
Account Screen (Tab 4)
│
├─── IF NOT LOGGED IN ─────────────────────────────
│    │
│    │  ┌──────────────────────────────────────┐
│    │  │  👤  Welcome!                        │
│    │  │  Sign in to view orders, wishlist    │
│    │  │  & exclusive deals                   │
│    │  │                                      │
│    │  │  [ SIGN IN ]                         │
│    │  └──────────────────────────────────────┘
│    │
│    │  Common menu items:
│    │  ├── Book Store Visit
│    │  ├── Virtual Consultation
│    │  ├── FAQ
│    │  ├── Contact Us
│    │  ├── Privacy Policy
│    │  └── Terms & Conditions
│    │
│    │  Sign In / Create Account → Login Screen
│
└─── IF LOGGED IN ─────────────────────────────────
     │
     │  ┌──────────────────────────────────────┐
     │  │  ●  J K   (initials avatar)          │
     │  │     Jinal Kumar                      │
     │  │     jinal@example.com                │
     │  │     +91 98765 43210 (if set)         │
     │  └──────────────────────────────────────┘
     │
     │  Account menu items:
     │  ├── My Orders ──────────────► Orders Screen
     │  ├── Wishlist ───────────────► (Planned)
     │  ├── Saved Addresses ────────► (Planned)
     │  └── Earthly Elite Membership► (Planned)
     │
     │  Common menu items:
     │  ├── Book Store Visit
     │  ├── Virtual Consultation
     │  ├── FAQ
     │  ├── Contact Us
     │  ├── Privacy Policy
     │  └── Terms & Conditions
     │
     │  ├── Sign Out
     │  │   └── Confirmation dialog
     │  │       ├── Cancel → dismiss
     │  │       └── Confirm → logout
     │  │           ├── Delete token from Shopify
     │  │           ├── Clear from memory
     │  │           └── Clear from SharedPreferences
     │
     └── Visit Us (if configured in Shopify Admin)
         ├── 📍 Store address
         ├── 🕐 Store hours
         ├── 📞 Phone number
         └── ✉️  Email address
```

---

# 10. LOGIN & REGISTRATION FLOW

```
┌─────────────────────────────────────────────────────┐
│  Login Screen                                       │
│                                                     │
│  ┌─────────────────┬───────────────────────────┐    │
│  │    SIGN IN      │     CREATE ACCOUNT        │    │
│  └─────────────────┴───────────────────────────┘    │
│                                                     │
├── SIGN IN TAB ──────────────────────────────────────┤
│                                                     │
│   Email ________________________________            │
│   Password _____________________________  👁        │
│                        Forgot password?             │
│                                                     │
│   ┌─────────────────────────────────────────┐       │
│   │                SIGN IN                  │       │
│   └─────────────────────────────────────────┘       │
│                                                     │
│   SIGN IN flow:                                     │
│   ├── Validate fields not empty                     │
│   ├── Show loading spinner on button                │
│   ├── API: customerAccessTokenCreate mutation       │
│   │   ├── Error → Red error banner (dismissible)    │
│   │   └── Success → token received                  │
│   ├── API: fetch customer profile                   │
│   ├── Save token to SharedPreferences               │
│   └── Close screen → Account tab updates            │
│                                                     │
│   FORGOT PASSWORD flow:                             │
│   ├── Email field must not be empty                 │
│   ├── API: customerRecover mutation                 │
│   └── Shopify sends reset email to user             │
│                                                     │
├── CREATE ACCOUNT TAB ───────────────────────────────┤
│                                                     │
│   First Name ___________  Last Name ___________     │
│   Email ________________________________            │
│   Password _____________________________  👁        │
│                                                     │
│   ┌─────────────────────────────────────────┐       │
│   │            CREATE ACCOUNT               │       │
│   └─────────────────────────────────────────┘       │
│                                                     │
│   REGISTER flow:                                    │
│   ├── API: customerCreate mutation                  │
│   │   ├── Error → Red error banner (dismissible)    │
│   │   └── Success → account created                 │
│   ├── Auto-login (calls login internally)           │
│   ├── API: fetch customer profile                   │
│   ├── Save token to SharedPreferences               │
│   └── Close screen → Account tab updates            │
└─────────────────────────────────────────────────────┘


SESSION MANAGEMENT
──────────────────────────────────────────────────────
App start     → Read "customer_token" from SharedPreferences
Token found   → Verify with Shopify API
Token valid   → User is logged in (no login screen shown)
Token expired → Clear token → guest mode
App install   → No token → guest mode
Logout        → Delete token from Shopify + SharedPreferences
```

---

# 11. ORDER HISTORY FLOW

```
Account Screen → My Orders
│
▼
┌───────────────────────────────────────────────────┐
│  Orders Screen                                    │
│                                                   │
│  On open: CustomerProvider.loadOrders()           │
│  API: customer { orders(first: 20, reverse: true)}│
│                                                   │
│  ┌─── LOADING STATE ────────────────────────────┐ │
│  │  [shimmer card]                              │ │
│  │  [shimmer card]                              │ │
│  │  [shimmer card]                              │ │
│  └──────────────────────────────────────────────┘ │
│                                                   │
│  ┌─── EMPTY STATE ──────────────────────────────┐ │
│  │       🛍                                     │ │
│  │    No orders yet                             │ │
│  │  Your order history will appear here.        │ │
│  └──────────────────────────────────────────────┘ │
│                                                   │
│  ┌─── ORDER LIST ───────────────────────────────┐ │
│  │                                              │ │
│  │  ┌──────────────────────────────────────┐    │ │
│  │  │  ┌──────┐  Order #1023              │    │ │
│  │  │  │      │  15 Aug 2026      ₹4,500  │    │ │
│  │  │  │ img  │                           │    │ │
│  │  │  │      │  Diamond Ring — Gold × 1  │    │ │
│  │  │  └──────┘  Pearl Necklace × 2       │    │ │
│  │  │                                     │    │ │
│  │  │  [  ✅ Delivered  ]                 │    │ │
│  │  └──────────────────────────────────────┘    │ │
│  │                                              │ │
│  │  ┌──────────────────────────────────────┐    │ │
│  │  │  ┌──────┐  Order #1018              │    │ │
│  │  │  │      │  02 Aug 2026     ₹12,000  │    │ │
│  │  │  │ img  │                           │    │ │
│  │  │  │      │  Gold Bangle Set × 1      │    │ │
│  │  │  └──────┘                           │    │ │
│  │  │  [  🟠 Processing  ]                │    │ │
│  │  └──────────────────────────────────────┘    │ │
│  └──────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘


ORDER STATUS BADGE COLOURS
──────────────────────────────────────────────────────
FULFILLED            →  🟢 Green    "Delivered"
UNFULFILLED          →  🟠 Orange   "Processing"
PARTIALLY_FULFILLED  →  🔵 Blue     "Partially Delivered"
IN_PROGRESS          →  ⚪ Grey     "In Progress"
```

---

# 12. WISHLIST FLOW (Planned)

```
STATUS: Not yet implemented

PLANNED FLOW:
Product Detail Screen
│
▼
❤ Add to Wishlist button
│
▼
CustomerProvider.addToWishlist(productId)
│
├── API: customerUpdate mutation
│   └── Stores product IDs in customer metafield
│
▼
Account → Wishlist Screen
│
└── Loads product IDs from customer metafield
    └── Fetches product details for each ID
        └── Shows product grid (same as shop)
            └── Tap → Product Detail Screen
```

---

# 13. NOTIFICATION FLOW (Planned)

```
STATUS: Not yet implemented

PLANNED FLOW:

Push Notification Types:
├── Order Status Update
│     "Your order #1023 has been shipped! 🚚"
│
├── New Collection Launch
│     "New arrivals just dropped ✨"
│
├── Exclusive Offer
│     "20% off for Earthly Elite members today only"
│
└── Abandoned Cart Reminder
      "Your cart is waiting for you 💍"


Technical Requirements:
├── Firebase Cloud Messaging (FCM)
├── Shopify Webhook → Server → FCM → App
└── Notification permission request on first launch
```

---

# 14. API & DATA FLOW

### How data reaches the screen

```
Shopify Store (earthlyjewels.co)
        │
        │  GraphQL over HTTPS
        │  POST /api/2024-10/graphql.json
        │  Header: X-Shopify-Storefront-Access-Token
        │
        ▼
ShopifyService (singleton)
        │
        ├── _query(gql)            ← public data (no customer auth)
        └── _queryWithVars(gql)    ← customer mutations (secure vars)
        │
        ▼
Provider (ChangeNotifier)
        │
        ├── Stores data in memory
        ├── Calls notifyListeners()
        └── UI rebuilds automatically
        │
        ▼
Screen / Widget (Consumer<Provider>)
        │
        ├── Loading state → show shimmer
        ├── Empty state   → show SizedBox.shrink() (section hides)
        └── Has data      → render section
```

### Section → API Mapping

| Screen Section | API Call | Extra Setup Needed |
|---|---|---|
| Announcement bar | Metaobject "announcement" | Create in Shopify Admin |
| Hero banners | Metaobject "hero_banner" | Create in Shopify Admin |
| Hero banners (fallback) | Collections API | None — works automatically |
| Feature banner | Metaobject "feature_banner" | Create in Shopify Admin |
| Nav chips | Menu API (main-menu) | None — uses existing menu |
| Why Earthly | Metaobject "why_earthly" | Create in Shopify Admin |
| Reviews | Metaobject "review" / Judge.me | Create or install review app |
| Products | Products API | None — works automatically |
| Categories | Collections API | Collections need cover images |
| Occasions | Collection handles | Collections must exist |
| CTA banner | Metaobject "cta" | Create in Shopify Admin |
| Footer | Shop brand API | None — works automatically |
| Store info | Shop metafields (custom.*) | Create metafields in Admin |
| Section labels | Shop metafields (section.*) | Create metafields in Admin |

---

# 15. SHOPIFY ADMIN CONFIGURATION

### 15.1 Get Storefront API Token

```
1. Open: earthlyjewels.co/admin/settings/apps
2. Click: "Develop apps"
3. Open your app → "Configuration" tab
4. Enable Storefront API scopes:
   ✅ unauthenticated_read_product_listings
   ✅ unauthenticated_read_collection_listings
   ✅ unauthenticated_read_content
   ✅ unauthenticated_read_metaobjects
   ✅ unauthenticated_read_customers
   ✅ unauthenticated_write_customers
5. Click Save
6. Go to "API credentials" tab
7. Click "Reveal token once" → Copy
8. Paste into app_constants.dart → storefrontAccessToken
```

### 15.2 Create Metaobject Types
```
Admin → Content → Metaobjects → Add definition

Type: announcement
  • text  (Single line text)  ← the message to display

Type: hero_banner
  • image     (File — image)
  • title     (Single line text)
  • subtitle  (Single line text)
  • cta_text  (Single line text)

Type: feature_banner
  • image     (File — image)
  • title     (Single line text)
  • subtitle  (Single line text)
  • cta_text  (Single line text)

Type: why_earthly
  • icon   (Single line text — use emoji e.g. 💍)
  • title  (Single line text)
  • body   (Multi-line text)

Type: review
  • rating         (Integer, 1–5)
  • reviewer_name  (Single line text)
  • title          (Single line text)
  • body           (Multi-line text)

Type: cta
  • title     (Single line text)
  • subtitle  (Single line text)
  • cta_text  (Single line text)
  • image     (File — image, optional)

⚠️ After creating each type:
   → Enable "Storefront API access" in the type settings
   → Add entries with actual content
```

### 15.3 Create Shop Metafields
```
Admin → Settings → Custom data → Shop → Add field

For section titles (shown as heading above each section):
  namespace: section  |  key: featured_products  |  value: "Most Loved Pieces"
  namespace: section  |  key: why_earthly         |  value: "Why Earthly Jewels"
  namespace: section  |  key: why_earthly_subtitle|  value: "More than just jewellery"
  namespace: section  |  key: reviews             |  value: "What Our Customers Say"
  namespace: section  |  key: categories          |  value: "Shop by Category"
  namespace: section  |  key: occasions           |  value: "Shop by Occasion"

For store contact info (shown in Account screen):
  namespace: custom  |  key: store_address  |  value: "123 Jewel Street, Mumbai"
  namespace: custom  |  key: store_hours    |  value: "Mon–Sat: 10am – 8pm"
  namespace: custom  |  key: store_phone    |  value: "+91 98765 43210"
  namespace: custom  |  key: store_email    |  value: "hello@earthlyjewels.co"

⚠️ Enable "Storefront API access" on each metafield
⚠️ Fill in real values for your store
```

---

# 16. SCREEN INVENTORY

| Screen | File | Status |
|---|---|---|
| Home | home_screen.dart | ✅ Built |
| Products / Shop | products_screen.dart | ✅ Built |
| Product Detail | product_detail_screen.dart | ✅ Built |
| Cart | cart_screen.dart | ✅ Built |
| Search | search_screen.dart | ✅ Built |
| Account | account_screen.dart | ✅ Built |
| Login & Register | login_screen.dart | ✅ Built |
| Orders History | orders_screen.dart | ✅ Built |
| Wishlist | — | ⬜ Planned |
| Saved Addresses | — | ⬜ Planned |
| Notifications | — | ⬜ Planned |
| Book Store Visit | — | ⬜ Planned |

---

# 17. FEATURE STATUS

### ✅ Completed Features

| Feature | Details |
|---|---|
| Dynamic home content | All 10 sections from Shopify API |
| Hero banner slider | Auto-play, swipe, dot indicators |
| Announcement bar | Scrolling ticker, dynamic messages |
| Product listing | Grid view with shimmer loading |
| Product detail | Image gallery, variant selector, price |
| Add to cart | With quantity, variant selection |
| Cart management | Add, update quantity, remove items |
| Shopify checkout | Opens official Shopify checkout URL |
| Product search | Live search with results grid |
| Customer login | Email + password, error handling |
| Customer register | Auto-login after registration |
| Forgot password | Email-based Shopify reset flow |
| Session persistence | Stays logged in across app restarts |
| Order history | List with thumbnails + status badges |
| Dynamic account | Guest vs logged-in states |
| Store info | Address, hours, phone, email from API |
| Shimmer loading | All major sections |
| Zero console logs | No API logs in production |

### ⬜ Planned Features

| Feature | Priority | What's Needed |
|---|---|---|
| Wishlist | High | Customer metafield for saved product IDs |
| Saved Addresses | High | customerAddressCreate/Update mutations |
| Product filtering | Medium | Filter by price range, tag, availability |
| Push notifications | Medium | Firebase FCM + Shopify webhook server |
| Book Store Visit | Low | Booking URL or third-party booking app |
| Virtual Consultation | Low | Video call booking link |
| Membership / Loyalty | Low | Custom loyalty program logic |
| Product reviews (submit) | Medium | Review app API (Judge.me / Loox) |
| Referral program | Low | Custom referral tracking |
| Augmented Reality try-on | Low | V Tryon app integration |

---

*Document Version: 1.0*
*Project: Earthly Jewels Customer Mobile App*
*Last Updated: 2026-09-02*
