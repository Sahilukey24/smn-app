# SMN – Social Media Network (Marketplace)

Production Flutter marketplace: business owners hire creators/videographers/freelancers with **hidden identity**, **calendar-only deadline negotiation**, **escrow**, **revisions**, and **analytics**.

---

## Core business logic

| Rule | Value |
|------|--------|
| Min service price | ₹10 |
| Platform fee | 6% |
| Gateway | 2% |
| Order charge | ₹49 (non-refundable) |
| Role verification | ₹15 per role |
| **1 cart** | **1 creator** (multiple services from same creator only) |
| **Deadline max** | **7 days** from today |
| **Counter proposals** | **Max 2** |
| **Auto cancel** | 48h no response (backend job) |
| Price edits | Do not affect running orders |
| Free revisions | 3 per order |
| File upload | Unlocked only after creator clicks **"Mark Ready for Delivery"** |
| Dispute | Freezes payout until resolved |
| Payout holding | 14 days |
| Max file size | 200MB |

---

## Architecture

```
lib/
├── core/                    # Constants, pricing, errors
│   ├── constants.dart
│   ├── pricing.dart
│   └── errors.dart
├── config/                  # Supabase, Razorpay, MSG91, etc. (env)
├── models/                  # Domain models
├── repositories/            # Data layer (Supabase)
│   ├── cart_repository.dart   # 1 cart = 1 creator
│   ├── order_repository.dart  # Deadline 7d, counter proposals 2
│   └── dispute_repository.dart
├── services/                # Application services
│   ├── marketplace/          # Auth, cart, order, profile, payment
│   ├── onboarding_service.dart
│   └── invoice_service.dart  # PDF invoice
├── features/                # Feature UI + widgets
│   ├── order/
│   │   └── widgets/
│   │       └── calendar_negotiation_widget.dart  # Calendar-only, max 7d, 2 counters
│   └── dispute/
│       └── dispute_screen.dart
├── screens/                 # App screens (marketplace, auth, etc.)
├── widgets/                 # Shared (earnings_calculator, analytics_chart)
└── router/
```

---

## Database (Supabase)

- Run **002_smn_marketplace.sql** then **004_order_deadline_disputes.sql**.
- **004** adds: `counter_proposals`, `ready_for_delivery_at`, `last_proposal_at`, `payout_frozen`, `carts.profile_id`, `disputes`, `order_deliveries`; trigger to set `payout_frozen` and status `disputed` on dispute create.
- Seed categories: **003_seed_categories_services.sql**.

---

## APIs

- **Supabase** – Auth, DB, Storage, RLS.
- **Razorpay** – Payments; webhook handler: `supabase/functions/razorpay-webhook/index.ts`. Set `RAZORPAY_WEBHOOK_SECRET` and point Razorpay to `https://<project>.supabase.co/functions/v1/razorpay-webhook`.
- **MSG91** – OTP (wire in auth).
- **Instagram Graph API / YouTube Data API** – Last 20 posts, engagement %, avg views.

---

## Security

- OCR/NLP filter for uploads (block numbers, emails, usernames); no links before accept; signed URLs for files; chat filter; abuse detection (backend/Edge).

---

## Run

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

## Implemented

- **Cart**: 1 creator only; `CartRepository` + `CartService`; mismatch shows SnackBar.
- **Order**: Deadline max 7 days; counter proposals max 2; `OrderRepository` + service.
- **Calendar negotiation**: `CalendarNegotiationWidget` – accept or propose new (calendar only).
- **Ready for Delivery**: Creator action; unlocks file upload (storage + `order_deliveries` in 004).
- **Dispute**: Raise from order detail; `DisputeRepository`; trigger freezes payout.
- **Invoice PDF**: `InvoiceService.generateOrderInvoice()`; download from order detail.
- **Analytics chart**: `AnalyticsChart` (fl_chart) on profile when `analytics_json` has data.
- **Razorpay webhook**: Edge Function for `payment.captured`; role verification + order payment rows.

---

## V2 rules

| Rule | Value |
|------|--------|
| **Penalty** | 2% per day after deadline, max 10%, grace 6 hours |
| **Auto complete** | 48h after delivery if buyer silent |
| **Analytics** | Hybrid: API + manual; manual requires admin approval |
| **File delivery** | MP4 200MB, MP3 50MB, PDF 20MB; upload only after "Ready for Delivery" |

**New tables (005):** `penalties`, `analytics_sources`, `manual_posts`, `order_deliveries` (extended with `file_type`), `admin_actions`, `tax_profiles`; `users.is_admin`, `users.banned`, `orders.delivered_at`.

**Services:** `delivery_service.dart` (file type/size validation, upload), `sla_service.dart` (penalty calculation, auto-complete/cancel helpers), `analytics_moderation.dart` (manual post submit, pending list), `admin_dispute_service.dart` (approve manual, resolve/close dispute, release payout, ban user).

**Admin UI:** `/admin` dashboard → Manual analytics (approve/reject), Disputes (resolve/close), Payouts (release frozen), Ban users. Shown in app bar when `users.is_admin = true`.

**Delivery UI:** Order detail shows "Upload delivery" when ready; `/order/:id/delivery` with file_picker (mp4/mp3/pdf) and size checks. Penalties listed on order detail when present.
