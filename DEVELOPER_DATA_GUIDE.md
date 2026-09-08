# Earthly Jewels — Developer Data Entry Guide
### Exact field names, types & sample data to enter in Shopify Admin

---

## HOW TO CREATE METAOBJECTS
```
Shopify Admin → Content → Metaobjects → Add definition
```

---

## 1. ANNOUNCEMENT BAR

**Definition Name:** `announcement`

| Field Key | Field Type | Required | Example Value |
|---|---|---|---|
| `text` | Single line text | ✅ Yes | `Free shipping on orders above ₹5,000` |

**Add these entries (3 announcements):**
```
Entry 1 → text = "Free shipping on orders above ₹5,000"
Entry 2 → text = "New collection launching this Diwali ✨"
Entry 3 → text = "Visit our store — Mon to Sat, 10am to 8pm"
```
> ⚠️ After creating type → go to **Storefront API access** → enable it

---

## 2. HERO BANNER

**Definition Name:** `hero_banner`

| Field Key | Field Type | Required | Example Value |
|---|---|---|---|
| `image` | File (image) | ✅ Yes | Upload banner image |
| `title` | Single line text | ✅ Yes | `Crafted With Love` |
| `subtitle` | Single line text | ❌ Optional | `Timeless jewellery for every occasion` |
| `cta_text` | Single line text | ❌ Optional | `SHOP NOW` |

**Add these entries (3–5 banners):**
```
Entry 1:
  image    = [upload homepage banner 1]
  title    = "Crafted With Love"
  subtitle = "Timeless jewellery for every occasion"
  cta_text = "SHOP NOW"

Entry 2:
  image    = [upload homepage banner 2]
  title    = "New Arrivals"
  subtitle = "Discover our latest collection"
  cta_text = "EXPLORE"

Entry 3:
  image    = [upload homepage banner 3]
  title    = "Made For You"
  subtitle = "Custom jewellery crafted to order"
  cta_text = "CUSTOMISE"
```
> ⚠️ After creating type → enable **Storefront API access**

---

## 3. FEATURE / SECOND BANNER

**Definition Name:** `feature_banner`

| Field Key | Field Type | Required | Example Value |
|---|---|---|---|
| `image` | File (image) | ✅ Yes | Upload second banner image |
| `title` | Single line text | ✅ Yes | `The Bridal Edit` |
| `subtitle` | Single line text | ❌ Optional | `Everything for your perfect day` |
| `cta_text` | Single line text | ❌ Optional | `SHOP BRIDAL` |

**Add 1 entry:**
```
Entry 1:
  image    = [upload feature banner image]
  title    = "The Bridal Edit"
  subtitle = "Everything for your perfect day"
  cta_text = "SHOP BRIDAL"
```
> ⚠️ After creating type → enable **Storefront API access**

---

## 4. WHY EARTHLY SECTION

**Definition Name:** `why_earthly`

| Field Key | Field Type | Required | Example Value |
|---|---|---|---|
| `icon` | Single line text | ✅ Yes | `💎` (emoji) |
| `title` | Single line text | ✅ Yes | `Lab-Grown Diamonds` |
| `body` | Multi-line text | ✅ Yes | `Certified, conflict-free stones` |

**Add these entries (3–5 values):**
```
Entry 1:
  icon  = 💎
  title = "Lab-Grown Diamonds"
  body  = "Every stone is IGI certified and ethically sourced"

Entry 2:
  icon  = 🚚
  title = "Free Insured Shipping"
  body  = "Pan-India delivery, fully insured at no extra cost"

Entry 3:
  icon  = ↩️
  title = "15-Day Easy Returns"
  body  = "Changed your mind? No questions asked returns"

Entry 4:
  icon  = 🏆
  title = "Lifetime Warranty"
  body  = "We stand behind every piece we make, forever"

Entry 5:
  icon  = ✨
  title = "Certified Quality"
  body  = "Every piece hallmarked and quality checked"
```
> ⚠️ After creating type → enable **Storefront API access**

---

## 5. CUSTOMER REVIEWS

**Definition Name:** `review`

| Field Key | Field Type | Required | Example Value |
|---|---|---|---|
| `rating` | Integer (1–5) | ✅ Yes | `5` |
| `reviewer_name` | Single line text | ✅ Yes | `Priya Sharma` |
| `title` | Single line text | ❌ Optional | `Absolutely stunning!` |
| `body` | Multi-line text | ✅ Yes | `I ordered the diamond ring...` |

**Add these entries (5–10 reviews):**
```
Entry 1:
  rating        = 5
  reviewer_name = "Priya Sharma"
  title         = "Absolutely stunning!"
  body          = "I ordered the diamond ring for my engagement and it exceeded all expectations. The quality is outstanding and the packaging was beautiful."

Entry 2:
  rating        = 5
  reviewer_name = "Ankit Mehta"
  title         = "Perfect anniversary gift"
  body          = "My wife absolutely loved the necklace. The craftsmanship is excellent and delivery was super fast."

Entry 3:
  rating        = 5
  reviewer_name = "Sneha Patel"
  title         = "Worth every rupee"
  body          = "The earrings are even more beautiful in person. Great customer service too. Will definitely order again!"

Entry 4:
  rating        = 4
  reviewer_name = "Rahul Joshi"
  title         = "Great quality"
  body          = "Very happy with my purchase. The ring looks premium and the sizing was perfect."

Entry 5:
  rating        = 5
  reviewer_name = "Meera Iyer"
  title         = "Loved it!"
  body          = "Ordered for my mom's birthday and she was thrilled. The presentation box made it extra special."
```
> ⚠️ After creating type → enable **Storefront API access**

---

## 6. CTA BANNER (Call to Action)

**Definition Name:** `cta`

| Field Key | Field Type | Required | Example Value |
|---|---|---|---|
| `title` | Single line text | ✅ Yes | `Design Your Dream Ring` |
| `subtitle` | Single line text | ❌ Optional | `Book a free virtual consultation` |
| `cta_text` | Single line text | ✅ Yes | `BOOK NOW` |
| `image` | File (image) | ❌ Optional | Upload background image |

**Add 1 entry:**
```
Entry 1:
  title    = "Design Your Dream Ring"
  subtitle = "Work with our experts to create your perfect piece"
  cta_text = "BOOK A CONSULTATION"
  image    = [upload dark/moody background image — optional]
```
> ⚠️ After creating type → enable **Storefront API access**
> 💡 If no image is uploaded, app shows solid dark background automatically

---

---

## HOW TO CREATE SHOP METAFIELDS
```
Shopify Admin → Settings → Custom data → Shop → Add field
```

---

## 7. SECTION TITLE LABELS

These are the heading texts shown above each section on the home screen.

**For each field below:**
- Namespace = `section`
- Type = `Single line text`
- Enable **Storefront API access** = ✅ Yes

| Field Key | Display Value to Enter |
|---|---|
| `featured_products` | `Most Loved Pieces` |
| `why_earthly` | `Why Earthly Jewels` |
| `why_earthly_subtitle` | `More than just jewellery` |
| `reviews` | `What Our Customers Say` |
| `categories` | `Shop by Category` |
| `occasions` | `Shop by Occasion` |

**Step by step for each:**
```
1. Click "Add field"
2. Type = Single line text
3. Name = (use the key name from table above)
4. Namespace = section
5. Key = (exact key from table above)
6. Save
7. Go to field → Enable "Storefront API access"
8. Go to field → Enter the value from table above
```

---

## 8. STORE CONTACT INFORMATION

These show inside the Account screen under "Visit Us".

**For each field below:**
- Namespace = `custom`
- Type = `Single line text`
- Enable **Storefront API access** = ✅ Yes

| Field Key | Example Value to Enter |
|---|---|
| `store_address` | `Shop No. 5, Jewellers Lane, Bandra West, Mumbai 400050` |
| `store_hours` | `Monday to Saturday: 10:00 AM – 8:00 PM` |
| `store_phone` | `+91 98765 43210` |
| `store_email` | `hello@earthlyjewels.co` |

> 💡 Fill in your actual store details. If left empty, "Visit Us" section is hidden in the app.

---

---

## COLLECTIONS SETUP

### 9. Add Cover Images to Collections
```
Shopify Admin → Products → Collections → [click collection]
→ Scroll to "Collection image" → Upload image
```

**Collections that need images:**
| Collection | Image Needed |
|---|---|
| Rings | ✅ Square or landscape product photo |
| Necklaces | ✅ Square or landscape product photo |
| Earrings | ✅ Square or landscape product photo |
| Bracelets | ✅ Square or landscape product photo |
| Bangles | ✅ Square or landscape product photo |

---

### 10. Occasion Collections
These collection handles MUST exist exactly as written:

| Handle (exact) | Collection Title |
|---|---|
| `engagement` | Engagement |
| `wedding` | Wedding |
| `anniversary` | Anniversary |
| `birthday` | Birthday |

```
To create:
Shopify Admin → Products → Collections → Create collection
  Title  = Engagement
  Handle = engagement   ← must match exactly
  Add products to this collection
  Add a cover image
```

---

## STORE BRAND SETUP

### 11. Upload Store Logo
```
Shopify Admin → Settings → Brand
  → Upload Logo (shown in app header)
  → Upload Square Logo (optional)
  → Add Slogan (shown in footer)
  → Add Short Description
```
> ⚠️ Logo is required for the app header. Without it, store name text is shown.

---

## NAVIGATION MENU

### 12. Main Menu
```
Shopify Admin → Content → Navigation → Main menu
  Handle must be: main-menu

Add menu items:
  - Rings        → link to rings collection
  - Necklaces    → link to necklaces collection
  - Earrings     → link to earrings collection
  - Bracelets    → link to bracelets collection
  - All Jewellery → link to all products
```
> ⚠️ Menu handle must be `main-menu` (hyphen, lowercase)

---

---

## STOREFRONT API TOKEN

### 13. Generate & Share Token
```
Shopify Admin → Settings → Apps → Develop apps
  → Open app → Configuration tab
  → Storefront API integration → Enable these scopes:

  ✅ unauthenticated_read_product_listings
  ✅ unauthenticated_read_collection_listings
  ✅ unauthenticated_read_content
  ✅ unauthenticated_read_metaobjects
  ✅ unauthenticated_read_customers
  ✅ unauthenticated_write_customers
  ✅ unauthenticated_read_customer_tags

  → Save
  → API credentials tab
  → Click "Reveal token once"
  → Copy and send to Flutter developer
```

---

## DEVELOPER COMPLETION CHECKLIST

```
METAOBJECTS
[ ] Created type: announcement    + enabled Storefront API access + added entries
[ ] Created type: hero_banner     + enabled Storefront API access + added 3–5 entries
[ ] Created type: feature_banner  + enabled Storefront API access + added 1 entry
[ ] Created type: why_earthly     + enabled Storefront API access + added 4–5 entries
[ ] Created type: review          + enabled Storefront API access + added 5–10 entries
[ ] Created type: cta             + enabled Storefront API access + added 1 entry

SHOP METAFIELDS — namespace: section
[ ] featured_products    → value entered + Storefront API access enabled
[ ] why_earthly          → value entered + Storefront API access enabled
[ ] why_earthly_subtitle → value entered + Storefront API access enabled
[ ] reviews              → value entered + Storefront API access enabled
[ ] categories           → value entered + Storefront API access enabled
[ ] occasions            → value entered + Storefront API access enabled

SHOP METAFIELDS — namespace: custom
[ ] store_address  → value entered + Storefront API access enabled
[ ] store_hours    → value entered + Storefront API access enabled
[ ] store_phone    → value entered + Storefront API access enabled
[ ] store_email    → value entered + Storefront API access enabled

COLLECTIONS
[ ] All main collections have cover images uploaded
[ ] Collection handle "engagement"   exists with cover image
[ ] Collection handle "wedding"      exists with cover image
[ ] Collection handle "anniversary"  exists with cover image
[ ] Collection handle "birthday"     exists with cover image

BRAND & NAVIGATION
[ ] Store logo uploaded in Settings → Brand
[ ] Main menu exists with handle: main-menu
[ ] Menu has at least 3–5 items

STOREFRONT API TOKEN
[ ] Token generated with all required scopes
[ ] Token shared with Flutter developer
```

---

