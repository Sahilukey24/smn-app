-- Seed categories and predefined services for Creator / Videographer / Freelancer
-- Run after 002_smn_marketplace.sql

-- Creator categories (e.g. Instagram/YouTube services)
insert into public.categories (id, name, role_type, sort_order) values
  ('11111111-1111-1111-1111-111111111101', 'Social media post', 'creator', 1),
  ('11111111-1111-1111-1111-111111111102', 'Story / Reel', 'creator', 2),
  ('11111111-1111-1111-1111-111111111103', 'Review / Unboxing', 'creator', 3),
  ('11111111-1111-1111-1111-111111111104', 'Brand mention', 'creator', 4)
on conflict do nothing;

insert into public.predefined_services (category_id, name, sort_order)
select id, 'Single post', 1 from public.categories where role_type = 'creator' and name = 'Social media post'
union all
select id, 'Story', 1 from public.categories where role_type = 'creator' and name = 'Story / Reel'
union all
select id, 'Reel', 2 from public.categories where role_type = 'creator' and name = 'Story / Reel'
union all
select id, 'Review video', 1 from public.categories where role_type = 'creator' and name = 'Review / Unboxing'
union all
select id, 'Brand mention (story)', 1 from public.categories where role_type = 'creator' and name = 'Brand mention';

-- Videographer
insert into public.categories (id, name, role_type, sort_order) values
  ('22222222-2222-2222-2222-222222222201', 'Video edit', 'videographer', 1),
  ('22222222-2222-2222-2222-222222222202', 'Short form', 'videographer', 2)
on conflict do nothing;

-- Freelancer
insert into public.categories (id, name, role_type, sort_order) values
  ('33333333-3333-3333-3333-333333333301', 'Design', 'freelancer', 1),
  ('33333333-3333-3333-3333-333333333302', 'Development', 'freelancer', 2),
  ('33333333-3333-3333-3333-333333333303', 'Writing', 'freelancer', 3),
  ('33333333-3333-3333-3333-333333333304', 'Marketing', 'freelancer', 4)
on conflict do nothing;

-- Predefined for freelancer (optional – or they add custom names)
insert into public.predefined_services (category_id, name, sort_order)
select id, 'Logo design', 1 from public.categories where role_type = 'freelancer' and name = 'Design'
union all
select id, 'Web app', 1 from public.categories where role_type = 'freelancer' and name = 'Development'
union all
select id, 'Blog post', 1 from public.categories where role_type = 'freelancer' and name = 'Writing';
