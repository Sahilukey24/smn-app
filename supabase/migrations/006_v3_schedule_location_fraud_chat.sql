-- V3: Schedule (date + time + duration), order_locations, revision fees, fraud_checks, chat strikes
-- Run after 005.

-- Schedule: date + start_time + duration (no text negotiation, max 2 counter proposals)
alter table public.orders add column if not exists scheduled_date date;
alter table public.orders add column if not exists start_time time;
alter table public.orders add column if not exists duration_minutes int;
alter table public.orders add column if not exists accepted_scheduled_date date;
alter table public.orders add column if not exists accepted_start_time time;
alter table public.orders add column if not exists accepted_duration_minutes int;

-- Location share: WhatsApp-style pin only (no address typing)
create table if not exists public.order_locations (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  lat decimal(10, 8) not null,
  lng decimal(11, 8) not null,
  shared_by uuid not null references public.users (id) on delete restrict,
  created_at timestamptz not null default now()
);
create index order_locations_order_id_idx on public.order_locations (order_id);

alter table public.order_locations enable row level security;
create policy "Order locations order parties" on public.order_locations for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
create policy "Order locations insert order party" on public.order_locations for insert with check (
  shared_by = auth.uid()
  and exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);

-- Revisions: paid amount (₹50 after first 3), fraud result
alter table public.revisions add column if not exists amount_inr decimal(12,2) not null default 0;
alter table public.revisions add column if not exists fraud_unchanged boolean not null default false;
alter table public.revisions add column if not exists delivery_id uuid references public.order_deliveries (id) on delete set null;

-- Fraud detection: perceptual hash, ffmpeg frame sampling, audio fingerprint → 90% = unchanged
create table if not exists public.fraud_checks (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  delivery_id uuid references public.order_deliveries (id) on delete set null,
  check_type text not null check (check_type in ('perceptual_hash', 'frame_sample', 'audio_fingerprint')),
  similarity_percent decimal(5,2) not null,
  is_unchanged boolean not null,
  details_json jsonb,
  created_at timestamptz not null default now()
);
create index fraud_checks_order_id_idx on public.fraud_checks (order_id);

alter table public.fraud_checks enable row level security;
create policy "Fraud checks order parties" on public.fraud_checks for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);

-- Chat: strike system (block numbers, emails, links; whitelist punctuation)
create table if not exists public.chat_strikes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  room_id uuid not null references public.chat_rooms (id) on delete cascade,
  strike_count int not null default 0,
  last_strike_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (user_id, room_id)
);
create index chat_strikes_room_id_idx on public.chat_strikes (room_id);

alter table public.chat_strikes enable row level security;
create policy "Chat strikes room parties" on public.chat_strikes for select using (
  exists (
    select 1 from public.chat_rooms r
    join public.orders o on o.id = r.order_id
    where r.id = room_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid())
  )
);
