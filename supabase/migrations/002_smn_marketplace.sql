-- SMN Marketplace – full schema
-- Run after 001 or on a fresh project. Uses auth.users for identity.

-- Extended user (phone, email from auth or our store)
create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  phone text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Roles: user pays ₹15 per role; profile unlocked after payment
create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  role text not null check (role in ('business_owner', 'creator', 'videographer', 'freelancer')),
  paid_at timestamptz,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);
create index roles_user_id_idx on public.roles (user_id);

-- Provider profiles (creator / videographer / freelancer) – identity hidden until order accepted
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  role text not null check (role in ('creator', 'videographer', 'freelancer')),
  display_name text,
  bio text,
  instagram_handle text,
  youtube_channel_id text,
  instagram_connected_at timestamptz,
  youtube_connected_at timestamptz,
  analytics_json jsonb,
  bank_verified boolean not null default false,
  upi_verified boolean not null default false,
  is_live boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, role)
);
create index profiles_user_id_idx on public.profiles (user_id);
create index profiles_role_live_idx on public.profiles (role, is_live) where is_live = true;

-- Categories (predefined per role type)
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role_type text not null check (role_type in ('creator', 'videographer', 'freelancer')),
  sort_order int not null default 0
);

-- Predefined services per category (creator picks from these and sets only price)
create table if not exists public.predefined_services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories (id) on delete cascade,
  name text not null,
  sort_order int not null default 0
);

-- Provider's offered services (price, delivery_days, demo_video, addons)
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  predefined_service_id uuid references public.predefined_services (id) on delete set null,
  name text not null,
  price_inr decimal(12,2) not null check (price_inr >= 10),
  delivery_days int,
  demo_video_url text,
  addons_json jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index services_profile_id_idx on public.services (profile_id);

-- Cart (business owner): multi-service before payment
create table if not exists public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);
create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts (id) on delete cascade,
  service_id uuid not null references public.services (id) on delete cascade,
  quantity int not null default 1 check (quantity >= 1),
  unique (cart_id, service_id)
);

-- Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.users (id) on delete restrict,
  provider_id uuid not null references public.users (id) on delete restrict,
  profile_id uuid not null references public.profiles (id) on delete restrict,
  status text not null default 'pending' check (status in (
    'pending', 'in_progress', 'delivered', 'revision', 'completed', 'failed'
  )),
  proposed_deadline timestamptz,
  accepted_deadline timestamptz,
  total_inr decimal(12,2) not null,
  platform_charge_inr decimal(12,2) not null default 49,
  chat_unlocked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index orders_buyer_id_idx on public.orders (buyer_id);
create index orders_provider_id_idx on public.orders (provider_id);
create index orders_status_idx on public.orders (status);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  service_id uuid not null references public.services (id) on delete restrict,
  service_name text not null,
  price_inr decimal(12,2) not null,
  quantity int not null default 1
);

-- Revisions (3 free, then paid)
create table if not exists public.revisions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  reason text not null check (length(reason) >= 20 and length(reason) <= 500),
  revision_number int not null,
  is_paid boolean not null default false,
  created_at timestamptz not null default now()
);

-- Payments (Razorpay)
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.orders (id) on delete set null,
  user_id uuid not null references public.users (id) on delete restrict,
  razorpay_order_id text,
  razorpay_payment_id text,
  amount_inr decimal(12,2) not null,
  status text not null default 'pending' check (status in ('pending', 'captured', 'failed', 'refunded')),
  role_verification_role text,
  created_at timestamptz not null default now()
);

-- Payouts to providers (after 14-day hold)
create table if not exists public.payouts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete restrict,
  order_id uuid not null references public.orders (id) on delete restrict,
  amount_inr decimal(12,2) not null,
  released_at timestamptz,
  created_at timestamptz not null default now()
);

-- Analytics (last 20 posts – engagement, avg views)
create table if not exists public.analytics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  source text not null check (source in ('instagram', 'youtube')),
  posts_json jsonb not null,
  engagement_percent decimal(5,2),
  avg_views decimal(12,2),
  updated_at timestamptz not null default now(),
  unique (profile_id, source)
);

-- Favorites (business saves providers)
create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, profile_id)
);

-- Chat (unlocked after creator accepts deadline)
create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade unique,
  created_at timestamptz not null default now()
);
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  sender_id uuid not null references public.users (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

-- Notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  title text not null,
  body text,
  type text,
  reference_id uuid,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_id_idx on public.notifications (user_id);

-- AI checks (NLP/OCR – block numbers, usernames, watermarks)
create table if not exists public.ai_checks (
  id uuid primary key default gen_random_uuid(),
  upload_type text not null,
  reference_id uuid not null,
  passed boolean not null,
  details_json jsonb,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.users enable row level security;
alter table public.roles enable row level security;
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.predefined_services enable row level security;
alter table public.services enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.revisions enable row level security;
alter table public.payments enable row level security;
alter table public.payouts enable row level security;
alter table public.analytics enable row level security;
alter table public.favorites enable row level security;
alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;
alter table public.notifications enable row level security;
alter table public.ai_checks enable row level security;

-- Users: own row
create policy "Users read own" on public.users for select using (auth.uid() = id);
create policy "Users update own" on public.users for update using (auth.uid() = id);
create policy "Users insert own" on public.users for insert with check (auth.uid() = id);

-- Roles: own rows
create policy "Roles read own" on public.roles for select using (
  exists (select 1 from public.users where id = user_id and id = auth.uid())
);
create policy "Roles insert own" on public.roles for insert with check (
  exists (select 1 from public.users where id = user_id and id = auth.uid())
);

-- Profiles: public read (no identity – no instagram_handle, etc. exposed until order); owner full access
create policy "Profiles public read limited" on public.profiles for select using (true);
create policy "Profiles update own" on public.profiles for update using (
  exists (select 1 from public.users where id = user_id and id = auth.uid())
);
create policy "Profiles insert own" on public.profiles for insert with check (
  exists (select 1 from public.users where id = user_id and id = auth.uid())
);

-- Categories, predefined_services: public read
create policy "Categories read all" on public.categories for select using (true);
create policy "Predefined services read all" on public.predefined_services for select using (true);

-- Services: public read active; profile owner manage
create policy "Services read active" on public.services for select using (is_active = true);
create policy "Services insert own profile" on public.services for insert with check (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);
create policy "Services update own profile" on public.services for update using (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);

-- Carts: own
create policy "Carts own" on public.carts for all using (user_id = auth.uid());
create policy "Cart items via cart" on public.cart_items for all using (
  exists (select 1 from public.carts where id = cart_id and user_id = auth.uid())
);

-- Orders: buyer or provider
create policy "Orders buyer or provider" on public.orders for select using (
  buyer_id = auth.uid() or provider_id = auth.uid()
);
create policy "Orders insert buyer" on public.orders for insert with check (buyer_id = auth.uid());
create policy "Orders update provider or buyer" on public.orders for update using (
  buyer_id = auth.uid() or provider_id = auth.uid()
);

-- Order items: via order
create policy "Order items via order" on public.order_items for select using (
  exists (select 1 from public.orders where id = order_id and (buyer_id = auth.uid() or provider_id = auth.uid()))
);

-- Revisions, payments, payouts: via order or own
create policy "Revisions via order" on public.revisions for select using (
  exists (select 1 from public.orders where id = order_id and (buyer_id = auth.uid() or provider_id = auth.uid()))
);
create policy "Payments own" on public.payments for select using (user_id = auth.uid());
create policy "Payouts own profile" on public.payouts for select using (
  exists (select 1 from public.profiles where id = profile_id and user_id = auth.uid())
);

-- Analytics: public read (metrics only), owner update
create policy "Analytics read all" on public.analytics for select using (true);
create policy "Analytics update own" on public.analytics for all using (
  exists (select 1 from public.profiles where id = profile_id and user_id = auth.uid())
);

-- Favorites: own
create policy "Favorites own" on public.favorites for all using (user_id = auth.uid());

-- Chat: via order
create policy "Chat rooms via order" on public.chat_rooms for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
create policy "Chat messages via room" on public.chat_messages for select using (
  exists (
    select 1 from public.chat_rooms r
    join public.orders o on o.id = r.order_id
    where r.id = room_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid())
  )
);

-- Notifications: own
create policy "Notifications own" on public.notifications for all using (user_id = auth.uid());

-- Sync users from auth
create or replace function public.handle_new_auth_user()
returns trigger as $$
begin
  insert into public.users (id, email) values (new.id, new.email)
  on conflict (id) do update set email = excluded.email, updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created_smn on auth.users;
create trigger on_auth_user_created_smn
  after insert on auth.users
  for each row execute procedure public.handle_new_auth_user();
