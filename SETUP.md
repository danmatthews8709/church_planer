# The Church Planner — Supabase + GitHub + Netlify setup

This replaces the old Claude-artifact storage with a real Postgres database (Supabase),
version-controlled on GitHub, and hosted on Netlify — the same stack you've used before.

The big win over the artifact version: **Supabase Realtime** means every open browser
tab gets pushed changes instantly, so multiple people editing at once actually stay in sync,
which the artifact's storage couldn't do.

## 1. Create the Supabase project

1. Go to [supabase.com](https://supabase.com) → New project.
2. Pick a name (e.g. `church-planner`), a strong database password (save it somewhere —
   you won't need it day-to-day, but you will if you ever connect directly to Postgres),
   and a region close to your church.
3. Wait ~2 minutes for it to provision.

## 2. Run the schema

1. In the Supabase dashboard: **SQL Editor → New query**.
2. Paste the entire contents of `supabase-schema.sql` from this repo.
3. Click **Run**. You should see "Success. No rows returned."
4. Check **Table Editor** — you should see `users`, `tags`, `audiences`, `weeks`,
   `recurring_rhythms`, `week_midweek_items`, `week_excluded_recurring`, and `events`,
   with `tags` and `audiences` already pre-filled with the defaults.

## 3. Get your API keys

1. **Project Settings → API**.
2. Copy the **Project URL** and the **`anon` `public`** key (not the `service_role` key —
   that one must never go in client-side code).
3. Paste them into `config.js` in this repo, replacing the placeholders.

> The anon key is meant to be public — it's what every visitor's browser will use.
> Row Level Security (already set up by the schema) is what actually controls access,
> the same way the PIN in the app is attribution, not a lock. Anyone with the site
> link can see and edit everything — identical posture to the old shared-storage version.

## 4. Push to GitHub

```bash
cd church-planner-repo
git init
git add .
git commit -m "Initial commit: Church Planner on Supabase"
gh repo create church-planner --private --source=. --push
```
(No `gh` CLI? Create an empty repo on github.com first, then:)
```bash
git remote add origin https://github.com/YOUR-USERNAME/church-planner.git
git branch -M main
git push -u origin main
```

**Important:** `config.js` contains your Supabase URL and anon key. Since the anon key
is safe to expose (see above), it's fine to commit — but if you'd rather keep it out of
git entirely (e.g. private repo isn't private enough for your taste), add `config.js` to
`.gitignore` and set it directly in Netlify's UI instead (see step 5).

## 5. Deploy on Netlify

1. [netlify.com](https://netlify.com) → **Add new site → Import an existing project**.
2. Connect GitHub, pick the `church-planner` repo.
3. Build settings: leave build command **blank**, publish directory **`.`** (already set
   in `netlify.toml`, so Netlify should pick this up automatically).
4. Deploy. You'll get a `something.netlify.app` URL immediately — add a custom domain
   later under **Site settings → Domain management** if you want one.

## 6. Test it

Open the Netlify URL in two different browsers (or one normal + one incognito window),
set up a user in each, and confirm:
- Adding a week in one shows up in the other **without refreshing** (this is the
  Realtime piece working).
- The busy-midweek amber flag, tags, and Settings panel all behave as before.

## What's next

This setup gives you the database and hosting. The actual `index.html` (the app itself)
still needs its data layer rewritten from the artifact's `window.storage` calls to
Supabase queries + a realtime subscription — that's a separate, sizeable pass I'll do
next once this infrastructure is confirmed working, rather than bundling an untested
rewrite with an untested deployment.
