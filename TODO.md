# Earthly Jewels — App TODO & Action Plan

> **Priority Order:** Fix API first → Configure Shopify Admin → Implement pending features → Test → Release

---

## PHASE 1 — Fix API Connection (Do This First)

### 1.1 Get Correct Storefront API Token

- [ ] Open `https://earthlyjewels.co/admin/settings/apps`
- [ ] Click **"Develop apps"**
- [ ] Open your app → **Configuration** tab
- [ ] Enable Storefront API scopes:
  - [ ] `unauthenticated_read_product_listings`
  - [ ] `unauthenticated_read_collection_listings`
  - [ ] `unauthenticated_read_content`
  - [ ] `unauthenticated_read_metaobjects`
  - [ ] `unauthenticated_read_customers`
  - [ ] `unauthenticated_write_customers`
  - [ ] `unauthenticated_read_customer_tags`
- [ ] Click **Save**
- [ ] Go to **API credentials** tab
- [ ] Click **"Reveal token once"** → Copy the token
- [ ] Open `lib/core/constants/app_constants.dart`
- [ ] Replace token:
  ```dart
  static const String storefrontAccessToken = 'PASTE_NEW_TOKEN_HERE';
  ```
- [ ] Run `flutter run` → verify products load on home screen

**Expected after this step:**
- ✅ Hero banner shows (collection images as fallback)
- ✅ Products section shows (Most Loved Pieces)
- ✅ Shop by Category grid shows
- ✅ Footer shows store name
- ✅ No red error card at top of home screen

---

## PHASE 2 — Configure Shopify Admin Content

> These sections are hidden until you create content in Shopify Admin.
> Complete Phase 1 first.

### 2.1 Create Metaobject Types

Go to: `earthlyjewels.co/admin/content/metaobjects`

#### Announcement Bar
- [ ] Create type: `announcement`
- [ ] Add field: `text` (Single line text)
- [ ] Enable **Storefront API access**
- [ ] Add 1–3 entries with real announcement text
- [ ] **Result:** Announcement bar appears at top of home screen

#### Hero Banners
- [ ] Create type: `hero_banner`
- [ ] Add fields:
  - `image` (File — image)
  - `title` (Single line text)
  - `subtitle` (Single line text)
  - `cta_text` (Single line text)
- [ ] Enable **Storefront API access**
- [ ] Add 3–5 entries with real banner images
- [ ] **Result:** Hero slider shows branded images instead of collection fallback

#### Feature / Second Banner
- [ ] Create type: `feature_banner`
- [ ] Add fields:
  - `image` (File — image)
  - `title` (Single line text)
  - `subtitle` (Single line text)
  - `cta_text` (Single line text)
- [ ] Enable **Storefront API access**
- [ ] Add 1 entry
- [ ] **Result:** Second banner section appears below hero

#### Why Earthly Section
- [ ] Create type: `why_earthly`
- [ ] Add fields:
  - `icon` (Single line text — use emoji like 💍 ✨ 🌿)
  - `title` (Single line text)
  - `body` (Multi-line text)
- [ ] Enable **Storefront API access**
- [ ] Add 3–5 entries (e.g. Lab Grown, Free Shipping, 15-Day Returns, Warranty)
- [ ] **Result:** "Why Earthly" section appears on home screen

#### Customer Reviews
- [ ] Create type: `review`
- [ ] Add fields:
  - `rating` (Integer, 1–5)
  - `reviewer_name` (Single line text)
  - `title` (Single line text)
  - `body` (Multi-line text)
- [ ] Enable **Storefront API access**
- [ ] Add 5–10 real customer reviews
- [ ] **Result:** Reviews section appears on home screen

#### CTA Banner
- [ ] Create type: `cta`
- [ ] Add fields:
  - `title` (Single line text)
  - `subtitle` (Single line text)
  - `cta_text` (Single line text)
  - `image` (File — image, optional)
- [ ] Enable **Storefront API access**
- [ ] Add 1 entry
- [ ] **Result:** CTA section appears near bottom of home screen

---

### 2.2 Create Shop Metafields

Go to: `earthlyjewels.co/admin/settings/custom_data` → click **Shop** → **Add field**

#### Section Titles (labels above each home section)

- [ ] namespace: `section` | key: `featured_products` | value: `Most Loved Pieces`
- [ ] namespace: `section` | key: `why_earthly` | value: `Why Earthly Jewels`
- [ ] namespace: `section` | key: `why_earthly_subtitle` | value: `More than just jewellery`
- [ ] namespace: `section` | key: `reviews` | value: `What Our Customers Say`
- [ ] namespace: `section` | key: `categories` | value: `Shop by Category`
- [ ] namespace: `section` | key: `occasions` | value: `Shop by Occasion`

> ⚠️ Enable **Storefront API access** on every metafield

#### Store Info (appears in Account screen → "Visit Us")

- [ ] namespace: `custom` | key: `store_address` | value: your real address
- [ ] namespace: `custom` | key: `store_hours` | value: e.g. `Mon–Sat: 10am – 8pm`
- [ ] namespace: `custom` | key: `store_phone` | value: your phone number
- [ ] namespace: `custom` | key: `store_email` | value: your email address

> ⚠️ Enable **Storefront API access** on every metafield

---

### 2.3 Collection Cover Images

> Required for "Shop by Category" grid and hero banner fallback

- [ ] Go to `earthlyjewels.co/admin/collections`
- [ ] Open each collection → scroll to **Collection image**
- [ ] Upload a high-quality square or landscape image
- [ ] Do this for at least 4 main collections (Rings, Necklaces, Earrings, Bracelets)
- [ ] **Result:** Category grid appears on home screen with real images

---

### 2.4 Occasion Collections

> Required for "Shop by Occasion" section

- [ ] Go to `earthlyjewels.co/admin/collections`
- [ ] Verify these collection handles exist:
  - [ ] `engagement`
  - [ ] `wedding`
  - [ ] `anniversary`
  - [ ] `birthday`
- [ ] If missing → create collections with those exact handles
- [ ] Add cover images to each occasion collection
- [ ] **Result:** Occasions section appears on home screen

---

## PHASE 3 — Complete Product Detail Screen

> The screen is built. These are enhancements.

### 3.1 Make USP Strip Dynamic
**File:** `lib/presentation/screens/products/product_detail_screen.dart` (line 483)

Currently the USP strip (Certified Diamond / Free Shipping / Returns / Warranty) has static text.

- [ ] Create metaobject type: `product_usp`
  - field: `icon` (text/emoji)
  - field: `label` (single line text)
- [ ] Add fetch method in `ShopifyService`
- [ ] Load in `ShopProvider`
- [ ] Replace `_ProductUspStrip` static text with dynamic data
- [ ] **Result:** Store owner can update USP badges without app update

### 3.2 Share Product Button
- [ ] Add share icon in `_ImageGallerySliver` actions (line 142)
- [ ] Use `share_plus` package
- [ ] Share: `https://earthlyjewels.co/products/{handle}`

### 3.3 Size Guide Link
- [ ] Add "Size Guide" text button below variant selector
- [ ] Opens URL or bottom sheet with size chart image

---

## PHASE 4 — Implement Wishlist

**Status:** Button exists (no-op) in product detail + account screen menu

### 4.1 Data Layer
- [ ] Add `wishlist` field to Customer in Shopify
  - Go to: `earthlyjewels.co/admin/settings/custom_data` → **Customers** → Add field
  - namespace: `custom` | key: `wishlist` | type: JSON (list of product IDs)
  - Enable **Storefront API access**
- [ ] Add to `ShopifyService`:
  - `fetchWishlist(accessToken)` → returns `List<String>` (product IDs)
  - `addToWishlist(accessToken, productId)` → updates customer metafield
  - `removeFromWishlist(accessToken, productId)` → updates metafield

### 4.2 Provider
- [ ] Add `WishlistProvider` (or add to `CustomerProvider`)
  - `wishlistIds` — list of product IDs
  - `isWishlisted(productId)` — bool
  - `toggle(productId)` — add or remove
  - `loadWishlist()` — fetch on login

### 4.3 Screens
- [ ] Create `lib/presentation/screens/account/wishlist_screen.dart`
  - Shows product grid of wishlisted items
  - Fetch product details for each ID
  - Remove button on each card
- [ ] Wire up in `account_screen.dart` (currently no-op tap)

### 4.4 Product Detail
- [ ] Make ❤ heart icon in image gallery toggle wishlist state
- [ ] Make "ADD TO WISHLIST" button functional
- [ ] Show filled heart if already wishlisted

---

## PHASE 5 — Implement Saved Addresses

**Status:** Menu item exists (no-op) in account screen

### 5.1 Data Layer
- [ ] Add to `ShopifyService`:
  - `fetchAddresses(accessToken)` → `List<CustomerAddress>`
  - `addAddress(accessToken, address)` → `customerAddressCreate` mutation
  - `updateAddress(accessToken, id, address)` → `customerAddressUpdate`
  - `deleteAddress(accessToken, id)` → `customerAddressDelete`
  - `setDefaultAddress(accessToken, id)` → `customerDefaultAddressUpdate`

### 5.2 Model
- [ ] Create `CustomerAddress` model:
  - id, firstName, lastName, address1, address2, city, province, zip, country, phone, isDefault

### 5.3 Screens
- [ ] Create `lib/presentation/screens/account/addresses_screen.dart`
  - List of saved addresses
  - Default badge on default address
  - Add / Edit / Delete / Set Default actions
- [ ] Create `lib/presentation/screens/account/address_form_screen.dart`
  - Form: First/Last name, address fields, phone
  - Save button

---

## PHASE 6 — Product Filtering & Sorting

**Status:** Products screen shows all products, no filter

- [ ] Add filter chips: All | Rings | Necklaces | Earrings | Bracelets | Bangles
- [ ] Add sort options: Newest | Price Low–High | Price High–Low | Bestsellers
- [ ] Use collection handle filter when chip selected
- [ ] Add price range slider (optional)

---

## PHASE 7 — Polish & Performance

### 7.1 Remove Debug Error Card
After API is confirmed working:
- [ ] Remove the red error card from `home_screen.dart` (lines added for debugging)
- [ ] Remove error-only `debugPrint` from `shopify_service.dart`

### 7.2 Handle Empty States Better
- [ ] Products screen: Show message if collection is empty
- [ ] Search: Show popular searches when input is empty
- [ ] Cart: Add "Continue Shopping" button that goes to Shop tab

### 7.3 Pull-to-Refresh
- [ ] Home screen: Add `RefreshIndicator` to reload all sections
- [ ] Products screen: Refresh collection
- [ ] Orders screen: Refresh order list

### 7.4 Image Optimization
- [ ] Add `&width=800` to Shopify CDN image URLs to reduce bandwidth
- [ ] Example: `imageUrl + '?width=800&format=webp'`

---

## PHASE 8 — Before Release

### 8.1 Code Cleanup
- [ ] Run `flutter analyze lib/` → fix all warnings
- [ ] Remove `CUSTOMER_APP_PLAN.md`, `CUSTOMER_APP_FLOW.md`, `TODO.md` from release build
- [ ] Remove debug error card from home screen
- [ ] Remove error `debugPrint` from `shopify_service.dart`

### 8.2 Android Setup
- [ ] Update `android/app/src/main/AndroidManifest.xml` with correct package name
- [ ] Add internet permission (should already be there for http package)
- [ ] Update `android/app/build.gradle` with correct `applicationId`
- [ ] Set correct app name in `android/app/src/main/res/values/strings.xml`
- [ ] Replace app icon in `android/app/src/main/res/mipmap-*/`

### 8.3 iOS Setup
- [ ] Update `ios/Runner/Info.plist` with correct bundle ID
- [ ] Set app name: `CFBundleName = Earthly Jewels`
- [ ] Replace app icon in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 8.4 Testing Checklist
- [ ] Home screen loads all available sections
- [ ] Tap product → detail screen opens correctly
- [ ] Add to cart works
- [ ] Cart quantity update works
- [ ] Remove from cart works
- [ ] Checkout opens Shopify page
- [ ] Search returns results
- [ ] Customer can register new account
- [ ] Customer can log in
- [ ] Forgot password sends email
- [ ] Logged-in session persists after app restart
- [ ] Logout clears session
- [ ] Orders list loads for logged-in user
- [ ] App works on both Android and iOS

---

## CURRENT STATUS SUMMARY

| Phase | Task | Status |
|---|---|---|
| 1 | Get correct Storefront API token | ⬜ Blocked — need token from Shopify Admin |
| 2.1 | Create metaobject types | ⬜ Pending |
| 2.2 | Create shop metafields | ⬜ Pending |
| 2.3 | Add collection cover images | ⬜ Pending |
| 2.4 | Create occasion collections | ⬜ Pending |
| 3 | Product detail enhancements | ⬜ Pending |
| 4 | Wishlist feature | ⬜ Pending |
| 5 | Saved addresses | ⬜ Pending |
| 6 | Product filtering | ⬜ Pending |
| 7 | Polish & performance | ⬜ Pending |
| 8 | Pre-release checklist | ⬜ Pending |

### Already Done ✅
| Feature | File |
|---|---|
| Home screen (10 sections, dynamic) | home_screen.dart |
| Hero banner + carousel | home_screen.dart |
| Products listing | products_screen.dart |
| Product detail screen | product_detail_screen.dart |
| Image gallery + variants | product_detail_screen.dart |
| Add to cart | cart_provider.dart |
| Cart screen | cart_screen.dart |
| Shopify checkout link | cart_screen.dart |
| Product search | search_screen.dart |
| Customer login | login_screen.dart |
| Customer register | login_screen.dart |
| Forgot password | login_screen.dart |
| Session persistence | customer_provider.dart |
| Account screen (guest + logged in) | account_screen.dart |
| Order history + status badges | orders_screen.dart |
| Shimmer loading everywhere | multiple files |
| Dynamic store brand / logo | shop_provider.dart |
| Announcement bar | announcement_bar.dart |

---

## QUICK REFERENCE — Key Files

| What you want to change | File to edit |
|---|---|
| API token / domain | `lib/core/constants/app_constants.dart` |
| Colors | `lib/core/theme/app_colors.dart` |
| Fonts / text styles | `lib/core/theme/app_text_styles.dart` |
| Home page sections | `lib/presentation/screens/home/home_screen.dart` |
| Product detail UI | `lib/presentation/screens/products/product_detail_screen.dart` |
| API calls | `lib/data/services/shopify_service.dart` |
| Auth (login/logout) | `lib/data/providers/customer_provider.dart` |
| Cart logic | `lib/data/providers/cart_provider.dart` |
| Navigation / routes | `lib/core/routes/app_routes.dart` |

---

*Last updated: 2026-09-02*
