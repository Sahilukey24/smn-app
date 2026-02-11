-- Revision request flow: order_revisions table + order revision fields

create table if not exists public.order_revisions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete restrict,
  reason text not null check (length(reason) >= 20 and length(reason) <= 500),
  is_paid boolean not null default false,
  amount decimal(12,2) not null default 0,
  created_at timestamptz not null default now()
);

create index order_revisions_order_id_idx on public.order_revisions (order_id);
create index order_revisions_user_id_idx on public.order_revisions (user_id);

alter table public.order_revisions enable row level security;

create policy "Order revisions order parties" on public.order_revisions for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);

create policy "Order revisions insert buyer" on public.order_revisions for insert with check (
  user_id = auth.uid()
  and exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
);

-- Orders: revision summary (updated when a revision is created)
alter table public.orders add column if not exists revision_count int not null default 0;
alter table public.orders add column if not exists last_revision_at timestamptz;
alter table public.orders add column if not exists revision_paid decimal(12,2) not null default 0;
