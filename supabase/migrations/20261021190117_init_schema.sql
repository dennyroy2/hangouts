-- ========== ENUMS ==========
create type friendship_status as enum ('pending', 'accepted');
create type invitation_status as enum ('invited', 'accepted', 'declined');

-- ========== PROFILES ==========
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text not null,
  display_name text not null,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_]{3,20}$')
);
-- Usernames must be unique case-insensitively ("Denny" and "denny" are the same user)
create unique index profiles_username_lower_idx on public.profiles (lower(username));

-- ========== FRIENDSHIPS ==========
create table public.friendships (
  id           uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  addressee_id uuid not null references public.profiles (id) on delete cascade,
  status_type friendship_status not null default 'pending',
  created_at   timestamptz not null default now(),
  constraint no_self_friendship check (requester_id <> addressee_id)
);
-- One row per pair, no matter who sent the request
create unique index friendships_pair_idx
  on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create index friendships_addressee_idx on public.friendships (addressee_id);

-- ========== HANGOUTS ==========
create table public.hangouts (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles (id) on delete cascade,
  hangout_name text not null,
  location_name text not null,
  starts_at timestamptz not null,
  hangout_description text,
  created_at timestamptz not null default now()
);

create index starts_at
    on public.hangouts (starts_at);

-- ========== INVITATIONS ==========
create table public.hangout_invitations (
  hangout_id   uuid not null references public.hangouts (id) on delete cascade,
  invitee_id   uuid not null references public.profiles (id) on delete cascade,
  status_type invitation_status not null default 'invited',
  responded_at timestamptz,
  primary key (hangout_id, invitee_id)
);

create index invited
    on public.hangout_invitations (invitee_id);

-- ========== PHOTOS ==========
create table public.hangout_photos (
  id           uuid primary key default gen_random_uuid(),
  hangout_id  uuid not null references public.hangouts (id) on delete cascade,
  storage_path text not null,
  position     int  not null default 0,
  unique (hangout_id, position)
);