-- SMN Social Media Network – Initial schema
-- Run this in Supabase SQL Editor after creating your project.

-- Profiles (extends auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  username text not null default '',
  role text not null default 'viewer' check (role in ('admin', 'member', 'viewer')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Posts
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  content text not null default '',
  image_url text,
  created_at timestamptz not null default now(),
  likes_count int not null default 0
);

create index if not exists posts_user_id_idx on public.posts (user_id);
create index if not exists posts_created_at_idx on public.posts (created_at desc);

-- Comments
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  comment text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists comments_post_id_idx on public.comments (post_id);

-- Likes
create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  unique (post_id, user_id)
);

create index if not exists likes_post_id_idx on public.likes (post_id);

-- RLS
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.likes enable row level security;

-- Profiles: anyone authenticated can read; users can update own
create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

-- Posts: readable by all; insert/update/delete by owner or admin
create policy "Posts are viewable by everyone"
  on public.posts for select using (true);
create policy "Authenticated users can create posts if member or admin"
  on public.posts for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.profiles where id = auth.uid() and role in ('admin', 'member')
    )
  );
create policy "Users can update own posts"
  on public.posts for update using (auth.uid() = user_id);
create policy "Users can delete own posts; admins can delete any"
  on public.posts for delete using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- Comments: readable by all; insert by authenticated
create policy "Comments are viewable by everyone"
  on public.comments for select using (true);
create policy "Authenticated users can add comments"
  on public.comments for insert with check (auth.uid() = user_id);
create policy "Users can delete own comments"
  on public.comments for delete using (auth.uid() = user_id);

-- Likes: readable by all; insert/delete by authenticated
create policy "Likes are viewable by everyone"
  on public.likes for select using (true);
create policy "Authenticated users can like"
  on public.likes for insert with check (auth.uid() = user_id);
create policy "Users can remove own like"
  on public.likes for delete using (auth.uid() = user_id);

-- Trigger: keep posts.likes_count in sync
create or replace function public.update_post_likes_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set likes_count = likes_count + 1 where id = new.post_id;
  elsif tg_op = 'DELETE' then
    update public.posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
  end if;
  return null;
end;
$$ language plpgsql security definer;

drop trigger if exists on_likes_change on public.likes;
create trigger on_likes_change
  after insert or delete on public.likes
  for each row execute procedure public.update_post_likes_count();

-- Trigger: create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'viewer')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Keep profiles.updated_at in sync
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Storage bucket for post images (run in Dashboard or here)
insert into storage.buckets (id, name, public)
values ('post-images', 'post-images', true)
on conflict (id) do nothing;

create policy "Post images are public"
  on storage.objects for select using (bucket_id = 'post-images');
create policy "Authenticated users can upload post images"
  on storage.objects for insert with check (
    bucket_id = 'post-images' and auth.role() = 'authenticated'
  );
create policy "Users can update own uploads"
  on storage.objects for update using (auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users can delete own uploads"
  on storage.objects for delete using (auth.uid()::text = (storage.foldername(name))[1]);

-- Avatars bucket (optional)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Avatar images are public"
  on storage.objects for select using (bucket_id = 'avatars');
create policy "Authenticated users can upload avatars"
  on storage.objects for insert with check (bucket_id = 'avatars' and auth.role() = 'authenticated');
create policy "Users can update own avatar"
  on storage.objects for update using (auth.uid()::text = (storage.foldername(name))[1]);
create policy "Users can delete own avatar"
  on storage.objects for delete using (auth.uid()::text = (storage.foldername(name))[1]);
