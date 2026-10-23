-- Rooms Supabase starter schema. Review policies and test in staging before production.
create extension if not exists pgcrypto;
create type public.rooms_role as enum ('resident','owner','admin');
create type public.rooms_review_status as enum ('pending','approved','rejected','needs_changes');
create type public.rooms_audience as enum ('any','women_only','men_only');
create type public.rooms_property_kind as enum ('pg','coliving','hotel','hostel','apartment');
create type public.rooms_room_kind as enum ('private','shared','studio');

create table public.rooms_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check(char_length(display_name) between 1 and 80),
 role public.rooms_role not null default 'resident',
 age_years smallint check(age_years between 18 and 100),
 preferred_language text not null default 'en' check(preferred_language in ('en','kn')),
 verification_status public.rooms_review_status not null default 'pending',
 created_at timestamptz not null default now()
);
create table public.rooms_listings (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.rooms_profiles(id) on delete restrict,
 name text not null check(char_length(name) between 2 and 120),
 property_kind public.rooms_property_kind not null default 'pg',
 room_kind public.rooms_room_kind not null,
 area text not null,
 full_address text,
 audience public.rooms_audience not null default 'any',
 monthly_rent numeric(10,2) not null check(monthly_rent>=0),
 deposit numeric(10,2) not null default 0 check(deposit>=0),
 room_capacity smallint not null check(room_capacity between 1 and 30),
 occupied_beds smallint not null default 0 check(occupied_beds>=0 and occupied_beds<=room_capacity),
 min_age smallint not null default 18 check(min_age between 18 and 100),
 max_age smallint check(max_age between 18 and 100),
 amenities text[] not null default '{}',
 house_rules text,
 available_from date,
 review_status public.rooms_review_status not null default 'pending',
 property_verified boolean not null default false,
 published_at timestamptz,
 created_at timestamptz not null default now(),
 check(max_age is null or max_age>=min_age),
 check((review_status='approved' and published_at is not null) or (review_status<>'approved' and published_at is null))
);
create index rooms_listings_area_idx on public.rooms_listings(area,review_status);
create table public.rooms_listing_photos (
 id uuid primary key default gen_random_uuid(),
 listing_id uuid not null references public.rooms_listings(id) on delete cascade,
 storage_path text not null,
 alt_text text,
 sort_order smallint not null default 0
);
create table public.rooms_lifestyle_preferences (
 user_id uuid primary key references public.rooms_profiles(id) on delete cascade,
 sleep_schedule text, cleanliness text, noise_preference text, food_preference text,
 guest_frequency text, work_study_routine text, social_style text, smoking_preference text,
 budget_min numeric(10,2) check(budget_min>=0), budget_max numeric(10,2) check(budget_max>=0),
 preferred_area text, visible_to_matches boolean not null default false,
 check(budget_max is null or budget_min is null or budget_max>=budget_min)
);
create table public.rooms_verification_cases (
 id uuid primary key default gen_random_uuid(),
 subject_user_id uuid references public.rooms_profiles(id) on delete cascade,
 listing_id uuid references public.rooms_listings(id) on delete cascade,
 case_type text not null check(case_type in ('resident_identity','owner_identity','property')),
 status public.rooms_review_status not null default 'pending',
 private_storage_path text,
 reviewer_id uuid references public.rooms_profiles(id),
 reviewer_notes text,
 submitted_at timestamptz not null default now(),
 reviewed_at timestamptz,
 check(subject_user_id is not null or listing_id is not null)
);
create table public.rooms_enquiries (
 id uuid primary key default gen_random_uuid(),
 listing_id uuid not null references public.rooms_listings(id) on delete cascade,
 resident_id uuid not null references public.rooms_profiles(id) on delete cascade,
 message text not null check(char_length(message) between 1 and 3000),
 status text not null default 'new' check(status in ('new','responded','closed')),
 created_at timestamptz not null default now()
);

alter table public.rooms_profiles enable row level security;
alter table public.rooms_listings enable row level security;
alter table public.rooms_listing_photos enable row level security;
alter table public.rooms_lifestyle_preferences enable row level security;
alter table public.rooms_verification_cases enable row level security;
alter table public.rooms_enquiries enable row level security;

create policy "profile self read" on public.rooms_profiles for select to authenticated using(id=auth.uid());
create policy "resident creates own profile" on public.rooms_profiles for insert to authenticated with check(id=auth.uid() and role='resident');
create policy "profile self update" on public.rooms_profiles for update to authenticated using(id=auth.uid() and role<>'admin') with check(id=auth.uid() and role<>'admin');
create policy "approved listings public, owner sees own" on public.rooms_listings for select to anon,authenticated using((review_status='approved' and published_at is not null) or owner_id=auth.uid());
create policy "owner submits pending listing" on public.rooms_listings for insert to authenticated with check(owner_id=auth.uid() and review_status='pending' and published_at is null);
create policy "owner edits unapproved listing" on public.rooms_listings for update to authenticated using(owner_id=auth.uid() and review_status in ('pending','needs_changes')) with check(owner_id=auth.uid() and review_status in ('pending','needs_changes') and published_at is null);
create policy "photo read only visible or owned listing" on public.rooms_listing_photos for select to anon,authenticated using(exists(select 1 from public.rooms_listings l where l.id=listing_id and ((l.review_status='approved' and l.published_at is not null) or l.owner_id=auth.uid())));
create policy "owner attaches photos to own pending listing" on public.rooms_listing_photos for insert to authenticated with check(exists(select 1 from public.rooms_listings l where l.id=listing_id and l.owner_id=auth.uid() and l.review_status in ('pending','needs_changes')));
create policy "preferences self read" on public.rooms_lifestyle_preferences for select to authenticated using(user_id=auth.uid());
create policy "preferences self insert" on public.rooms_lifestyle_preferences for insert to authenticated with check(user_id=auth.uid());
create policy "preferences self update" on public.rooms_lifestyle_preferences for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "verification subject read" on public.rooms_verification_cases for select to authenticated using(subject_user_id=auth.uid());
create policy "resident submits own verification" on public.rooms_verification_cases for insert to authenticated with check(subject_user_id=auth.uid() and status='pending' and reviewer_id is null);
create policy "enquiry participants read" on public.rooms_enquiries for select to authenticated using(resident_id=auth.uid() or exists(select 1 from public.rooms_listings l where l.id=listing_id and l.owner_id=auth.uid()));
create policy "resident creates enquiry" on public.rooms_enquiries for insert to authenticated with check(resident_id=auth.uid());

-- Security TODOs: admin review must be a trusted server function; never allow users to self-assign admin or verified status.
-- Configure Supabase Phone Auth + SMS provider; separate private identity-document storage from public listing photos.
-- Add storage.objects policies, transactional bed/booking updates, audit logs, consent/retention/deletion rules,
-- abuse controls and RLS tests. These starter policies need a security review before real user data is stored.
