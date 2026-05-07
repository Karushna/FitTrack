-- Run this in Supabase SQL Editor.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  location text default 'Colombo, Sri Lanka',
  created_at timestamp with time zone default now()
);

create table if not exists activities (
  id bigint generated always as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  user_name text not null,
  type text not null,
  distance_km double precision default 0,
  minutes integer default 0,
  image_url text,
  created_at timestamp with time zone default now()
);

create table if not exists routes (
  id bigint generated always as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  name text not null,
  location text,
  distance_km double precision default 0,
  difficulty text default 'Easy',
  image_url text,
  created_at timestamp with time zone default now()
);

create table if not exists challenges (
  id bigint generated always as identity primary key,
  user_id uuid references profiles(id) on delete cascade,
  title text not null,
  target_km double precision default 10,
  progress_km double precision default 0,
  created_at timestamp with time zone default now()
);

create table if not exists challenge_members (
  id bigint generated always as identity primary key,
  challenge_id bigint references challenges(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  created_at timestamp with time zone default now(),
  unique(challenge_id, user_id)
);

alter table profiles enable row level security;
alter table activities enable row level security;
alter table routes enable row level security;
alter table challenges enable row level security;
alter table challenge_members enable row level security;

drop policy if exists "profiles_select_own" on profiles;
drop policy if exists "profiles_insert_own" on profiles;
drop policy if exists "profiles_update_own" on profiles;

create policy "profiles_select_own"
on profiles for select
using (auth.uid() = id);

create policy "profiles_insert_own"
on profiles for insert
with check (auth.uid() = id);

create policy "profiles_update_own"
on profiles for update
using (auth.uid() = id);

drop policy if exists "activities_select_authenticated" on activities;
drop policy if exists "activities_insert_own" on activities;
drop policy if exists "activities_update_own" on activities;
drop policy if exists "activities_delete_own" on activities;

create policy "activities_select_authenticated"
on activities for select
using (auth.role() = 'authenticated');

create policy "activities_insert_own"
on activities for insert
with check (auth.uid() = user_id);

create policy "activities_update_own"
on activities for update
using (auth.uid() = user_id);

create policy "activities_delete_own"
on activities for delete
using (auth.uid() = user_id);

drop policy if exists "routes_select_authenticated" on routes;
drop policy if exists "routes_insert_own" on routes;
drop policy if exists "routes_update_own" on routes;
drop policy if exists "routes_delete_own" on routes;

create policy "routes_select_authenticated"
on routes for select
using (auth.role() = 'authenticated');

create policy "routes_insert_own"
on routes for insert
with check (auth.uid() = user_id);

create policy "routes_update_own"
on routes for update
using (auth.uid() = user_id);

create policy "routes_delete_own"
on routes for delete
using (auth.uid() = user_id);

drop policy if exists "challenges_select_authenticated" on challenges;
drop policy if exists "challenges_insert_own" on challenges;
drop policy if exists "challenges_update_authenticated" on challenges;
drop policy if exists "challenges_delete_own" on challenges;

create policy "challenges_select_authenticated"
on challenges for select
using (auth.role() = 'authenticated');

create policy "challenges_insert_own"
on challenges for insert
with check (auth.uid() = user_id);

create policy "challenges_update_authenticated"
on challenges for update
using (auth.role() = 'authenticated');

create policy "challenges_delete_own"
on challenges for delete
using (auth.uid() = user_id);

drop policy if exists "challenge_members_select_authenticated" on challenge_members;
drop policy if exists "challenge_members_insert_own" on challenge_members;
drop policy if exists "challenge_members_delete_own" on challenge_members;

create policy "challenge_members_select_authenticated"
on challenge_members for select
using (auth.role() = 'authenticated');

create policy "challenge_members_insert_own"
on challenge_members for insert
with check (auth.uid() = user_id);

create policy "challenge_members_delete_own"
on challenge_members for delete
using (auth.uid() = user_id);