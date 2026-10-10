-- LOOP MVP schema. Run this entire file in Supabase Dashboard > SQL Editor.
-- All exposed tables use Row Level Security. Do not add a service-role key to the website.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 40),
  level text default '',
  course text default '',
  bio text default '' check (char_length(bio) <= 220),
  interests text[] not null default '{}',
  university text not null default 'Veritas University, Bwari, Abuja',
  created_at timestamptz not null default now()
);
create table if not exists public.connections (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted')),
  created_at timestamptz not null default now(),
  constraint different_users check (requester_id <> recipient_id),
  constraint one_connection_pair unique (requester_id, recipient_id)
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.connections(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1500),
  created_at timestamptz not null default now()
);
create table if not exists public.blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint no_self_block check (blocker_id <> blocked_id)
);
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (char_length(reason) between 3 and 500),
  created_at timestamptz not null default now(),
  reviewed boolean not null default false,
  constraint no_self_report check (reporter_id <> reported_user_id)
);

create index if not exists connections_recipient_status_idx on public.connections(recipient_id,status);
create index if not exists connections_requester_status_idx on public.connections(requester_id,status);
create index if not exists messages_connection_created_idx on public.messages(connection_id,created_at);
create index if not exists profiles_created_idx on public.profiles(created_at desc);

alter table public.profiles enable row level security;
alter table public.connections enable row level security;
alter table public.messages enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.connections to authenticated;
grant select, insert on public.messages to authenticated;
grant select, insert, delete on public.blocks to authenticated;
grant insert on public.reports to authenticated;

drop policy if exists "signed in users can discover profiles" on public.profiles;
create policy "signed in users can discover profiles" on public.profiles
for select to authenticated using (true);
drop policy if exists "users create their own profile" on public.profiles;
create policy "users create their own profile" on public.profiles
for insert to authenticated with check ((select auth.uid()) = id);
drop policy if exists "users update their own profile" on public.profiles;
create policy "users update their own profile" on public.profiles
for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "participants read connections" on public.connections;
create policy "participants read connections" on public.connections
for select to authenticated using ((select auth.uid()) = requester_id or (select auth.uid()) = recipient_id);
drop policy if exists "users request connections" on public.connections;
create policy "users request connections" on public.connections
for insert to authenticated with check ((select auth.uid()) = requester_id and requester_id <> recipient_id and status = 'pending'
 and not exists (select 1 from public.blocks b where (b.blocker_id=requester_id and b.blocked_id=recipient_id) or (b.blocker_id=recipient_id and b.blocked_id=requester_id)));
drop policy if exists "recipient accepts or declines request" on public.connections;
create policy "recipient accepts or declines request" on public.connections
for update to authenticated using ((select auth.uid()) = recipient_id) with check ((select auth.uid()) = recipient_id and status = 'accepted');
drop policy if exists "recipient can delete pending request" on public.connections;
create policy "recipient can delete pending request" on public.connections
for delete to authenticated using ((select auth.uid()) = recipient_id and status = 'pending');

drop policy if exists "connected participants read messages" on public.messages;
create policy "connected participants read messages" on public.messages
for select to authenticated using (exists (
 select 1 from public.connections c where c.id=connection_id and c.status='accepted'
 and ((select auth.uid())=c.requester_id or (select auth.uid())=c.recipient_id)
) and not exists (select 1 from public.blocks b where
 (b.blocker_id=(select auth.uid()) and b.blocked_id=(select case when c.requester_id=(select auth.uid()) then c.recipient_id else c.requester_id end from public.connections c where c.id=connection_id))
 or (b.blocker_id=(select case when c.requester_id=(select auth.uid()) then c.recipient_id else c.requester_id end from public.connections c where c.id=connection_id) and b.blocked_id=(select auth.uid()))
));
drop policy if exists "connected users send messages as themselves" on public.messages;
create policy "connected users send messages as themselves" on public.messages
for insert to authenticated with check (sender_id=(select auth.uid()) and exists (
 select 1 from public.connections c where c.id=connection_id and c.status='accepted'
 and ((select auth.uid())=c.requester_id or (select auth.uid())=c.recipient_id)
 and not exists (select 1 from public.blocks b where
 (b.blocker_id=c.requester_id and b.blocked_id=c.recipient_id) or
 (b.blocker_id=c.recipient_id and b.blocked_id=c.requester_id))
));

drop policy if exists "users see blocks they created" on public.blocks;
create policy "users see blocks they created" on public.blocks
for select to authenticated using ((select auth.uid()) = blocker_id);
drop policy if exists "users create their own blocks" on public.blocks;
create policy "users create their own blocks" on public.blocks
for insert to authenticated with check ((select auth.uid()) = blocker_id);
drop policy if exists "users remove their own blocks" on public.blocks;
create policy "users remove their own blocks" on public.blocks
for delete to authenticated using ((select auth.uid()) = blocker_id);

drop policy if exists "users submit reports" on public.reports;
create policy "users submit reports" on public.reports
for insert to authenticated with check ((select auth.uid()) = reporter_id and reporter_id <> reported_user_id);

-- This is an MVP schema, not a completed moderation operation. Only trusted admins
-- should receive access to report contents. Review admin access before public launch.
