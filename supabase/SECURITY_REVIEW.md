# Rooms Supabase schema — security review

## Scope
Static review of `supabase/schema.sql` for the Rooms Bengaluru PG/coliving prototype. This SQL has **not** been executed against Supabase, and the policies have not been verified against a live database.

## Changes in this draft
- Restricts profile writes to safe profile fields; browser clients cannot write role or verification status.
- Requires trusted server-side/admin tooling to promote a resident to owner/admin.
- Restricts listing inserts to owners and pending, unpublished, unverified listings; browser updates cannot change owner, review state, publication time, property-verification flag, or exact address.
- Does not grant browser roles access to `full_address`.
- Keeps lifestyle preferences private to their user.
- Hides private verification paths, reviewer IDs, and reviewer notes from browser reads.
- Allows owners to submit property-verification cases and users to submit their own identity cases.
- Restricts enquiry creation to residents contacting approved/published listings; only the listing owner may update enquiry status.
- Revokes broad table privileges and grants only selected columns and operations.

## Product requirements preserved in the data model
- Resident and owner roles (owner assignment must be trusted/admin-controlled).
- English/Kannada language preference.
- PG, coliving, hotel, hostel, and apartment property types.
- Private/shared/studio room types.
- Area, rent, deposit, amenities, house rules, and availability.
- Audience restrictions, age ranges, bed capacity/occupancy.
- Lifestyle compatibility preferences.
- Resident, owner, and property verification workflow metadata.
- Enquiries between residents and listing owners.

## Important limitations / follow-up work
1. **Fresh database only:** this is a starter schema with enum and table creation statements, not an idempotent migration. Do not rerun over existing objects. If objects already exist, create a reviewed migration instead.
2. **Static review only:** apply to a disposable staging project first; test with separate anonymous, resident, owner, and admin identities.
3. **Owner onboarding:** no self-service owner role assignment is provided. Build a trusted server-side onboarding/approval path.
4. **Admin workflow:** listing approvals, role changes, verification outcomes, and publishing must be performed by trusted server-side logic. Never ship the service-role key to browser code.
5. **Storage:** this schema creates no Storage bucket or `storage.objects` policies. Keep identity documents private and separate from listing photos.
6. **Capacity correctness:** the row check `occupied_beds <= room_capacity` does not implement transactional bookings or prevent concurrent booking races.
7. **Matching privacy:** preferences are self-readable only. A server-side matching workflow must enforce consent and reveal only the minimum necessary compatibility information.
8. **Exact address:** direct browser access is intentionally denied. If addresses should be disclosed after an approved enquiry, add a narrow server-side authorization flow.
9. **Phone authentication:** configure a supported SMS provider, abuse/rate limits, and OTP testing separately.
10. **Production controls:** audit logs, deletion/retention rules, consent, moderation, spam prevention, backups, and automated RLS regression tests remain outstanding.

## Manual security test plan (staging)
- Anonymous clients can read only approved and published listings, never drafts.
- An authenticated resident cannot set their role to owner/admin or verification status to approved.
- A user cannot read another user's profile or lifestyle preferences.
- A resident cannot create listings or enquire about a pending/unpublished listing.
- An owner cannot approve/publish their own listing, change `owner_id`, or set `property_verified`.
- An owner can create and edit their own pending listing but cannot edit another owner's listing.
- Browser clients cannot select `full_address`, private verification storage paths, or reviewer notes.
- A user cannot create a verification case for another user or another owner's listing.
- Only the listing owner can change enquiry status.
- Anonymous/resident/owner clients cannot access private identity-document objects in Storage.
- Concurrent booking tests are required once bed allocation exists.

## Review status
**Draft for pull-request review; not production-approved.** No SQL has been run against the user's Supabase project.
