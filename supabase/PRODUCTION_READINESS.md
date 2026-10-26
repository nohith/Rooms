# Rooms staging validation and production-readiness checklist

## Important status
This is a runbook and test harness, not proof that the database has passed tests. No connection to the user's Supabase project is available through this workflow, and no SQL has been executed against it. Do not run this on production.

## Recommended environment
1. Create a separate Supabase staging project (not the project intended for real users).
2. Confirm it is empty. The current `schema.sql` creates enums/tables and is not an idempotent migration.
3. In the staging SQL Editor, inspect the project and confirm the database is disposable.
4. Apply `supabase/schema.sql` there only after reviewing the SQL and saving a backup/restore point if applicable.
5. Enable pgTAP in staging if it is not already enabled, then run `supabase/tests/rooms_security.test.sql`.
6. Treat any failing assertion as a release blocker. Save the full test output with the PR.
7. Run behavior tests using separate anonymous, resident, and owner test accounts; catalog/grant checks alone do not prove RLS behavior.

## pgTAP test harness
The file `supabase/tests/rooms_security.test.sql` checks that all six tables have RLS enabled and browser roles do not have direct privileges to modify role/verification/approval state or read exact addresses and private verification fields. It uses a transaction and rolls back.

These tests are necessary but not sufficient: they do not simulate every RLS path, storage policy, OTP flow, admin operation, or concurrent booking.

## Required behavioral RLS tests
Use separate test identities and verify each outcome:
- Anonymous: can read approved/published listing fields; cannot read drafts or exact addresses.
- Resident: can read/update own permitted profile fields and own preferences; cannot read another user's profile/preferences.
- Resident: cannot promote self to owner/admin or set verification status.
- Resident: cannot insert a listing or create an enquiry for an unapproved/unpublished listing.
- Owner: can submit/edit own pending listing; cannot edit another owner's listing or change owner ID, approval status, publication time, or property verification.
- Owner: cannot directly read exact address fields through PostgREST or read private verification notes/document paths.
- Verification: users can submit only their own identity case; owners can submit a property case only for their own listing; only trusted server-side tooling can review cases.
- Enquiries: resident and listing owner can read an enquiry; unrelated users cannot; only owner can change status.
- Storage: anonymous/resident/owner clients cannot read identity documents; listing photos are public only if intended and only for approved/published listings.
- Abuse and privacy: test OTP throttling, duplicate submissions, consent, account deletion, and private matching preference behavior.

## Production readiness blockers
Do not onboard real users until all applicable items are complete:
- [ ] Review/approve the schema PR and test results; apply only through a versioned migration.
- [ ] Separate staging and production projects; restrict production dashboard access.
- [ ] Implement trusted server-side owner onboarding, admin review, listing moderation, and verification decisions. Never expose service-role credentials to browsers.
- [ ] Define private Storage buckets and object-level RLS policies; identity documents must never be in public photo storage.
- [ ] Configure phone OTP provider, sender configuration, abuse limits, CAPTCHA/rate limiting as appropriate, and delivery tests.
- [ ] Add transactional bed reservation/occupancy operations and concurrency/overbooking tests.
- [ ] Implement authorized address disclosure after an appropriate user action, rather than public direct access.
- [ ] Implement server-side matching with consent, opt-out, minimal disclosure, and protection against inferring sensitive traits.
- [ ] Validate age restrictions and audience filters in trusted logic, not only UI controls.
- [ ] Add audit logs for admin actions, verification changes, listing approval, and sensitive address/document access.
- [ ] Add privacy notice, consent, retention/deletion workflows, account deletion, abuse reporting, and moderation.
- [ ] Set backups/PITR according to plan, verify restore procedure, and configure alerts/monitoring.
- [ ] Run Supabase Security Advisor and dependency/build checks; resolve findings.
- [ ] Test Kannada/English content, mobile responsiveness, accessibility, and error states.
- [ ] Run end-to-end tests with synthetic data only; remove test identities/data before launch.
- [ ] Prepare incident response and a rollback plan.

## Go/no-go rule
Production launch is **NO-GO** until SQL has been applied successfully in staging, pgTAP and behavioral RLS tests pass, Storage rules are tested, and trusted server workflows exist for all privileged actions.
