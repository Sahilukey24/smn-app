-- Order contract layer, payout splits, chat attachment, freelancer invite

-- order_contract: one per order, smart hiring contract (scope + price + revisions + dispute window)
create table if not exists public.order_contracts (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade unique,
  buyer_id uuid not null references public.users (id) on delete restrict,
  creator_id uuid not null references public.users (id) on delete restrict,
  freelancer_id uuid references public.users (id) on delete set null,
  base_price decimal(12,2) not null,
  platform_fee decimal(12,2) not null,
  creator_payout decimal(12,2) not null,
  escrow_locked boolean not null default false,
  status text not null default 'pending_payment' check (status in (
    'pending_payment', 'escrow_locked', 'in_progress', 'delivered', 'revision_requested', 'approved', 'payout_released', 'completed'
  )),
  max_free_revisions int not null default 3,
  paid_revision_price decimal(12,2) not null default 50,
  dispute_window_hours int not null default 48,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index order_contracts_order_id_idx on public.order_contracts (order_id);

alter table public.order_contracts enable row level security;
create policy "Order contracts order parties" on public.order_contracts for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
  or exists (select 1 from public.order_contracts c where c.order_id = order_contracts.order_id and c.freelancer_id = auth.uid())
);
create policy "Order contracts insert buyer" on public.order_contracts for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
);
create policy "Order contracts update parties" on public.order_contracts for update using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
  or freelancer_id = auth.uid()
);

-- Freelancer invite: creator invites freelancer with split %
create table if not exists public.order_freelancer_invites (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  freelancer_id uuid not null references public.users (id) on delete restrict,
  creator_id uuid not null references public.users (id) on delete restrict,
  split_percent decimal(5,2) not null check (split_percent >= 0 and split_percent <= 100),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  unique (order_id, freelancer_id)
);
create index order_freelancer_invites_order_id_idx on public.order_freelancer_invites (order_id);

alter table public.order_freelancer_invites enable row level security;
create policy "Freelancer invites order parties" on public.order_freelancer_invites for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid() or freelancer_id = auth.uid())
));
create policy "Freelancer invites insert creator" on public.order_freelancer_invites for insert with check (
  creator_id = auth.uid() and exists (select 1 from public.orders o where o.id = order_id and o.provider_id = auth.uid())
);
create policy "Freelancer invites update" on public.order_freelancer_invites for update using (
  creator_id = auth.uid() or freelancer_id = auth.uid()
);

-- Payout splits: who gets what when order completes (platform already in order_finance)
create table if not exists public.payout_splits (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete restrict,
  role text not null check (role in ('creator', 'freelancer')),
  percent decimal(5,2) not null,
  amount_inr decimal(12,2) not null,
  released_at timestamptz,
  created_at timestamptz not null default now()
);
create index payout_splits_order_id_idx on public.payout_splits (order_id);

alter table public.payout_splits enable row level security;
create policy "Payout splits order parties" on public.payout_splits for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
  or exists (select 1 from public.order_contracts c where c.order_id = order_id and c.freelancer_id = auth.uid())
);
create policy "Payout splits insert system" on public.payout_splits for insert with check (true);

-- Order timeline: allow freelancer to read when assigned to order
create policy "Order timeline freelancer" on public.order_timeline for select using (
  exists (select 1 from public.order_contracts c where c.order_id = order_timeline.order_id and c.freelancer_id = auth.uid())
);

-- Chat: allow attachment in messages
alter table public.chat_messages add column if not exists attachment_url text;

-- RLS: only order parties can read chat/deliveries; only creator (or freelancer if assigned) upload delivery; only buyer approve
-- (Existing policies already restrict by order parties; delivery insert is provider-only in 004. We keep as is.)
-- Add policy so freelancer can also insert delivery when they are assigned (optional): do in app by checking order_contracts.freelancer_id and allowing upload_by freelancer.
