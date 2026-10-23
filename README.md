# Rooms — Bengaluru PG & Roommate Finder

## Files and entry points

- **`index.html`** — original starter version, preserved unchanged.
- **`rooms-v2.html`** — new feature prototype for the requested marketplace workflow.
- **`supabase/schema.sql`** — starter database schema for a future Supabase backend.
- **`styles.css` and `app.js`** — the original starter assets; the v2 prototype is self-contained in `rooms-v2.html`.

Open `rooms-v2.html` in a browser to try the new prototype. To run with a local server, use:

```bash
python3 -m http.server 8000
```

Then visit http://localhost:8000/rooms-v2.html. Node.js and a build step are not required for the front-end demo.

## What v2 demonstrates

- Bengaluru-first search by area, monthly budget, room type and audience
- Sample listings showing capacity, occupied beds, availability and age bounds
- Owner submission form for PG, coliving, hotel, hostel or apartment listings
- Photo selection and local preview data stored in the current browser only
- Capacity validation (occupied beds cannot exceed capacity) and age-range validation
- Women-only / men-only listing audience labels and filters
- Resident lifestyle profile with sleep schedule, cleanliness, noise, food, guests, work/study routine, social style and smoking preference
- A simple property/profile estimate and sorting placeholder, not a validated psychological assessment or real person-to-person roommate matching
- Phone sign-in placeholder that explicitly does not send an OTP
- A small Kannada/English toggle; most form labels and policy content remain English
- Check-in verification checklist that is only a local reminder, not evidence of verification
- Original `index.html` remains intact, preserving the initial search/filter/favourites/details experience

## Critical limitations

**This repository is not a production marketplace yet.** The new v2 file is a browser-only prototype:

- Seed listings are illustrative sample data, not verified offers.
- Owner-submitted listings, selected photos and lifestyle profiles stay in the current browser's local storage; they are not shared with other users/devices.
- Listing submissions are not sent to an administrator, and the demo does not enforce a real approval queue.
- Phone login does not send SMS and does not authenticate users.
- There is no live owner/property identity verification, resident identity verification, check-in approval, messaging, enquiries backend, payment flow or cloud photo storage.
- No Supabase project has been connected or configured. The SQL file is a starter schema and has not been applied or security-tested against a live database.
- The SQL schema alone does not implement secure admin review, role assignment, storage permissions or transactional bed reservations. Review and test it before storing personal information.
- Full Kannada localization has not been completed.
- The matching estimate cannot identify whether three roommates in a four-person room share the same mindset; the demo does not contain real roommate profiles or real compatibility data.

Do not upload identity documents, private phone information or other sensitive data to the demo. Do not treat any sample listing or checkbox as verified. Never place Supabase service-role keys in browser code.

## Backend implementation plan

1. Create a Supabase project and review/run `supabase/schema.sql` in a staging project.
2. Enable Supabase Phone Auth and configure an SMS provider; test OTP delivery, rate limits and abuse prevention.
3. Implement owner/resident onboarding and secure server-side role assignment. Users must never be able to grant themselves admin or verified status.
4. Configure private storage for identity evidence and a separate listing-photo bucket with restrictive policies.
5. Add server-side admin approval for owner accounts, property details, resident verification and listing publication.
6. Enforce room capacity and occupancy transactionally on the server/database to prevent overbooking.
7. Build consent-based matching that returns only the preferences a user has opted to share; let users edit/delete their profiles.
8. Add enquiries/messaging and check-in workflow with server-side authorization, audit logs, retention/deletion policies and security testing.
9. Translate the full UI and safety/privacy terms into reviewed Kannada and English.
10. Test RLS, authentication, age/audience filters, moderation, photo access, capacity races and deployment before a public launch.

## Deployment

A static host such as Netlify can serve the prototype with the repository root as publish directory and no build command. Hosting the static file does not enable authentication, shared data, verification or other backend features. Configure and test the backend separately before describing the service as live.

## Licence

No licence has been added yet.
