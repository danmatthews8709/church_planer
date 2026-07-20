# The Church Planner

A term-based planning app for churches: Dashboard (weekly rhythm), Calendar, and List
views, with tagged midweek activities, recurring rhythms with per-week exceptions, and
a name+PIN system for lightweight multi-user attribution.

Backed by Supabase (Postgres + Realtime), deployed via Netlify, versioned on GitHub.

See `SETUP.md` for step-by-step setup instructions.

## Structure

```
.
├── index.html          the app, backed by Supabase (see SETUP.md for how it connects)
├── config.js            your Supabase URL + anon key (fill in after setup)
├── supabase-schema.sql   run this once in the Supabase SQL editor
├── netlify.toml          Netlify build config (static site, no build step)
└── SETUP.md              step-by-step setup guide
```
