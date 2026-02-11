-- Phase 1: Escrow payment – order_finance table + state machine statuses

-- Order status: add 'approved' (buyer approved, payout pending)
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check check (status in (
  'pending_payment', 'pending', 'in_progress', 'delivered', 'approved', 'revision', 'completed', 'failed', 'disputed', 'cancelled'
));

-- order_finance: one row per order, tracks escrow and payout
create table if not exists public.order_finance (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade unique,
  buyer_paid_amount decimal(12,2) not null default 0,
  platform_fee decimal(12,2) not null default 0,
  escrow_locked boolean not null default false,
  creator_payout decimal(12,2) not null default 0,
  payout_status text not null default 'pending' check (payout_status in (
    'pending', 'released', 'failed', 'refunded', 'partially_refunded'
  )),
  released_at timestamptz,
  transaction_id text,
  razorpay_payment_id text,
  razorpay_order_id text,
  finance_status text not null default 'pending_payment' check (finance_status in (
    'pending_payment', 'escrow_locked', 'delivered', 'approved', 'payout_released', 'completed'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index order_finance_order_id_idx on public.order_finance (order_id);
create index order_finance_razorpay_payment_id_idx on public.order_finance (razorpay_payment_id);

alter table public.order_finance enable row level security;
create policy "Order finance order parties" on public.order_finance for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
-- Insert/update from app or webhook (service role); restrict to order parties for update from client
create policy "Order finance insert buyer" on public.order_finance for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
);
create policy "Order finance update order party" on public.order_finance for update using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
