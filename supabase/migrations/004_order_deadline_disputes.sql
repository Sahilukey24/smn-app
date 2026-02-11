-- Order deadline rules, ready-for-delivery, counter proposals, disputes, auto-cancel
-- Run after 002_smn_marketplace.sql

-- Add columns to orders
alter table public.orders add column if not exists counter_proposals int not null default 0;
alter table public.orders add column if not exists ready_for_delivery_at timestamptz;
alter table public.orders add column if not exists last_proposal_at timestamptz;
alter table public.orders add column if not exists delivery_file_url text;
alter table public.orders add column if not exists payout_frozen boolean not null default false;

-- Extend status check to include disputed, cancelled
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check check (status in (
  'pending', 'in_progress', 'delivered', 'revision', 'completed', 'failed', 'disputed', 'cancelled'
));

-- 1 cart = 1 creator: store profile_id on cart
alter table public.carts add column if not exists profile_id uuid references public.profiles (id) on delete set null;

-- Disputes: freezes payout until resolved
create table if not exists public.disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete restrict unique,
  raised_by uuid not null references public.users (id) on delete restrict,
  reason text not null,
  status text not null default 'open' check (status in ('open', 'under_review', 'resolved', 'closed')),
  admin_notes text,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index disputes_order_id_idx on public.disputes (order_id);
create index disputes_status_idx on public.disputes (status);

alter table public.disputes enable row level security;

create policy "Disputes order parties" on public.disputes for select using (
  exists (
    select 1 from public.orders o
    where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid())
  )
);
create policy "Disputes insert by order party" on public.disputes for insert with check (
  raised_by = auth.uid()
  and exists (
    select 1 from public.orders o
    where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid())
  )
);

-- When dispute is created, freeze order payout
create or replace function public.on_dispute_created()
returns trigger as $$
begin
  update public.orders set payout_frozen = true, status = 'disputed', updated_at = now() where id = new.order_id;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_dispute_created on public.disputes;
create trigger on_dispute_created after insert on public.disputes for each row execute procedure public.on_dispute_created();

-- Order deliveries: signed URLs handled in app/storage; store key or path
create table if not exists public.order_deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  uploaded_by uuid not null references public.users (id) on delete restrict,
  file_path text not null,
  file_size_bytes bigint,
  created_at timestamptz not null default now()
);
create index order_deliveries_order_id_idx on public.order_deliveries (order_id);

alter table public.order_deliveries enable row level security;

create policy "Order deliveries order parties" on public.order_deliveries for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
create policy "Order deliveries insert provider" on public.order_deliveries for insert with check (
  uploaded_by = auth.uid()
  and exists (select 1 from public.orders o where o.id = order_id and o.provider_id = auth.uid() and o.ready_for_delivery_at is not null)
);
