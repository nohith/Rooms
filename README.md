# Rooms — PG & Coliving Finder

A responsive, modern starter app for exploring PG accommodations, private rooms, shared rooms, and studio stays. Built with plain HTML, CSS, and JavaScript: no package manager, build step, API key, or paid service is required.

> **Demo data:** All properties, locations, prices, ratings, review counts, and illustrations are sample content, not verified accommodation offers. The contact action prepares an email draft; there is no live property-owner backend yet.

## Features

- Responsive desktop, tablet, and mobile layout
- Search by property name, neighbourhood, city, or room type
- Monthly budget and room-type filters
- Quick filters for Wi-Fi, meals, air conditioning, and women-only stays
- Sort by recommended order, monthly price, or rating
- Save and unsave favourites using browser local storage when available
- Details dialog with amenities and a prefilled enquiry email draft
- Keyboard-friendly controls, accessible labels, reduced-motion support, and empty state
- No third-party API credentials or JavaScript dependencies

## Run locally

### Option 1 — Open directly

1. Download the repository ZIP or clone the repository.
2. Open the project folder.
3. Open `index.html` in a modern browser.

### Option 2 — Use a local server (recommended)

Node.js is **not required**. If Python 3 is installed, open a terminal in the project folder and run:

```bash
python3 -m http.server 8000
```

Then visit http://localhost:8000. If your computer uses the `python` command instead, run `python -m http.server 8000`. Stop the server with Ctrl+C.

### Option 3 — VS Code

1. Open this folder in Visual Studio Code.
2. Install the Live Server extension if needed.
3. Right-click `index.html` and choose **Open with Live Server**.

## Project structure

```text
Rooms/
├── index.html   # Page structure and accessible controls
├── styles.css   # Responsive visual design
├── app.js       # Sample data and interactive behaviour
└── README.md    # Setup and project documentation
```

## Try the app

1. Search for an area such as `Koramangala` or `HSR Layout`.
2. Choose a monthly budget and room type.
3. Use amenity chips to narrow results.
4. Sort by price or rating.
5. Click the heart on a card to save a stay, then use **Saved** in the header.
6. Click **View details** to see sample information and prepare an enquiry email.

Use **Clear all filters** when no results match.

## Customise listings

Edit the `stays` array near the top of `app.js`. Each object includes an ID, name, area, type, price in INR per month, rating, review count, gender category, amenity list, tag, colour palette, and description. Keep IDs unique. The quick-filter labels must match the amenity strings.

## Before production use

This is a front-end starter, not a complete booking platform. Before using it with real customers:

- Replace sample data with accurate, permissioned property listings.
- Add a secure backend/database for listings, availability, enquiries, and moderation.
- Verify owner identities and property details.
- Add privacy, safety, terms, and listing-verification policies.
- Never place private API keys in browser-side JavaScript.
- Replace the placeholder email `hello@rooms.example` in `index.html` with an actively monitored address.
- Test with real devices, keyboard navigation, and screen readers.

## Deployment

This is a static website. Upload the files to a static web host or connect this repository to one. Set the repository root as the publish directory. No build command is needed.

## Licence

No licence has been added. Add one before inviting reuse or contributions.
