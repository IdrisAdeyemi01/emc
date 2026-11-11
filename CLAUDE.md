# CLAUDE.md: EMC Portal

This file is the source of truth for how this project is built. Read it fully at the start of every session.
If something here conflicts with a request, ask before deviating. When a decision changes, update this file in the same change.

---

## 1. Project overview

**EMC Portal** is the web app (and later mobile app) for our **Extra Mural Class (EMC)**, an after-school tutoring program for JSS 1 to SSS 3 students.

- **Phase now:** Website only, built with **Jaspr** (Dart web framework), hosted on **GitHub Pages** at `https://idrisadeyemi01.github.io/emc/` (repo `IdrisAdeyemi01/emc`).
- **Later:** An Android APK built with **Flutter**, reusing the same Dart business logic.
- **Backend / source of truth:** A **Google Sheet** that admins edit directly. The app never owns data that lives in the sheet. Every page load or refresh must show the sheet's current data.
- **First feature:** Teacher Daily Reminders (section 2). More features will follow (timetable view, teacher directory, attendance, etc.), so build everything as one feature inside a multi-feature app, not as a one-off page.

> Note on "Flutter Jaspr": Jaspr is not Flutter. It is a Dart framework with a Flutter-like component API that renders real HTML/CSS. UI code is **not** shared between the Jaspr site and the future Flutter app. What **is** shared is the pure-Dart core package (models, parsing, business rules, message building). That's why the core must never import Jaspr or Flutter.

---

## 2. Current feature: Teacher Daily Reminders

### 2.1 Problem
Every class day, the EMC admin opens each scheduled teacher's WhatsApp chat one at a time, copy-edits a reminder template (class, subject, start time), and sends it. It's repetitive and easy to get wrong (wrong class, missed teacher).

### 2.2 Goal
Open the site, see **today's teachers** already computed from the sheet, and send each reminder in **one or two taps**.

### 2.3 Data source: `Teachers' Contacts` sheet

Spreadsheet ID: `<not stored in the repo; the Apps Script is bound to the sheet>`
Tab name: `Teachers' Contacts` (straight apostrophe; match exactly)

**This tab is the only data source for this feature.** Whatever is in it is what gets sent. There is no separate active/inactive filter; if a teacher shouldn't get reminders, the admin removes or changes their row in this tab.

Columns (header row 1):

| Day | Class | Subject | Teacher | Phone numbers | Start Time |
|---|---|---|---|---|---|
| Monday | JSS 1 | Mathematics | Bro Yusuf Adebayo | 08xxxxxxxxx | 4:00 PM |
| Saturday | SSS 1 | Literature | Bro Kareem Lawal | 07xxxxxxxxx | 12:00 PM |

Current Start Time values: `4:00 PM` (Monday to Thursday); `10:00 AM`, `12:00 PM`, `2:00 PM` (Saturday periods). Don't hardcode these; they come from the sheet.

Real data quirks the parser **must** handle (all observed in the live sheet):
- **Locate columns by header name, never by position.** Match headers case-insensitively, trimmed. Admins may reorder or add columns. Accepted phone headers: `Phone numbers`, `Phone number`, `Phone`. Accepted time headers: `Start Time`, `Time`.
- Class days are currently Monday to Thursday and Saturday. Don't hardcode that; derive from data.
- Day values may vary: `Wednesday`, `Weds`, `Wed`, `wednesday ` → normalize to a `Weekday` enum.
- **One teacher can have several classes on the same day** (e.g. Saturday: Bro Kareem Lawal teaches JSS 3 English, SSS 1 English and SSS 1 Literature).
- **The same person can appear under slightly different names** with the same phone (e.g. `Sis Aisha Bello` / `Sis Aishah Bello`, `Mr Danjuma` / `Mr Danjuma (DJ)`). Treat the phone as the identity.
- Phones are Nigerian local format (`08000000001`), possibly with spaces, `+234`, or `234` prefix.
- Blank rows, trailing spaces and stray whitespace in all cells.
- Class labels are `JSS 1`...`SSS 3`; display exactly as written in the sheet.

Other tabs (`School Period`, `Teachers List & Subject`, `Holiday Coaching`) are free-form human layouts. **Do not read or parse them.**

### 2.4 Business rules (all live in `emc_core`, all unit-tested)

1. **"Today" is computed in Africa/Lagos time (UTC+1, no DST)**, regardless of the device timezone: `DateTime.now().toUtc().add(const Duration(hours: 1))`. Keep this in a single injectable `Clock` so tests can control it.
2. The admin can switch the selected day (e.g. pick tomorrow to send reminders the night before). Default = today.
3. **Group sessions by normalized phone number.** One reminder per teacher per day, listing all their classes that day.
4. Within a reminder, order classes by start time (parse `h:mm AM/PM`, also tolerate `4pm`, `4 pm`, `16:00`), then by class. If a time can't be parsed, keep sheet order for that row and still display the raw text.
5. Order teacher cards on the page by their earliest class time, then by name.
6. Display name for a group = the teacher name from the first row for that phone that day.
7. **Phone normalization** to WhatsApp international format (digits only, no `+`):
   - strip spaces, dashes, brackets, leading `+`
   - `0XXXXXXXXXX` (11 digits) → `234XXXXXXXXXX`
   - `234XXXXXXXXXX` (13 digits) → keep
   - anything else → **invalid**. Show the card with a warning and disable its send button. Never guess.
8. If no rows match the selected day, show an empty state ("No classes scheduled for Friday"), not an error.
9. **Unusable rows:** fully blank rows are dropped silently. A row with a blank or unrecognizable Day, or a Day but no Class/Subject/Teacher/Phone, is skipped and counted (`Timetable.skipped`, row number + reason only) so the UI can say "1 row couldn't be read".
10. **Blank phone:** the row still becomes a card with an invalid-phone warning ("No phone number in the sheet"). Blank-phone rows are grouped by teacher name; other invalid phones by their raw text.
11. **Unreadable times** sort after readable ones, in sheet order (within a card); teachers with no readable time go last (on the page).
12. Day chips = days with classes, plus today even if it has none.

### 2.5 Message template

Reproduce the admin's template **exactly**, including her spelling, punctuation, the curly apostrophe in "you’re", WhatsApp `*bold*` markers, blank lines and trailing spaces. Do **not** "correct" the Arabic transliterations.

Single class:
```
Assalamu Alaykum Warahmotullahi Wabarakaatuhu

Hope you’re doing great today.

This is to remind you of your class at EMC today. 

Details below:
*Class* : SS3
*Subject* : Mathematics 
*Start Time* : 4pm

Kindly take note.
Jazzakumullahu khayran

Signed: EMC Admin
```

Multiple classes the same day: "your class" becomes "your classes", and each class gets its own block separated by a blank line:
```
...
This is to remind you of your classes at EMC today. 

Details below:
*Class* : SSS 1
*Subject* : English
*Start Time* : 10:00 AM

*Class* : SSS 1
*Subject* : Literature
*Start Time* : 12:00 PM

Kindly take note.
...
```

Field values (`Class`, `Subject`, `Start Time`) are inserted **exactly as written in the sheet** (e.g. `SSS 3`, `4:00 PM`). The `SS3` / `4pm` in the sample above is the admin's original example, not a format to convert to.

If the selected day isn't today, replace "today" in "your class at EMC today" with the weekday, e.g. "at EMC on Saturday". "Hope you’re doing great today." stays unchanged.

If a row's Start Time cell is blank, the card shows a "Start time missing" warning and the admin must type it into the editable preview before sending.

Cells are trimmed (stray whitespace), so a value never carries a trailing space: the admin's sample `*Subject* : Mathematics ` comes out as `*Subject* : Mathematics`. The template's own trailing space after "today." / "on Saturday." stays, and so does the one in a blank `*Start Time* : ` line.

The template string lives in one place (`emc_core`, `ReminderTemplate`). Build it with a pure function `String buildReminderMessage(TeacherReminder r, {required bool isToday})`. Golden-string tests cover the single-class, multi-class, not-today and missing-time variants.

### 2.6 WhatsApp delivery

**Build now: click-to-chat links. Free, no Meta account, no ban risk.**
- Each teacher card has a **"Send on WhatsApp"** button that opens
  `https://wa.me/<234number>?text=<Uri.encodeComponent(message)>` in a new tab.
  On a phone this opens the WhatsApp app in that teacher's chat with the message prefilled; the admin just taps send.
- A **"Copy message"** button as a fallback, with a short "Copied" confirmation.
- The message preview is **editable** (textarea) before sending. Edits aren't persisted to the sheet.
- After tapping send, the card is marked **"Sent ✓"** (stored in `localStorage` keyed by `yyyy-MM-dd` + phone, so it survives a refresh that day and resets the next day). The admin can toggle it back. Wrap all `localStorage` access in try/catch; if it fails, keep state in memory.
- Header shows a progress count: "4 of 7 sent".

**Out of scope for now:** automated "Send all" through the official WhatsApp Cloud API. Don't build or scaffold it. If it's picked up later it must be server-side (Apps Script), use an approved message template, and keep tokens out of the web app.

**Never** use unofficial WhatsApp automation (whatsapp-web.js, Baileys, browser automation of WhatsApp Web, etc.). It breaks WhatsApp's terms and gets numbers banned.

### 2.7 Backend: Google Apps Script web app (thin proxy over the sheet)

Why not read the sheet straight from the browser: the "anyone with link" CSV export works, but it exposes every teacher's phone number to anyone with the link, and browser CORS behaviour on Google's export endpoints is unreliable. The Apps Script runs as the sheet owner, so the sheet can be made private.

Lives in `backend/apps_script/` (`Code.gs` + `appsscript.json` + `README.md` with deploy steps), deployed with `clasp` or by pasting into the Apps Script editor. Bound to the EMC spreadsheet.

**Contract v1:**
```
GET {EMC_API_URL}?action=contacts&key={EMC_API_KEY}

200 → {
  "ok": true,
  "fetchedAt": "2026-11-10T17:56:00Z",
  "sheet": "Teachers' Contacts",
  "headers": ["Day","Class","Subject","Teacher","Phone numbers","Start Time"],
  "rows": [ ["Monday","JSS 1","Mathematics","Bro Yusuf Adebayo","08000000001","4:00 PM"], ... ]
}
error → { "ok": false, "error": "unauthorized" | "sheet_not_found" | "unknown_action" | "not_configured" | "not_bound" | "internal" }
```
- Return **raw headers + raw rows** using `getDisplayValues()`, so times arrive exactly as shown in the sheet (`4:00 PM`), not as date serials. All parsing and rules stay in Dart (`emc_core`), so they're testable and shared with the future Flutter app.
- **No caching** (no `CacheService`). Freshness beats speed here.
- `key` is a shared secret from Script Properties. It's light protection against casual discovery, not real auth (it ships inside the public JS bundle). Real admin login comes with a later feature.

The Dart side talks to the backend only through a `TimetableRepository` interface, so the data source can be swapped (a fake for tests, Firebase later) without touching UI or rules.

---

## 3. Architecture

### 3.1 Repository layout (Dart pub workspace, Dart ≥ 3.10)

```
emc/
├── CLAUDE.md
├── pubspec.yaml                 # workspace root: lists packages/ and apps/
├── analysis_options.yaml        # shared lints (package:lints/recommended + strict-casts/inference/raw-types)
├── .github/workflows/deploy.yml # build Jaspr site + deploy to GitHub Pages
├── docs/
│   ├── deploy.md                # Pages setup, secrets, key rotation
│   ├── admin-guide.md           # short how-to for the EMC admin
│   └── design/
│       └── README.md            # approved design links, decisions, screen inventory (section 4)
├── packages/
│   └── emc_core/                # PURE DART. No Jaspr, no Flutter, no dart:html/web.
│       ├── lib/
│       │   ├── emc_core.dart    # public barrel export
│       │   └── src/
│       │       ├── common/      # Clock, Result type, failures, Weekday enum, time parsing
│       │       ├── timetable/   # ClassSession model, sheet row parser, TimetableRepository (abstract)
│       │       └── reminders/   # TeacherReminder, grouping, PhoneNumber, ReminderTemplate
│       └── test/                # unit tests + fixtures (FAKE phone numbers only)
├── apps/
│   ├── emc_web/                 # Jaspr app (client mode, static hosting)
│   │   ├── lib/
│   │   │   ├── main.client.dart # browser entrypoint (compiled to main.client.dart.js)
│   │   │   ├── app.dart         # root component: Router
│   │   │   ├── core/            # router.dart (routes + AppPaths), env.dart, later data/ (http data source impl)
│   │   │   ├── shared/          # reusable components (buttons, cards, chips, empty/error/loading states, layout shell)
│   │   │   └── features/
│   │   │       ├── home/        # <feature>_strings.dart + ui/
│   │   │       └── reminders/   # <feature>_strings.dart + state/ + ui/
│   │   └── web/
│   │       ├── index.html          # <base href="/">; no <title> (routes set it)
│   │       ├── styles/tokens.css   # DESIGN TOKENS: single source of truth (CSS custom properties)
│   │       ├── styles/base.css     # reset, typography, layout primitives
│   │       └── assets/brand/       # emc-logo.svg (use this) + owner's original JPGs
│   └── emc_mobile/              # Flutter app: NOT created yet. Will depend on emc_core.
└── backend/
    └── apps_script/             # Code.gs, appsscript.json, README.md (deploy steps)
```

### 3.2 Layering rules
- **Feature-first** folders inside each app; inside a feature: `data/` (if feature-specific), `state/`, `ui/` (pages + components).
- Dependency direction: `ui → state → emc_core`. UI never parses sheet data, builds phone numbers or composes messages; it calls `emc_core`.
- `emc_core` exposes the `TimetableRepository` **interface** and models. The HTTP implementation (`AppsScriptTimetableRepository`) lives in `apps/emc_web/lib/core/data/` (move to a small `emc_data` package when the Flutter app needs it). Use `package:http` so it works on web and mobile. JSON decoding of the response (`decodeContactsResponse` / `timetableFromResponse`) lives in `emc_core`, so the repository is only HTTP + failure mapping and the Flutter app can reuse the decoding.
- Errors: return a sealed `Result<T>` / failure types from the repository (network error, unauthorized, sheet missing, malformed headers). UI maps each to a human message + Retry button. No uncaught exceptions reaching the UI.
- Immutable models (`final` fields, `const` constructors, `==`/`hashCode`). Use Dart 3 records/sealed classes/pattern matching. Only add `freezed`/`json_serializable` if models grow enough to justify codegen.

### 3.3 Jaspr app specifics
- Mode: **client** (SPA compiled to static files). Data is fetched in the browser on each load, which meets the "refresh shows latest data" requirement.
- Routing with `jaspr_router`. Initial routes: `/` (home with feature tiles), `/reminders`. Leave room for future routes.
- State: `jaspr_riverpod`. One provider for the fetched sheet data (refreshable), derived providers for the selected day and grouped reminders, and a notifier for "sent" state.
  - As built (M4): `core/providers.dart` (clock, repository, storage, clipboard: override these in tests), `features/reminders/state/` (`timetableProvider` with Loading / NotConfigured / Loaded(refreshing) / Failed(retrying) states, selected day, reminders, sent marks, message drafts, toast). Components read providers with `context.watch` / `context.read`.
  - Browser APIs (localStorage, clipboard) live behind interfaces in `core/browser/` and use `package:universal_web`, never `package:web`, so component tests run on the VM.
  - Jaspr's `onClick` calls `preventDefault()` on `<a>` elements. For links that must still open (the `wa.me` Send link), attach a raw `events: {'click': ...}` listener instead (see `AppButton`).
  - Only one `jaspr serve` can run per package directory (shared build daemon).
  - Every routed page's `build` returns **one root element** (`div(classes: 'page', ...)`), never `Component.fragment`: the browser renderer can't detach a top-level fragment when the router swaps pages, so the URL changes but the old page stays. `test/core/router_test.dart` guards this.
- Jaspr's API has changed between versions. **Before writing components, check the installed `jaspr` version's docs/changelog** (e.g. the `build` method signature and styling APIs) instead of assuming from memory.
- Installed versions (M1): `jaspr` 0.23.5, `jaspr_router` 0.9.0, `jaspr_cli` 0.23.5. Components are `Component build(BuildContext context)`; HTML helpers (`div`, `main_`, `img`, ...) come from `package:jaspr/dom.dart`; text is `Component.text(...)`; route titles come from `Route(title: ...)`.
- Styling: components use CSS classes and `var(--token)` values from `web/styles/tokens.css`. No hardcoded colors, sizes or spacing in components. See section 4.
  - Styles are **plain CSS files** in `web/styles/` linked from `index.html`: `tokens.css`, `base.css`, `components.css` (all of `lib/shared/`), then one file per feature (`reminders.css`, which also holds Home). Few files keep requests low on mobile data. Don't use Jaspr's `@css`/`Styles` API. `pubspec.yaml` sets `jaspr: styles: standalone` only because client mode requires it.

### 3.4 Hosting: GitHub Pages
- URL: `https://idrisadeyemi01.github.io/emc/`, a **project site** from the public repo `IdrisAdeyemi01/emc` (`emc.github.io` wasn't available). Source `index.html` keeps `<base href="/">` for local dev; the workflow rewrites it to `/<repo>/` (`BASE_PATH`), and Jaspr's router and the relative asset URLs follow `<base href>`. For a user/org site set `BASE_PATH: /`.
- Deploy with GitHub Actions (`.github/workflows/deploy.yml`): set up Dart, `dart pub get`, `dart analyze` + tests, `jaspr build` with the defines from repo **Actions secrets**, then `actions/upload-pages-artifact` + `actions/deploy-pages`. Pages source = "GitHub Actions".
- GitHub Pages has no SPA rewrites: a refresh on `/reminders` would 404. The workflow copies the built `index.html` to `404.html`, adds an empty `.nojekyll` and drops build leftovers (`packages/`, `.dart_tool/`, `.build.manifest`). Setup steps and key rotation: `docs/deploy.md`; admin how-to: `docs/admin-guide.md`.

### 3.5 Config & secrets
- `EMC_API_URL` and `EMC_API_KEY` are passed at build time with `--dart-define` (read via `const String.fromEnvironment` in `apps/emc_web/lib/core/env.dart`). Both `jaspr serve` and `jaspr build` accept `--dart-define=KEY=VALUE` and `--dart-define-from-file=<.env or .json>` (verified with jaspr_cli 0.23.5).
- Locally: a git-ignored `.env.local` at the repo root, passed with `--dart-define-from-file` (variables documented in `.env.example`). In CI: GitHub Actions secrets.
- **Never commit real keys, tokens or real phone numbers.**

---

## 4. Design: Claude Design workflow and design brief

### 4.1 Workflow (mandatory for UI work)
UI is designed **before** it is built. For any new screen or significant UI change:

1. **Design system first (once).** Before the first screen, create the EMC design system: color, type, spacing, radius, shadow and motion tokens + core components (section 4.4). Record the tokens as CSS custom properties in `docs/design/tokens.css` during M0 (no app exists yet); M1 moves that file to `apps/emc_web/web/styles/tokens.css`, which is its permanent home. Once tokens and shared components exist in code (end of M4), publish them so later designs inherit them: this is the **EMC Mint Paper** Design System artifact (https://claude.ai/artifact/8G4Ynxe1Nx9dzvMzCndRc7). Start new `/design` canvases from it, and update it whenever `tokens.css` or the shared component CSS changes.
2. **Explore with `/design`.** Use `/design` with the brief in 4.2/4.3 to generate **2 to 3 directions** as artboards for the screen, covering the states listed for it. Note the trade-offs between directions.
3. **Owner picks.** Stop and wait for Idris to choose a direction and leave comments. Refine until approved. Don't implement an unapproved design.
4. **Record it.** Add the approved design link + key decisions to `docs/design/README.md`.
5. **Implement in Jaspr.** Translate the approved artboard into Jaspr components:
   - Artboards are HTML/CSS (often React-style). **Never** add React, Tailwind, npm build tooling or any JS framework to this project. Rebuild the layout as Jaspr components with semantic HTML.
   - Map every value to a token in `tokens.css`. If the design needs a value with no token, add the token (and note it) rather than hardcoding.
   - Reuse `shared/` components; create a new shared component only if it will be reused.
6. **Verify against the design.** Run `jaspr serve`, check at 360px, 768px and 1280px widths, compare with the artboard, and fix differences before calling the task done.

### 4.2 Design brief
- **Primary user:** the EMC admin, on an **Android phone**, often on mobile data. Secondary: other EMC coordinators on laptops.
- **Job to be done:** in under two minutes, see today's teachers and send every reminder, knowing for sure who's been reminded.
- **Context and tone:** an Islamic community tutoring program. Calm, clean, respectful and trustworthy. Not playful, not corporate. No photos of people.
- **Brand assets:** in `apps/emc_web/web/assets/brand/` (moved from `docs/design/brand/` in M1).
  - `emc-logo.svg`: the EMC mark, a green square with a stepped "E" cut out. The cut-out is transparent, so it works on any background. Use this for the app; the PNG/JPEG files are the owner's originals for reference.
  - Official backgrounds the logo appears on: white `#FFFFFF`, charcoal `#2F2F2F`, black `#000000`.
  - Don't redraw, recolor, rotate, add effects to or crop the logo. Give it clear space of at least 25% of its width.
- **Brand colors (from the logo):**
  - Brand green `#27A844`. **Contrast warning:** only 3.1:1 on white. It's fine for the logo, large headings (≥ 24px, or ≥ 19px bold), icons, progress bars and decorative fills. It must **not** be used for body text or as a background behind normal-size white button labels.
  - For primary buttons, links and green text, derive a darker shade that passes AA, e.g. `#1E7F34` (5.07:1 with white). Final values are chosen in the design-system step.
  - Charcoal `#2F2F2F` (13.4:1 on white): primary text, dark surfaces and app header candidate.
  - The design system builds a full scale (green 50 to 900, neutrals from charcoal) plus semantic colors (success, warning, danger, info) that don't clash with the brand green. Note that "Sent ✓" success and brand green must stay distinguishable (use icon + text, not color alone).
- **Character of the mark:** geometric, square, solid, no curves. Let this guide the UI: crisp edges, small radii (0 to 6px), confident blocks of color, no playful rounded bubbles or gradients.
- **Performance:** light pages. System font stack, or at most one self-hosted font with 2 weights. SVG icons. No heavy images.
- **Language:** English UI. Islamic greetings appear only inside message content, as written in the template.

### 4.3 Screens and required states

**Home (`/`)**: EMC name/logo, a tile for "Teacher Reminders" (with today's count, e.g. "7 teachers today"). Leave space for future feature tiles. Don't show fake "coming soon" features.

**Teacher Reminders (`/reminders`)**:
- Sticky header: page title, **day selector** (chips for days that have classes, today marked and selected by default), progress ("4 of 7 sent" + bar), **Refresh** button, "Last updated 6:42 PM".
- **Teacher card**: teacher name; list of classes (class, subject, start time); status badge (Not sent / Sent ✓); collapsible editable message preview; primary **Send on WhatsApp** button; secondary **Copy message** button; "Mark as not sent" when sent.
- States to design: loading (skeleton cards), list with mixed sent/unsent, **all sent** (completion moment), empty day, error with retry, card with **invalid phone** (send disabled + reason), card with **missing start time** (warning, preview must be edited), card for a teacher with **3 classes** (Saturday case).
- Use a generic send/chat icon on the WhatsApp button, not the WhatsApp logo.

### 4.4 Design system rules
- **Mobile-first:** base layout at 360px wide, single-column cards; 2 columns from 768px; content max-width ~1100px on desktop.
- **Touch targets ≥ 44px**, primary actions reachable by thumb.
- **Accessibility:** WCAG 2.1 AA contrast, semantic HTML (`main`, `header`, `h1`, `button`, `label`), visible focus rings, status never shown by color alone (icon + text), respects `prefers-reduced-motion`.
- Light theme first; structure tokens so a dark theme can be added later.
- Core shared components: AppShell/header, Button (primary/secondary/ghost, loading/disabled), Chip (day selector), Badge, Card, ProgressBar, Textarea, Toast, Skeleton, EmptyState, ErrorState.

---

## 5. Commands

> Keep this section accurate. Verified at M1 (Dart 3.13.7, jaspr_cli 0.23.5).

```bash
# one-time setup
dart pub global activate jaspr_cli            # if `jaspr` isn't installed
export PATH="$PATH:$HOME/.pub-cache/bin"      # add to your shell profile; `jaspr` lives here
cp .env.example .env.local                    # then fill in EMC_API_URL / EMC_API_KEY (git-ignored)

# from repo root
dart pub get                                  # resolves the whole workspace (one pubspec.lock)
dart analyze                                  # must be clean (0 issues)
dart format .

# core
cd packages/emc_core && dart test             # unit tests
cd packages/emc_core && dart run coverage:test_with_coverage   # writes coverage/lcov.info (git-ignored)

# web (from apps/emc_web)
jaspr serve --dart-define-from-file=../../.env.local   # dev server, http://localhost:8080 (use --port to change)
jaspr build --dart-define-from-file=../../.env.local   # output: apps/emc_web/build/jaspr

# web tests (from apps/emc_web; VM tests, no browser needed)
dart test

# demo mode (from apps/emc_web): fake Saturday data + fixed clock, for design checks
# and screenshots without real teachers' details
jaspr serve --port 8092 --dart-define=EMC_DEMO=true

# live backend check (from apps/emc_web; reads ../../.env.local, prints counts only)
dart run tool/check_backend.dart

# backend: deploy steps in backend/apps_script/README.md (paste into the bound script, or clasp)
cd backend/apps_script && clasp push && clasp deploy

# deploy: push to main → GitHub Actions analyzes, tests, builds and publishes to
# https://idrisadeyemi01.github.io/emc/ (one-time setup in docs/deploy.md)
```

## 6. Coding conventions
- Effective Dart style; `dart format` with default line length; `dart analyze` must be clean before a task counts as done.
- Small files and small components. Extract a component once it passes ~150 lines or is reused.
- Names: files `snake_case.dart`; one public class per file where reasonable; components end in a noun (`ReminderCard`, `DaySelector`).
- No business logic in components. No `print`; use a tiny logger in `emc_core/common`.
- No new dependency without a one-line justification in the commit message. Prefer the Dart SDK + `http`, `jaspr`, `jaspr_router`, `jaspr_riverpod`, `test`, `mocktail`.
- User-facing strings for a feature live together in one file per feature, ready for later localization.
- Commits: conventional commits (`feat(reminders): ...`, `fix(core): ...`, `test(core): ...`). One logical change per commit.

## 7. Testing (required, not optional)
- `emc_core` targets **~100% coverage of business rules**: header lookup, day normalization, row parsing with messy input, time parsing/sorting, phone normalization (valid/invalid cases), grouping by phone (multi-class, name variants), message building (golden strings for single, multi-class, not-today, missing time).
- Test fixtures mirror the real sheet's shape and quirks but use **fake** names/numbers (e.g. `08000000001`).
- Repository: test JSON decoding and every failure mapping with a fake HTTP client.
- Web: component tests for key states (loading, error, empty, list) using `jaspr_test` where practical; otherwise keep components thin enough that core tests cover the logic.
- Before saying a task is done: `dart analyze` clean, `dart test` green, and (for UI work) the page runs locally with `jaspr serve` and matches the approved design.

## 8. Security & privacy
- Teacher phone numbers are personal data. Don't log them, don't commit them, and don't put them in screenshots, fixtures or design artboards (use fake numbers in designs).
- Once the Apps Script backend works, the sheet owner switches the spreadsheet's link sharing from "Anyone with the link" to restricted. The app must keep working, since it reads via the script.
- `wa.me` links contain the phone and message; that's acceptable because the admin opens them herself.

## 9. Roadmap
- **M0** Design first (section 4), before any code exists: design system + tokens (saved to `docs/design/tokens.css`), then Home and Teacher Reminders screens with all states, via `/design`. Owner approval required. Output: `docs/design/README.md` with approved links and decisions. **Done 2026-11-11.**
- **M1** Workspace scaffold: root workspace, `emc_core`, `emc_web` (Jaspr client mode), lints, router with placeholder pages. `git mv docs/design/tokens.css apps/emc_web/web/styles/tokens.css` so there is only ever one tokens file; update the pointer in `docs/design/README.md`. **Done 2026-11-11.**
- **M2** `emc_core`: models, parser, time parsing, phone, grouping, template, Clock + full tests. **Done 2026-11-11.**
- **M3** Apps Script backend v1 (`contacts` action) + README deploy steps; `AppsScriptTimetableRepository` + tests. **Done 2026-11-11** (live check passed; the browser fetch is first exercised in M4).
- **M4** Build the approved UI in Jaspr: shared components, Reminders page wired to real data, sent tracking, all states. Then `/design-sync`. **Done 2026-11-11.** `/design-sync` replaced by the EMC Mint Paper Design System artifact (see decisions).
- **M5** GitHub Pages deploy via Actions (`idrisadeyemi01.github.io/emc`), SPA 404 fallback, short admin how-to in `docs/`. **Done 2026-11-11** (workflow + docs; site goes live once the repo secrets and Pages source are set).
- **Later** Flutter `emc_mobile` app on `emc_core`; more features (timetable view, teacher directory, attendance, admin auth).

## 10. Rules for Claude
- Work milestone by milestone. For anything non-trivial, propose a short plan first and wait for approval.
- Design comes first. No UI implementation without an approved design (section 4.1), except M1 placeholder pages.
- Don't run `flutter create` anywhere in this repo until the mobile milestone; then only inside `apps/emc_mobile/`.
- Keep `emc_core` pure Dart. If you feel the need to import Jaspr/Flutter/`dart:html`/`package:web` there, stop and restructure.
- Only read the `Teachers' Contacts` tab. Don't hardcode teachers, days, times or phone numbers.
- Don't change the message template wording.
- Don't build automated WhatsApp sending; don't add unofficial WhatsApp automation; don't put tokens in client code.
- When a requirement is unclear (e.g. a new sheet column), ask; don't guess.
- After finishing a milestone: update section 5 (Commands), section 11 (Decisions) and anything else that changed, then summarize what was done and what's next.

## 11. Decisions log
- 2026-11-10: Jaspr web first; Flutter mobile later sharing `emc_core`.
- 2026-11-10: Google Sheet (`Teachers' Contacts` tab) is the source of truth, read through an Apps Script proxy.
- 2026-11-10: Phase 1 delivery = `wa.me` click-to-chat links + copy + sent tracking.
- 2026-11-11: `Start Time` column added to the sheet; times come only from the sheet (no defaults in code).
- 2026-11-11: No active/inactive filtering; the `Teachers' Contacts` tab alone decides who gets reminders.
- 2026-11-11: Hosting on GitHub Pages at `emc.github.io`.
- 2026-11-11: WhatsApp Cloud API automation deferred; not in current scope.
- 2026-11-11: All UI goes through the Claude Design workflow (`/design`, `/design-sync`) before implementation.
- 2026-11-11: Design is milestone M0, done before any code is scaffolded.
- 2026-11-11: Brand = existing EMC logo (green `#27A844` square mark); brand green not used for body text or behind small white text due to contrast.
- 2026-11-11: Design system = Direction C "Mint Paper" (mint `--green-50` page, white cards, 6px radius, soft green-tinted shadows, system fonts). Actions and green text use `#1E7F34`; "Sent" uses `#0F5132` on `#DDF1E4` with a filled ✓ icon. Tokens in `docs/design/tokens.css`.
- 2026-11-11: `/reminders` layout = "Card stack": cards in time order, sent cards shrink to compact in place, message hidden until opened (open by default when the start time is missing). Two columns from 768px.
- 2026-11-11: Home = logo, date (Lagos time) and one Teacher Reminders tile with today's count and progress; no placeholder tiles.
- 2026-11-11: M0 complete; approved designs and decisions recorded in `docs/design/README.md`.
- 2026-11-11: Dart SDK floor raised to 3.10 (required by Jaspr 0.23). Workspace uses `resolution: workspace` with one root `pubspec.lock`.
- 2026-11-11: Styles are plain CSS files in `web/styles/`, not Jaspr's `@css` API, so the approved designs' CSS ports directly.
- 2026-11-11: `jaspr_riverpod` and `http` are added when first used (M3/M4), not in M1.
- 2026-11-11: `emc_core` test dependency pinned to `^1.26.0` (resolves to a version compatible with `jaspr_builder`'s analyzer 12).
- 2026-11-11: `index.html` has no static `<title>`; each route's `title` sets it (a static one would win over the router's).
- 2026-11-11: M1 complete.
- 2026-11-11: Unusable rows, blank phones, unreadable-time ordering and template trimming follow 2.4 rules 9-12 and the note in 2.5 (approved by Idris).
- 2026-11-11: `TimetableRepository.loadTimetable()` returns a parsed `Timetable`; implementations call `parseContactsSheet` on the raw `SheetTable`.
- 2026-11-11: `sentStorageKey(date, reminder)` takes the date as a parameter. Whether it's the send date or the class date (so reminders sent Friday night for Saturday still show "Sent" on Saturday) is decided in M4.
- 2026-11-11: Golden test strings write trailing spaces as `\u0020`, because editors strip real trailing spaces.
- 2026-11-11: `coverage` dev dependency added to measure the ~100% business-rule target (100% of `emc_core` lines at M2).
- 2026-11-11: M2 complete.
- 2026-11-11: Backend deployed by the sheet owner as a script bound to the spreadsheet (`spreadsheets.currentonly` scope), web app "Execute as: Me", "Anyone". A standalone script can't read the sheet and now returns `not_bound`.
- 2026-11-11: Backend errors added beyond v1's examples: `unknown_action`, `not_configured` (no key in Script Properties), `not_bound`. The app maps them to `UnexpectedResponseFailure`.
- 2026-11-11: The repository sends no custom headers (no CORS preflight), times out after 20 s (Apps Script cold starts), decodes UTF-8 itself, and never logs the URL (it carries the key) or the body (it holds phones).
- 2026-11-11: `createTimetableRepository()` returns null when `EMC_API_URL`/`EMC_API_KEY` are missing or the URL isn't https; M4 shows a setup error for that.
- 2026-11-11: `tool/check_backend.dart` verifies the live backend through the real repository and prints counts only. First run: 51 rows, 0 skipped, Saturday up to 3 classes per teacher.
- 2026-11-11: `http` (backend calls, named in 3.2) and `test` (web repository tests) added to `emc_web`.
- 2026-11-11: M3 complete. Pending owner step: set the spreadsheet's General access to Restricted.
- 2026-11-11: "Sent" marks are keyed by the **class date** (today, or the next occurrence of the selected weekday), so reminders sent the night before still show "Sent" on the day. Marks older than 14 days are deleted on load.
- 2026-11-11: Tapping Send on WhatsApp marks the card sent (CLAUDE.md 2.6); "Mark as not sent" undoes it. No Undo button on toasts.
- 2026-11-11: Rows the parser skipped show one info notice above the list ("1 row in the sheet couldn't be read"). Not in the approved artboards; approved by Idris in the M4 plan.
- 2026-11-11: Invalid-phone cards get a ghost "Mark as sent" button (the admin copies the message and sends it another way). Without it, "all sent" could never be reached while any phone is invalid. Not in the approved artboards.
- 2026-11-11: Send stays disabled while any `*Start Time* :` line in the (edited) message is blank (`messageHasBlankStartTime` in `emc_core`).
- 2026-11-11: Copy uses the Clipboard API, falling back to select + `execCommand('copy')`; if both fail, a toast says to press and hold the message instead.
- 2026-11-11: A failed refresh keeps the last loaded timetable on screen and shows a toast; only the first load shows the full error panel.
- 2026-11-11: Demo mode (`EMC_DEMO=true`) uses an in-memory store seeded with 3 sent marks and a clock fixed at Saturday 14 Nov 2026, 8:15 AM Lagos.
- 2026-11-11: Packages added to `emc_web`: `jaspr_riverpod` (state, named in 3.3), `universal_web` (browser APIs that still compile on the VM for tests), `jaspr_test` (dev, component tests).
- 2026-11-11: M4 complete. Verified in demo mode at 375/768/1280 against the artboards, and with the live backend in the browser (counts only, no screenshots of real data).
- 2026-11-11: `/design-sync` doesn't fit this repo (it uploads a compiled React library; our components are Jaspr/Dart) and standalone Claude Design closes by 14 Dec 2026. Instead, the **EMC Mint Paper** Design System artifact (https://claude.ai/artifact/8G4Ynxe1Nx9dzvMzCndRc7) holds `tokens.json` (converted exactly from `tokens.css`), `components/bundle.css` (base + components + reminders CSS), the logo, a conventions README with the class vocabulary, and static previews of 12 components using the real classes. No JS bundle.
- 2026-11-11: `emc.github.io` wasn't available. Hosting is a project site at `https://idrisadeyemi01.github.io/emc/` from the public repo `IdrisAdeyemi01/emc` (public because free Pages needs it). The default branch is `main`.
- 2026-11-11: Before the first push, git history was rewritten to replace a real phone number, real teacher names and the spreadsheet ID in CLAUDE.md with fake values. The spreadsheet ID isn't stored in the repo; the Apps Script is bound to the sheet.
- 2026-11-11: Base path is set at deploy time (the workflow rewrites `<base href>`), so `jaspr serve` keeps working at `/`. Verified with a local Pages-like server: cold deep link to `/emc/reminders` via `404.html`, navigation in both directions, and assets.
- 2026-11-11: The deploy workflow runs `dart analyze` and both test suites before building, so a red build never publishes.
- 2026-11-11: M5 complete.
