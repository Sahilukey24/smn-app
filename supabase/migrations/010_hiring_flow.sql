-- Core hiring flow: pending_payment, order_timeline, chat_room on payment success

-- Allow status pending_payment (before gateway redirect)
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check check (status in (
  'pending_payment', 'pending', 'in_progress', 'delivered', 'revision', 'completed', 'failed', 'disputed', 'cancelled'
));

-- Order timeline: status milestones for dashboard
create table if not exists public.order_timeline (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  event_type text not null,
  title text,
  description text,
  created_at timestamptz not null default now()
);
create index order_timeline_order_id_idx on public.order_timeline (order_id);

alter table public.order_timeline enable row level security;
create policy "Order timeline order parties" on public.order_timeline for select using (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
create policy "Order timeline insert system" on public.order_timeline for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);
