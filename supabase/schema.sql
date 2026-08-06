-- ============================================================
-- Portfolio backend schema for Supabase
-- Run this ONCE in: Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- Needed for gen_random_uuid()
create extension if not exists pgcrypto;

-- ---------- PROFILE (single row, id = 1) ----------
create table if not exists public.profile (
  id integer primary key default 1,
  name text,
  title text,
  bio text,
  photo_url text,
  email text,
  whatsapp text,       -- digits only, e.g. 201277573021
  linkedin text,        -- full url
  github text,          -- full url
  available boolean default true,
  updated_at timestamptz default now(),
  constraint single_row check (id = 1)
);

insert into public.profile (id, name, title, bio, email, whatsapp, linkedin, github, available)
values (
  1,
  'Michael Talaat',
  'Flutter Developer & UI/UX Designer',
  'Senior-minded Flutter engineer focused on product-grade mobile apps, scalable architecture, and polished motion.',
  'michael.talaat.dev@gmail.com',
  '201277573021',
  'https://linkedin.com/in/yourusername',
  'https://github.com/yourusername',
  true
)
on conflict (id) do nothing;

-- ---------- PROJECTS ----------
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  technologies text[] default '{}',
  cover text,
  images jsonb default '[]',   -- [{ "name": "...", "url": "..." }, ...]
  videos jsonb default '[]',   -- [{ "name": "...", "url": "..." }, ...]
  sort_order integer default 0,
  created_at timestamptz default now()
);

-- ---------- CONTACT MESSAGES ----------
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  message text not null,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- Public (anon key) can: read profile, read projects, insert messages.
-- Only a signed-in Supabase Auth user (your admin login) can:
-- write profile/projects, and read/delete messages.
-- ============================================================
alter table public.profile enable row level security;
alter table public.projects enable row level security;
alter table public.messages enable row level security;

-- profile
drop policy if exists "public read profile" on public.profile;
create policy "public read profile" on public.profile
  for select using (true);

drop policy if exists "admin write profile" on public.profile;
create policy "admin write profile" on public.profile
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- projects
drop policy if exists "public read projects" on public.projects;
create policy "public read projects" on public.projects
  for select using (true);

drop policy if exists "admin write projects" on public.projects;
create policy "admin write projects" on public.projects
  for all using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- messages: anyone can send, only admin can read/delete
drop policy if exists "public send message" on public.messages;
create policy "public send message" on public.messages
  for insert with check (true);

drop policy if exists "admin read messages" on public.messages;
create policy "admin read messages" on public.messages
  for select using (auth.role() = 'authenticated');

drop policy if exists "admin manage messages" on public.messages;
create policy "admin manage messages" on public.messages
  for update using (auth.role() = 'authenticated');

drop policy if exists "admin delete messages" on public.messages;
create policy "admin delete messages" on public.messages
  for delete using (auth.role() = 'authenticated');

-- ============================================================
-- STORAGE (profile photo + project images/covers)
-- Run this part too — creates a public bucket called "portfolio"
-- ============================================================
insert into storage.buckets (id, name, public)
values ('portfolio', 'portfolio', true)
on conflict (id) do nothing;

drop policy if exists "public read portfolio bucket" on storage.objects;
create policy "public read portfolio bucket" on storage.objects
  for select using (bucket_id = 'portfolio');

drop policy if exists "admin upload portfolio bucket" on storage.objects;
create policy "admin upload portfolio bucket" on storage.objects
  for insert with check (bucket_id = 'portfolio' and auth.role() = 'authenticated');

drop policy if exists "admin update portfolio bucket" on storage.objects;
create policy "admin update portfolio bucket" on storage.objects
  for update using (bucket_id = 'portfolio' and auth.role() = 'authenticated');

drop policy if exists "admin delete portfolio bucket" on storage.objects;
create policy "admin delete portfolio bucket" on storage.objects
  for delete using (bucket_id = 'portfolio' and auth.role() = 'authenticated');

-- ============================================================
-- LAST STEP (do this in the Dashboard, not SQL):
-- Authentication -> Users -> Add user -> create YOUR admin email + password.
-- That's the only account that can log in to /admin panel.
-- ============================================================
