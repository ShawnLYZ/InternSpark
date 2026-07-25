<div align="center">
    <img src="packages\core\assets\branding\internspark_icon.png" alt="InternSpark Logo" width="200" height="200"/>
    <h1>InternSpark</h1>
    <h3><em>What if internships matched students like dating apps match people?</em></h3>
</div>

<p align="center">
    <strong>Connects students with internships that fit where they're trying to grow, not just what's listed first.</strong>
    <strong>Universities can see which placements actually lead somewhere.</strong>
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter"/>
    <img src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" alt="Dart"/>
    <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white" alt="Supabase"/>
    <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
    <img src="https://img.shields.io/badge/Gemini-8E75B2?style=flat&logo=googlegemini&logoColor=white" alt="Gemini"/>
</p>

# Setup & Configuration Guide

InternSpark is a swipe-to-match internship platform with three apps sharing one backend:
a **mobile app** for students, a **web app** for employers and universities, and a
**Supabase** backend (database + AI). None of these run against real data out of the box —
this repo intentionally ships with **no real API keys or URLs** in it. This guide walks you,
step by step, through creating your own free backend and plugging its keys into the project.

Every step is spelled out. If a term is unfamiliar, keep
reading — it's explained the first time it's used.

> **Where does everything actually go?** If you just want the short answer, skip to
> [Quick reference](#6-quick-reference--every-value-and-where-it-goes).

## Table of contents
1. [What you'll need before you start](#1-what-youll-need-before-you-start)
2. [Get the project code](#2-get-the-project-code)
3. [Create your Supabase project](#3-create-your-supabase-project)
4. [Get a Gemini API key](#4-get-a-gemini-api-key)
5. [Configure and run the apps](#5-configure-and-run-the-apps)
6. [Quick reference — every value and where it goes](#6-quick-reference--every-value-and-where-it-goes)
7. [Troubleshooting](#7-troubleshooting)
8. [Security notes](#8-security-notes)

---

## 1. What you'll need before you start

**Accounts (all free):**
- A [Supabase](https://supabase.com) account — this hosts your database, authentication, file
  storage, and the server-side "ai" function. You can sign up with GitHub or an email address.
- A [Google account](https://accounts.google.com) — used once to generate a Gemini AI key from
  Google AI Studio.

**Software on your computer:**
| Tool | Why you need it | Get it |
|---|---|---|
| **Git** | Downloads ("clones") and tracks changes to the code | [git-scm.com/downloads](https://git-scm.com/downloads) |
| **Flutter SDK** | Builds and runs the two apps (mobile + web) | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |
| **Node.js** (v18+) | Runs the backend helper scripts and the Supabase CLI | [nodejs.org](https://nodejs.org) (choose the "LTS" version) |
| **A code editor** | Lets you open/edit files | [Visual Studio Code](https://code.visualstudio.com) is recommended; install its "Flutter" and "Dart" extensions |
| **Google Chrome** | Runs the web app during development | [google.com/chrome](https://www.google.com/chrome/) |

You do **not** need Docker, and you do **not** need the Supabase CLI pre-installed — this repo's
`package.json` installs the CLI for you as a project dependency (see §3).

**What is a "terminal"?** It's a text window where you type commands instead of clicking icons.
- **Windows:** open "PowerShell" from the Start menu.
- **macOS:** open "Terminal" from Applications → Utilities.
- **Linux:** open your distribution's terminal app.

Every command below is meant to be typed into that window, one line at a time, followed by
Enter. Where Windows PowerShell syntax differs from macOS/Linux ("bash"), both are shown.

---

## 2. Get the project code

If you already have this folder on your computer (you're reading this file, so you probably
do), skip to §3. Otherwise:

```bash
git clone https://github.com/<your-username>/InternSpark.git
cd InternSpark
```

Then install the Node-based backend tooling (this reads `package.json` at the repo root and
downloads the Supabase CLI into `node_modules/`):

```bash
npm install
```

---

## 3. Create your Supabase project

### 3.1 Sign up and create a project

1. Go to **[supabase.com](https://supabase.com)** and click **"Start your project"** (top
   right), then sign up or log in.
2. Once logged in, you'll land on the **Organizations/Projects** dashboard. Click
   **"New Project"**.
3. Fill in the form:
   - **Name:** anything, e.g. `internspark`.
   - **Database Password:** click "Generate a password" or type your own — **copy this
     somewhere safe right now**. You'll need it later to link the Supabase CLI, and Supabase
     will not show it to you again.
   - **Region:** pick whichever is closest to you.
4. Click **"Create new project"**. Wait 1–2 minutes while Supabase provisions your database.

### 3.2 Find your Project URL and API keys

Once the project has finished provisioning:

1. In the left sidebar, click the **gear icon ⚙ ("Project Settings")** near the bottom.
2. Click **"API"** (in newer Supabase dashboards this may be labeled **"Data API"** or
   **"API Keys"** — it's the same page).
3. You'll see:
   - **Project URL** — looks like `https://abcdefghijklmnop.supabase.co`. This is your
     `SUPABASE_URL`. The random letters in it (`abcdefghijklmnop`) are your **project ref**,
     used later with the CLI.
   - **`anon` `public` key** — a long string starting with `eyJ...`. This is your
     `SUPABASE_ANON_KEY`. It is safe to embed in the mobile/web apps (Supabase's row-level
     security rules protect the data even though this key is public).
   - **`service_role` `secret` key** — another long `eyJ...` string, usually hidden behind a
     "Reveal" click. This is your `SUPABASE_SERVICE_ROLE_KEY`. **Never put this in the mobile
     or web app, and never commit it to git** — it bypasses all security rules. It is only used
     by backend scripts and the Supabase-hosted AI function.

Copy all three values into a scratch file for now — §5 shows you exactly where each one goes.

### 3.3 Set up the database schema and backend function

You need to (a) create all the database tables, and (b) deploy the server-side "ai" function
that talks to Gemini. There are two ways to do this — pick whichever you're more comfortable
with. **Option A (CLI) is faster and recommended**; **Option B (manual)** works if you'd rather
not install anything beyond what §1 already listed.

#### Option A — Using the Supabase CLI

1. Make sure you've run `npm install` at the repo root (§2) — this installed the Supabase CLI
   locally as `node_modules/.bin/supabase`, run through `npx`.
2. Log in (this opens your browser to authenticate with your Supabase account):
   ```bash
   npx supabase login
   ```
3. Link this folder to your new project (replace `<your-project-ref>` with the random letters
   from your Project URL, e.g. `abcdefghijklmnop`; you'll be prompted for the database password
   from §3.1):
   ```bash
   npx supabase link --project-ref <your-project-ref>
   ```
4. Push the database schema (this runs every file in `supabase/migrations/` against your new
   project, in order):
   ```bash
   npx supabase db push
   ```
5. Deploy the AI Edge Function:
   ```bash
   npx supabase functions deploy ai
   ```
6. Set the function's server-side secrets (see §4 for how to get a Gemini key; `GEMINI_MODEL`
   and `AI_DAILY_TOKEN_BUDGET` are optional — they default to `gemini-2.5-flash` and `200000`
   if you omit them):
   ```bash
   npx supabase secrets set GEMINI_API_KEY=<your-gemini-api-key> GEMINI_MODEL=gemini-2.5-flash AI_DAILY_TOKEN_BUDGET=200000
   ```

#### Option B — Manually, through the Supabase dashboard (no CLI)

1. **Apply the schema:** in the left sidebar, click **"SQL Editor"** → **"New query"**. Open
   each file in `supabase/migrations/` in your code editor **in filename order** (the numbers
   at the front of each filename, e.g. `20260614175019_schema.sql` before
   `20260614175411_security.sql`, are timestamps — oldest first), paste its full contents into
   the SQL Editor, and click **"Run"**. Repeat for every file in that folder, in order, without
   skipping any.
2. **Deploy the AI function:** in the left sidebar, click **"Edge Functions"** → **"Deploy a new
   function"** → name it exactly **`ai`**. Supabase's dashboard editor lets you add multiple
   files — recreate the file tree from `supabase/functions/ai/` in this repo (`index.ts`,
   `shared.ts`, `gates.ts`, `verification.ts`, and any other `.ts` files in that folder), copying
   each file's contents across exactly. This step is fiddly by hand; if you get stuck, installing
   Node (§1) and using Option A just for this one step is much less error-prone.
3. **Set the function's secrets:** still on the Edge Functions page, find **"Manage secrets"**
   (or **Project Settings → Edge Functions → Secrets**). Add:
   - `GEMINI_API_KEY` = the key you'll generate in §4
   - `GEMINI_MODEL` = `gemini-2.5-flash` (optional)
   - `AI_DAILY_TOKEN_BUDGET` = `200000` (optional)
4. **Allow sign-ups without email confirmation** (needed for the in-app sign-up flow to work
   immediately): **Authentication → Sign In / Providers** → find **"Confirm email"** and turn it
   **off**. (Supabase renames this section occasionally — search "confirm email" in
   Authentication settings if you don't see it in this exact spot.)

### 3.4 (Optional) Seed demo data

The repo includes scripts that create sample students, companies, and jobs so the apps aren't
empty on first run. They need three environment variables set in your terminal **first** —
these are not read from any file, only from the current terminal session:

```bash
# macOS/Linux (bash):
export SUPABASE_URL="https://<your-project-ref>.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="<your-service-role-key>"
export SUPABASE_ANON_KEY="<your-anon-key>"
node supabase/seed/seed.mjs
node supabase/verify.mjs
```
```powershell
# Windows (PowerShell):
$env:SUPABASE_URL = "https://<your-project-ref>.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY = "<your-service-role-key>"
$env:SUPABASE_ANON_KEY = "<your-anon-key>"
node supabase/seed/seed.mjs
node supabase/verify.mjs
```

`verify.mjs` should print a row count for every table with no errors. This creates login
accounts you can use once the apps are running, all with the password `Passw0rd!demo`:
`student@internspark.demo`, `employer@internspark.demo`, `university@internspark.demo`.

---

## 4. Get a Gemini API key

The backend's AI features (résumé generation, curriculum lookups, chat assistance) call
Google's Gemini model through the Edge Function you deployed in §3.3. You need your own key:

1. Go to **[aistudio.google.com](https://aistudio.google.com/)** and sign in with a Google
   account.
2. Click **"Get API key"** (usually in the left sidebar).
3. Click **"Create API key"**. If asked, choose or create a Google Cloud project — any name is
   fine, Google creates one for free automatically if you don't have one.
4. Copy the key that appears — it starts with `AIza...`. This is your `GEMINI_API_KEY` from
   §3.3 step 6 (Option A) or step 3 (Option B).

This key must **only** ever be set as a Supabase Edge Function secret (server-side). It must
never appear in the Flutter apps' code or run commands — that would ship it to every user's
device.

---

## 5. Configure and run the apps

The two Flutter apps never read a config *file* for their Supabase connection — they read it
from **build-time flags** (`--dart-define`) passed on the command line when you run them. This
section shows exactly where to type your two values (`SUPABASE_URL` and `SUPABASE_ANON_KEY` —
**never** the service role key or Gemini key, those are backend-only).

First, install each package's dependencies once:

```bash
(cd packages/core && flutter pub get)
(cd app_mobile && flutter pub get)
(cd app_web && flutter pub get)
```

### 5.1 Run the student app (mobile)

From the repo root, run (replace the two placeholders with your real values from §3.2):

```bash
cd app_mobile
flutter run --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

This launches on whatever device/emulator Flutter detects (pass `-d chrome` to run it as a web
page instead, or `flutter devices` to see your options).

### 5.2 Run the employer/university app (web)

From the repo root:

```bash
cd app_web
flutter run -d chrome --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
```

### 5.3 (Optional) Save yourself retyping — a local launch config

Retyping those long flags every time is tedious. You can save them in a file **that is never
committed to git** (this repo's `.gitignore` excludes the whole `.vscode/` folder), so it's safe
to put your real keys in it.

Create the file `.vscode/launch.json` at the repo root with this content, filling in your two
real values in both places they appear:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "app_mobile",
      "request": "launch",
      "type": "dart",
      "program": "app_mobile/lib/main.dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=<your-anon-key>"
      ]
    },
    {
      "name": "app_web",
      "request": "launch",
      "type": "dart",
      "program": "app_web/lib/main.dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=<your-anon-key>"
      ],
      "deviceId": "chrome"
    }
  ]
}
```

With this file in place, open the repo in VS Code, go to the "Run and Debug" panel, pick
"app_mobile" or "app_web" from the dropdown, and press the green play button — no typing needed.

You can also jot down all your values in a plain-text file named `API Key Configuration.md` at
the repo root, as a personal reference. This filename is already listed in `.gitignore`, so it
will never be committed — but note that **nothing in the codebase reads this file
automatically**; it's just notes for you to copy values from into the commands above.

### 5.4 Sign in

Once an app is running, sign in with one of the seeded demo accounts from §3.4 (password
`Passw0rd!demo` for all three), or use each app's "Create account" link to sign up fresh.

---

## 6. Quick reference — every value and where it goes

| Value | Looks like | Where you get it | Where it goes |
|---|---|---|---|
| Project ref | `abcdefghijklmnop` | Part of your Project URL (§3.2) | `npx supabase link --project-ref <this>` |
| Database password | text you chose | Set when creating the project (§3.1) | Prompted by `supabase link` / `supabase db push` |
| `SUPABASE_URL` | `https://abcdefghijklmnop.supabase.co` | Project Settings → API (§3.2) | `--dart-define=SUPABASE_URL=…` (§5.1, §5.2), `.vscode/launch.json` (§5.3), env var for seed/verify scripts (§3.4) |
| `SUPABASE_ANON_KEY` | long string starting `eyJ...` | Project Settings → API, "anon public" (§3.2) | `--dart-define=SUPABASE_ANON_KEY=…` (§5.1, §5.2), `.vscode/launch.json` (§5.3), env var for seed/verify scripts (§3.4) |
| `SUPABASE_SERVICE_ROLE_KEY` | long string starting `eyJ...` | Project Settings → API, "service_role secret" (§3.2) | Env var for `node supabase/seed/*.mjs` and `node supabase/verify*.mjs` only (§3.4). **Never** in a Flutter app or dart-define flag. |
| `GEMINI_API_KEY` | starts with `AIza...` | Google AI Studio (§4) | `npx supabase secrets set GEMINI_API_KEY=…` (§3.3 Option A) or dashboard "Manage secrets" (§3.3 Option B). Server-side only. |
| `GEMINI_MODEL` (optional) | e.g. `gemini-2.5-flash` | You choose | Same secrets mechanism as above; defaults if omitted |
| `AI_DAILY_TOKEN_BUDGET` (optional) | e.g. `200000` | You choose | Same secrets mechanism as above; defaults if omitted |
| Personal access token | starts with `sbp_...` | Supabase dashboard → account avatar → "Access Tokens" | Only needed for non-interactive CLI login (`SUPABASE_ACCESS_TOKEN` env var) as an alternative to `supabase login` |

---

## 7. Troubleshooting

- **"Invalid API key" when the app starts** — double-check you copied the `anon` key, not the
  `service_role` key, into `SUPABASE_ANON_KEY`, and that there's no extra space or line break
  pasted in.
- **App builds but the login screen errors on sign-in** — confirm `npx supabase db push`
  (or the manual SQL Editor steps) completed with no errors, and that "Confirm email" is
  disabled (§3.3 step 4, Option B) if sign-up sessions aren't returning.
- **Deck/list is empty after logging in** — run the seed script (§3.4); nothing is empty because
  of a code bug, it's because your database has no data yet.
- **AI features return generic/templated text instead of real generated content** — this is
  expected, intentional fallback behavior when `GEMINI_API_KEY` is missing/invalid or the daily
  token budget (`AI_DAILY_TOKEN_BUDGET`) has been used up for the day; it is not an error.
- **`supabase: command not found`** — always run it as `npx supabase ...` (not bare `supabase`)
  from the repo root, after `npm install`.
- **Windows PowerShell error on `export VAR=value`** — that syntax is bash-only; use
  `$env:VAR = "value"` instead (see the PowerShell blocks in §3.4).

---

## 8. Security notes

- The `SUPABASE_ANON_KEY` is the only secret that's safe to ship inside the compiled apps —
  Supabase's row-level security policies (not this key) are what actually protect the data.
- If you ever suspect a key has leaked (e.g. pasted into a tracked file and pushed to GitHub),
  regenerate it immediately from the Supabase dashboard (Project Settings → API → "Reset" next
  to the key) or Google AI Studio, rather than trying to scrub git history after the fact.
