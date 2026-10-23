-- Rooms Supabase starter schema (security-hardened draft).
-- Apply only to a NEW/empty Supabase database after review.
-- This file is not an idempotent migration; enum/table names must not already exist.
-- Never put the service-role key in browser code.

create extension if not exists pgcrypto;

create type public.rooms_role as enum ('resident','owner','admin');
create type public.rooms_review_status as enum ('pending','approved','rejected','needs_changes');
create type public.rooms_audience as enum ('any','women_only','men_only');
create type public.rooms_property_kind as enum ('pg','coliving','hotel','hostel','apartment');
create type public.rooms_room_kind as enum ('private','shared','studio');

create table public.rooms_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  role public.rooms_role not null default 'resident',
  age_years smallint check (age_years between 18 and 100),
  preferred_language text not null default 'en' check (preferred_language in ('en','kn')),
  verification_status public.rooms_review_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.rooms_listings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.rooms_profiles(id) on delete restrict,
  name text not null check (char_length(name) between 2 and 120),
  property_kind public.rooms_property_kind not null default 'pg',
  room_kind public.rooms_room_kind not null,
  area text not null,
  -- Exact address is intentionally not granted to browser roles; expose it later
  -- only through an authorized server workflow if product requirements need it.
  full_address text,
  audience public.rooms_audience not null default 'any',
  monthly_rent numeric(10,2) not null check (monthly_rent >= 0),
  deposit numeric(10,2) not null default 0 check (deposit >= 0),
  room_capacity smallint not null check (room_capacity between 1 and 30),
  occupied_beds smallint not null default 0 check (occupied_beds >= 0 and occupied_beds <= room_capacity),
  min_age smallint not null default 18 check (min_age between 18 and 100),
  max_age smallint check (max_age between 18 and 100),
  amenities text[] not null default '{}',
  house_rules text,
  available_from date,
  review_status public.rooms_review_status not null default 'pending',
  property_verified boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  check (max_age is null or max_age >= min_age),
  check ((review_status = 'approved' and published_at is not null) or
         (review_status <> 'approved' and published_at is null))
);
create index rooms_listings_area_status_idx on public.rooms_listings(area, review_status);

create table public.rooms_listing_photos (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.rooms_listings(id) on delete cascade,
  storage_path text not null,
  alt_text text,
  sort_order smallint not null default 0
);

create table public.rooms_lifestyle_preferences (
  user_id uuid primary key references public.rooms_profiles(id) on delete cascade,
  sleep_schedule text,
  cleanliness text,
  noise_preference text,
  food_preference text,
  guest_frequency text,
  work_study_routine text,
  social_style text,
  smoking_preference text,
  budget_min numeric(10,2) check (budget_min >= 0),
  budget_max numeric(10,2) check (budget_max >= 0),
  preferred_area text,
  visible_to_matches boolean not null default false,
  check (budget_max is null or budget_min is null or budget_max >= budget_min)
);

create table public.rooms_verification_cases (
  id uuid primary key default gen_random_uuid(),
  subject_user_id uuid references public.rooms_profiles(id) on delete cascade,
  listing_id uuid references public.rooms_listings(id) on delete cascade,
  case_type text not null check (case_type in ('resident_identity','owner_identity','property')),
  status public.rooms_review_status not null default 'pending',
  -- Private document paths and reviewer notes are never readable by browser roles.
  private_storage_path text,
  reviewer_id uuid references public.rooms_profiles(id),
  reviewer_notes text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  check (subject_user_id is not null or listing_id is not null),
  check (
    (case_type in ('resident_identity','owner_identity') and subject_user_id is not null and listing_id is null)
    or (case_type = 'property' and listing_id is not null)
  )
);

create table public.rooms_enquiries (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.rooms_listings(id) on delete cascade,
  resident_id uuid not null references public.rooms_profiles(id) on delete cascade,
  message text not null check (char_length(message) between 1 and 3000),
  status text not null default 'new' check (status in ('new','responded','closed')),
  created_at timestamptz not null default now()
);

-- Enable RLS on every table exposed in the public schema.
alter table public.rooms_profiles enable row level security;
alter table public.rooms_listings enable row level security;
alter table public.rooms_listing_photos enable row level security;
alter table public.rooms_lifestyle_preferences enable row level security;
alter table public.rooms_verification_cases enable row level security;
alter table public.rooms_enquiries enable row level security;

-- Start from no browser privileges; grant only the operations/columns required.
revoke all on table public.rooms_profiles, public.rooms_listings,
  public.rooms_listing_photos, public.rooms_lifestyle_preferences,
  public.rooms_verification_cases, public.rooms_enquiries from anon, authenticated;

grant select on public.rooms_profiles to authenticated;
grant insert (id, display_name, age_years, preferred_language) on public.rooms_profiles to authenticated;
grant update (display_name, age_years, preferred_language) on public.rooms_profiles to authenticated;

-- Do not expose full_address through direct browser queries.
grant select (
  id, owner_id, name, property_kind, room_kind, area, audience, monthly_rent,
  deposit, room_capacity, occupied_beds, min_age, max_age, amenities, house_rules,
  available_from, review_status, property_verified, published_at, created_at
) on public.rooms_listings to anon, authenticated;
grant insert (
  owner_id, name, property_kind, room_kind, area, audience, monthly_rent, deposit,
  room_capacity, occupied_beds, min_age, max_age, amenities, house_rules, available_from
) on public.rooms_listings to authenticated;
grant update (
  name, property_kind, room_kind, area, audience, monthly_rent, deposit,
  room_capacity, occupied_beds, min_age, max_age, amenities, house_rules, available_from
) on public.rooms_listings to authenticated;

grant select (id, listing_id, storage_path, alt_text, sort_order) on public.rooms_listing_photos to anon, authenticated;
grant insert (listing_id, storage_path, alt_text, sort_order) on public.rooms_listing_photos to authenticated;

grant select on public.rooms_lifestyle_preferences to authenticated;
grant insert (
  user_id, sleep_schedule, cleanliness, noise_preference, food_preference,
  guest_frequency, work_study_routine, social_style, smoking_preference,
  budget_min, budget_max, preferred_area, visible_to_matches
) on public.rooms_lifestyle_preferences to authenticated;
grant update (
  sleep_schedule, cleanliness, noise_preference, food_preference, guest_frequency,
  work_study_routine, social_style, smoking_preference, budget_min, budget_max,
  preferred_area, visible_to_matches
) on public.rooms_lifestyle_preferences to authenticated;

-- Only non-sensitive case metadata is readable from the browser.
grant select (id, subject_user_id, listing_id, case_type, status, submitted_at, reviewed_at)
  on public.rooms_verification_cases to authenticated;
grant insert (subject_user_id, listing_id, case_type) on public.rooms_verification_cases to authenticated;

grant select on public.rooms_enquiries to authenticated;
grant insert (listing_id, resident_id, message) on public.rooms_enquiries to authenticated;
grant update (status) on public.rooms_enquiries to authenticated;

-- Profiles: users can see only their own profile and cannot set role or verification status.
create policy "rooms_profiles_select_self"
  on public.rooms_profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "rooms_profiles_insert_resident_self"
  on public.rooms_profiles for insert to authenticated
  with check (
    id = (select auth.uid())
    and role = 'resident'
    and verification_status = 'pending'
  );
create policy "rooms_profiles_update_safe_fields_self"
  on public.rooms_profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Listings: only approved/published listings are public; owners can see their own drafts.
create policy "rooms_listings_read_public_or_owner"
  on public.rooms_listings for select to anon, authenticated
  using (
    (review_status = 'approved' and published_at is not null)
    or owner_id = (select auth.uid())
  );
create policy "rooms_listings_owner_insert_pending"
  on public.rooms_listings for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and review_status = 'pending'
    and published_at is null
    and property_verified = false
    and exists (
      select 1 from public.rooms_profiles p
      where p.id = (select auth.uid()) and p.role = 'owner'
    )
  );
create policy "rooms_listings_owner_update_unapproved"
  on public.rooms_listings for update to authenticated
  using (
    owner_id = (select auth.uid())
    and review_status in ('pending','needs_changes')
    and exists (
      select 1 from public.rooms_profiles p
      where p.id = (select auth.uid()) and p.role = 'owner'
    )
  )
  with check (
    owner_id = (select auth.uid())
    and review_status in ('pending','needs_changes')
    and published_at is null
    and exists (
      select 1 from public.rooms_profiles p
      where p.id = (select auth.uid()) and p.role = 'owner'
    )
  );

-- Photos follow listing visibility and ownership; no browser delete/update privileges.
create policy "rooms_photos_read_visible_listing"
  on public.rooms_listing_photos for select to anon, authenticated
  using (
    exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id
        and ((l.review_status = 'approved' and l.published_at is not null)
             or l.owner_id = (select auth.uid()))
    )
  );
create policy "rooms_photos_owner_insert_pending"
  on public.rooms_listing_photos for insert to authenticated
  with check (
    exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
        and l.review_status in ('pending','needs_changes')
    )
  );

-- Lifestyle preferences are private to their user for now.
create policy "rooms_preferences_select_self"
  on public.rooms_lifestyle_preferences for select to authenticated
  using (user_id = (select auth.uid()));
create policy "rooms_preferences_insert_self"
  on public.rooms_lifestyle_preferences for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "rooms_preferences_update_self"
  on public.rooms_lifestyle_preferences for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Verification case metadata only; documents/reviewer notes are server-only.
create policy "rooms_verification_read_own_or_owned_property"
  on public.rooms_verification_cases for select to authenticated
  using (
    subject_user_id = (select auth.uid())
    or exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );
create policy "rooms_verification_submit_own_identity"
  on public.rooms_verification_cases for insert to authenticated
  with check (
    status = 'pending'
    and reviewer_id is null
    and private_storage_path is null
    and (
      (case_type in ('resident_identity','owner_identity')
       and subject_user_id = (select auth.uid()) and listing_id is null)
      or
      (case_type = 'property' and subject_user_id is null and exists (
        select 1 from public.rooms_listings l
        where l.id = listing_id and l.owner_id = (select auth.uid())
      ))
    )
  );

-- Enquiries: only residents can contact approved listings; owner can update status.
create policy "rooms_enquiries_read_participants"
  on public.rooms_enquiries for select to authenticated
  using (
    resident_id = (select auth.uid())
    or exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );
create policy "rooms_enquiries_resident_insert"
  on public.rooms_enquiries for insert to authenticated
  with check (
    resident_id = (select auth.uid())
    and exists (
      select 1 from public.rooms_profiles p
      where p.id = (select auth.uid()) and p.role = 'resident'
    )
    and exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id and l.review_status = 'approved'
        and l.published_at is not null
    )
  );
create policy "rooms_enquiries_owner_update_status"
  on public.rooms_enquiries for update to authenticated
  using (
    exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.rooms_listings l
      where l.id = listing_id and l.owner_id = (select auth.uid())
    )
  );

-- IMPORTANT TRUST BOUNDARIES:
-- 1. Promote a profile to owner/admin only through trusted server-side admin tooling.
-- 2. Approval/rejection, verification decisions, published_at, property_verified,
--    full_address and private verification document paths are server-only.
-- 3. Do not store identity documents in public listing-photo storage.
-- 4. Bed availability must be updated transactionally; this schema alone does not
--    prevent concurrent overbooking or provide a booking/payment workflow.
-- 5. Review Supabase Storage policies, phone/SMS auth, rate limits, audit logging,
--    consent/retention/deletion rules, and RLS tests before real users or documents.
