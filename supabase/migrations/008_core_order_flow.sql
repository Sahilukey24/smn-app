-- Core order money flow: service fields, order.service_id, chat_rooms parties, creator balance

-- Services: description, sample image, category
alter table public.services add column if not exists description text;
alter table public.services add column if not exists demo_image_url text;
alter table public.services add column if not exists category_id uuid references public.categories (id) on delete set null;

-- Orders: link single service for core flow
alter table public.orders add column if not exists service_id uuid references public.services (id) on delete set null;

-- Chat rooms: store buyer and creator for convenience
alter table public.chat_rooms add column if not exists buyer_id uuid references public.users (id) on delete restrict;
alter table public.chat_rooms add column if not exists creator_id uuid references public.users (id) on delete restrict;

-- Allow insert chat_room when order exists and current user is buyer or provider
create policy "Chat rooms insert order party" on public.chat_rooms for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and (o.buyer_id = auth.uid() or o.provider_id = auth.uid()))
);

-- Creator balance (earnings added on order completed)
alter table public.profiles add column if not exists balance_inr decimal(12,2) not null default 0;

-- Optional: RPC to increment creator balance (avoids race if app updates in parallel)
create or replace function public.increment_profile_balance(p_profile_id uuid, p_amount decimal)
returns void language sql security definer as $$
  update public.profiles set balance_inr = coalesce(balance_inr, 0) + p_amount, updated_at = now() where id = p_profile_id;
$$;
