create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  grading_view text not null default '100' check (grading_view in ('100', '5')),
  created_at timestamptz not null default now()
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  constraint subjects_user_id_name_key unique (user_id, name)
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  date date not null,
  percent numeric(5,2) not null check (percent >= 0 and percent <= 100),
  type text not null default 'regular',
  created_at timestamptz not null default now()
);

create index if not exists grades_user_id_idx on public.grades (user_id);
create index if not exists grades_subject_id_idx on public.grades (subject_id);
create index if not exists subjects_user_id_idx on public.subjects (user_id);

alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.grades enable row level security;

create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "subjects_select_own"
on public.subjects
for select
to authenticated
using (auth.uid() = user_id);

create policy "subjects_insert_own"
on public.subjects
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "subjects_update_own"
on public.subjects
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "subjects_delete_own"
on public.subjects
for delete
to authenticated
using (auth.uid() = user_id);

create policy "grades_select_own"
on public.grades
for select
to authenticated
using (auth.uid() = user_id);

create policy "grades_insert_own"
on public.grades
for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.subjects s
    where s.id = subject_id
      and s.user_id = auth.uid()
  )
);

create policy "grades_update_own"
on public.grades
for update
to authenticated
using (auth.uid() = user_id)
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.subjects s
    where s.id = subject_id
      and s.user_id = auth.uid()
  )
);

create policy "grades_delete_own"
on public.grades
for delete
to authenticated
using (auth.uid() = user_id);
