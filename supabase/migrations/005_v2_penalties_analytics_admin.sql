-- V2: penalties, analytics_sources, manual_posts, order_deliveries (extend), admin_actions, tax_profiles
-- Run after 004.

-- Penalties: 2% per day after deadline, max 10%, grace 6h
create table if not exists public.penalties (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete restrict,
  penalty_percent decimal(5,2) not null check (penalty_percent >= 0 and penalty_percent <= 10),
  penalty_amount_inr decimal(12,2) not null,
  days_late int not null default 0,
  grace_applied boolean not null default false,
  created_at timestamptz not null default now()
);
create index penalties_order_id_idx on public.penalties (order_id);

alter table public.penalties enable row level security;
create policy "Penalties order parties" on public.penalties for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);

-- Analytics: hybrid API + manual; manual requires admin approval
create table if not exists public.analytics_sources (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  source_type text not null check (source_type in ('instagram_api', 'youtube_api', 'manual')),
  external_id text,
  is_approved boolean,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index analytics_sources_profile_id_idx on public.analytics_sources (profile_id);

create table if not exists public.manual_posts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  source_id uuid references public.analytics_sources (id) on delete set null,
  post_url text,
  views bigint,
  likes bigint,
  comments bigint,
  shares bigint,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.users (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
create index manual_posts_profile_id_idx on public.manual_posts (profile_id);
create index manual_posts_status_idx on public.manual_posts (status);

alter table public.analytics_sources enable row level security;
alter table public.manual_posts enable row level security;

create policy "Analytics sources profile owner" on public.analytics_sources for all using (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);
create policy "Analytics sources read all" on public.analytics_sources for select using (true);

create policy "Manual posts profile owner" on public.manual_posts for select using (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);
create policy "Manual posts insert owner" on public.manual_posts for insert with check (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);

-- Extend order_deliveries with file_type (mp4, mp3, pdf) and size limits enforced in app
alter table public.order_deliveries add column if not exists file_type text check (file_type in ('mp4', 'mp3', 'pdf'));

-- Admin actions: approve manual analytics, resolve disputes, release payouts, ban users
create table if not exists public.admin_actions (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.users (id) on delete restrict,
  action_type text not null check (action_type in (
    'approve_manual_post', 'reject_manual_post',
    'resolve_dispute', 'close_dispute',
    'release_payout', 'freeze_payout',
    'ban_user', 'unban_user'
  )),
  reference_type text not null,
  reference_id uuid not null,
  notes text,
  created_at timestamptz not null default now()
);
create index admin_actions_admin_id_idx on public.admin_actions (admin_id);
create index admin_actions_reference_idx on public.admin_actions (reference_type, reference_id);

-- Admin role and ban
alter table public.users add column if not exists is_admin boolean not null default false;
alter table public.users add column if not exists banned boolean not null default false;

alter table public.admin_actions enable row level security;
create policy "Admin actions admin select" on public.admin_actions for select using (
  exists (select 1 from public.users u where u.id = auth.uid() and u.is_admin = true)
);
create policy "Admin actions admin insert" on public.admin_actions for insert with check (
  admin_id = auth.uid()
  and exists (select 1 from public.users u where u.id = auth.uid() and u.is_admin = true)
);

-- Manual posts: admin can update status (approve/reject)
create policy "Manual posts admin update" on public.manual_posts for update using (
  exists (select 1 from public.users u where u.id = auth.uid() and u.is_admin = true)
);
create policy "Manual posts admin select" on public.manual_posts for select using (true);

-- Disputes: admin can update (resolve, close, add notes)
create policy "Disputes admin update" on public.disputes for update using (
  exists (select 1 from public.users u where u.id = auth.uid() and u.is_admin = true)
);
create policy "Disputes admin select" on public.disputes for select using (true);

-- Tax profiles (for payouts / invoicing)
create table if not exists public.tax_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade unique,
  pan text,
  gstin text,
  business_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index tax_profiles_user_id_idx on public.tax_profiles (user_id);

alter table public.tax_profiles enable row level security;
create policy "Tax profiles own" on public.tax_profiles for all using (user_id = auth.uid());

-- Orders: delivered_at for auto-complete 48h
alter table public.orders add column if not exists delivered_at timestamptz;

-- Storage bucket for order deliveries (mp4, mp3, pdf)
insert into storage.buckets (id, name, public)
values ('order-deliveries', 'order-deliveries', false)
on conflict (id) do nothing;

create policy "Order deliveries provider upload"
  on storage.objects for insert with check (
    bucket_id = 'order-deliveries' and auth.role() = 'authenticated'
  );
create policy "Order deliveries order parties read"
  on storage.objects for select using (
    bucket_id = 'order-deliveries'
    and exists (
      select 1 from public.order_deliveries d
      join public.orders o on o.id = d.order_id
      where d.file_path = name and (o.buyer_id = auth.uid() or o.provider_id = auth.uid())
    )
  );