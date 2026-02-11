-- Provider onboarding: profile defaults, provider_social, profile_predefined_services (max 4), rating

-- Profiles: base price and default delivery days for provider
alter table public.profiles add column if not exists base_price_inr decimal(12,2) check (base_price_inr is null or base_price_inr >= 10);
alter table public.profiles add column if not exists default_delivery_days int;
alter table public.profiles add column if not exists portfolio_links jsonb default '[]'; -- array of {url, label}
alter table public.profiles add column if not exists rating_avg decimal(3,2) default null; -- 0-5 for sort
alter table public.profiles add column if not exists rating_count int not null default 0;

-- Provider social (instagram, youtube, portfolio URLs) – optional separate table for multiple links
create table if not exists public.provider_social (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('instagram', 'youtube')),
  handle_or_url text not null,
  created_at timestamptz not null default now(),
  unique (profile_id, platform)
);
create index provider_social_profile_id_idx on public.provider_social (profile_id);

alter table public.provider_social enable row level security;
create policy "Provider social profile owner" on public.provider_social for all using (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);
create policy "Provider social read live" on public.provider_social for select using (
  exists (select 1 from public.profiles p where p.id = profile_id and p.is_live = true)
);

-- Provider service types: max 4 predefined_services per profile (enforced in app)
create table if not exists public.profile_predefined_services (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  predefined_service_id uuid not null references public.predefined_services (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (profile_id, predefined_service_id)
);
create index profile_predefined_services_profile_id_idx on public.profile_predefined_services (profile_id);

alter table public.profile_predefined_services enable row level security;
create policy "Profile predefined services profile owner" on public.profile_predefined_services for all using (
  exists (select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid())
);
create policy "Profile predefined services read" on public.profile_predefined_services for select using (true);
