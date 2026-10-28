-- pgTAP static privilege/RLS guard tests for Rooms.
-- Run only AFTER applying schema.sql to a disposable Supabase staging project.
-- Requires pgTAP (available in Supabase projects; enable it if necessary).
begin;
select plan(18);

select has_table('public', 'rooms_profiles', 'profiles table exists');
select has_table('public', 'rooms_listings', 'listings table exists');
select has_table('public', 'rooms_verification_cases', 'verification table exists');

select ok((select relrowsecurity from pg_class where oid='public.rooms_profiles'::regclass),
          'profiles RLS enabled');
select ok((select relrowsecurity from pg_class where oid='public.rooms_listings'::regclass),
          'listings RLS enabled');
select ok((select relrowsecurity from pg_class where oid='public.rooms_listing_photos'::regclass),
          'listing photos RLS enabled');
select ok((select relrowsecurity from pg_class where oid='public.rooms_lifestyle_preferences'::regclass),
          'lifestyle preferences RLS enabled');
select ok((select relrowsecurity from pg_class where oid='public.rooms_verification_cases'::regclass),
          'verification cases RLS enabled');
select ok((select relrowsecurity from pg_class where oid='public.rooms_enquiries'::regclass),
          'enquiries RLS enabled');

select ok(not has_column_privilege('authenticated', 'public.rooms_profiles', 'role', 'UPDATE'),
          'authenticated cannot update profile role');
select ok(not has_column_privilege('authenticated', 'public.rooms_profiles', 'verification_status', 'UPDATE'),
          'authenticated cannot update profile verification status');
select ok(not has_column_privilege('authenticated', 'public.rooms_listings', 'review_status', 'UPDATE'),
          'authenticated cannot approve/reject listings directly');
select ok(not has_column_privilege('authenticated', 'public.rooms_listings', 'published_at', 'UPDATE'),
          'authenticated cannot publish listings directly');
select ok(not has_column_privilege('authenticated', 'public.rooms_listings', 'property_verified', 'UPDATE'),
          'authenticated cannot self-verify a property');
select ok(not has_column_privilege('authenticated', 'public.rooms_listings', 'full_address', 'SELECT'),
          'authenticated cannot directly select exact property address');
select ok(not has_column_privilege('anon', 'public.rooms_listings', 'full_address', 'SELECT'),
          'anonymous clients cannot directly select exact property address');
select ok(not has_column_privilege('authenticated', 'public.rooms_verification_cases', 'private_storage_path', 'SELECT'),
          'authenticated cannot read private verification document path');
select ok(not has_column_privilege('authenticated', 'public.rooms_verification_cases', 'reviewer_notes', 'SELECT'),
          'authenticated cannot read private reviewer notes');

select * from finish();
rollback;
