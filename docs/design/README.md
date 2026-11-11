# EMC design

Design record for the EMC Portal (see `CLAUDE.md` section 4). Nothing is implemented from a design until it is marked **Approved** here.

- **Canvas (all artboards):** https://claude.ai/artifact/UU3eetAw8dqqsq2UnusbAC (private; share from its Share menu)
  - Page *Design system*: the three explored directions (A Ledger, B Charcoal Block, C Mint Paper)
  - Page *Teacher Reminders*: `/reminders` Layout 1 (approved) and Layout 2 (not chosen), all states, 360 / 768 / 1280
  - Page *Home*: `/` at 360 and 1280
- **Tokens:** [`apps/emc_web/web/styles/tokens.css`](../../apps/emc_web/web/styles/tokens.css) (moved from `docs/design/` in M1; the only tokens file)
- **Brand assets:** [`apps/emc_web/web/assets/brand/`](../../apps/emc_web/web/assets/brand/) (`emc-logo.svg` is the one to use)

## Status

| Item | Status |
|---|---|
| Design system | **Approved: Direction C "Mint Paper"** (2026-11-11) |
| Teacher Reminders `/reminders` | **Approved: Layout 1 "Card stack"** (2026-11-11) |
| Home `/` | **Approved** (2026-11-11) |
| `/design-sync` | After M4, once tokens and shared components exist in code |

## Design system: C "Mint Paper"

A faint green-tinted page (`--green-50`) with white cards that lift gently off it, roomier spacing, 6px corners, and green as the accent for selection and action.

Chosen over:
- **A Ledger** (white, hairlines, 0px corners): calmest, but status hierarchy too quiet.
- **B Charcoal Block** (charcoal header, teal status bands): most glanceable, but heaviest and adds a second hue.

Known trade-off we accepted: with green used widely, "Sent" must not rely on color. It always uses the filled ✓ icon + the word "Sent" + the darker success fill (`--success-700` on `--success-50`, 7.9:1), which is visibly cooler and darker than brand green.

### Key decisions

- **Color.** Full green scale from brand `#27A844` and neutrals around charcoal `#2F2F2F`.
  - `--green-500` (brand, 3.1:1 on white): logo, icons, progress fill, decorative fills, headings ≥ 24px only.
  - `--green-700` `#1E7F34`: primary buttons (white label 5.07:1), links, green text (4.67:1 on the mint page).
  - `--green-800`: class start times inside cards (6.25:1 on mint).
  - `--green-900`: focus ring (3px, 2px offset).
  - Status pairs (text on tint): success `#0F5132/#DDF1E4`, warning `#8A5300/#FFF4DB`, danger `#B42318/#FDEDEB`, info `#1F5FA8/#EAF2FC`, all ≥ 5.7:1.
  - Muted text `#6B6B69`: 5.3:1 on white, 4.9:1 on mint.
- **Type.** System font stack, no web fonts. Scale 13 / 15 / 16 / 20 / 25 / 31 (ratio ~1.25), weights 400 / 600 (700 rare). Body line-height 1.55. Sentence case, no all-caps labels.
- **Space.** 4px base: 4, 8, 12, 16, 20, 24, 32, 48. Card padding 20 (16 for compact cards), page gutter 16 on phones.
- **Radius.** 0 / 4 (badges, bars) / 6 (cards, buttons, chips, inputs). Nothing rounder, to stay true to the square mark.
- **Shadow.** Two soft, green-tinted levels: `--shadow-1` cards, `--shadow-2` toasts.
- **Motion.** 150ms / 240ms, `cubic-bezier(.2,.8,.2,1)`. Toast rises 8px and fades. Spinner and skeleton shimmer are disabled under `prefers-reduced-motion`.
- **Controls.** Buttons 48px (primary send 52px), day chips 52px, all touch targets ≥ 44px. Primary = solid green-700; Secondary = white with 1.5px green-700 border and green-700 label; Ghost = green-700 label with icon.
- **Icons.** Inline stroke SVG, 2px, round caps. A generic paper-plane "send" icon on the WhatsApp button (not the WhatsApp logo).
- **Badges.** Not sent = white with neutral-300 border + hollow circle; Sent = success tint + filled ✓; Start time missing = warning; Invalid phone = danger.
- **Dark theme later.** Components use only the semantic layer, so a dark theme overrides that layer alone.

## Teacher Reminders: Layout 1 "Card stack"

Artboards: page *Teacher Reminders*, row "Layout 1 · Card stack" (`R1-Phone`, `R1-States`, `R1-768`, `R1-1280`).

Chosen over Layout 2 "Next up" (focused next teacher + grouped rows): the order never changes, so it's predictable, and every card can be acted on directly.

- **Sticky app bar:** back to Home, title, Refresh icon button; day chips (only days that have classes, plus today if it has none; today shows a "Today" line and is selected by default); progress "3 of 7 sent" + bar + "Updated 8:15 AM".
- **Order:** cards in sheet time order (earliest class, then name); rows with no start time go last. Sending doesn't reorder.
- **Unsent card:** name, phone, "Not sent" badge, class list (class · subject, time in green-800), message hidden behind "Show message", full-width Send on WhatsApp (52px) + Copy message.
- **Sent card:** shrinks to compact: name, "Sent" badge, class lines, "Mark as not sent".
- **Invalid phone:** "Invalid phone" badge + danger notice with the reason; Send disabled, Copy still works.
- **Missing start time:** "Start time missing" badge, "No time" in the class list, warning notice, message open with the empty `*Start Time* :` line highlighted; Send disabled with "Add the start time to send" until a time is typed.
- **All sent:** full progress bar, completion panel ("All 7 teachers reminded"), compact sent cards below.
- **Empty day:** calendar state "No classes scheduled for Friday" + "See Saturday’s teachers".
- **Error:** "Couldn’t load the timetable" + Try again; day chips and progress hidden.
- **Loading:** skeleton chips, progress and three skeleton cards (shimmer off under reduced motion).
- **768px:** two columns of cards, buttons stacked. **1280px:** content max-width 1100px, two columns, Send and Copy side by side, Refresh as a labelled button.

## Screen inventory

| Screen | Route | States | Status |
|---|---|---|---|
| Home | `/` | default | Approved |
| Teacher Reminders | `/reminders` | loading, mixed sent/unsent, all sent, empty day, error, invalid phone card, missing start time card, 3-class teacher | Approved (Layout 1) |

## Decisions log

- 2026-11-11: Three design-system directions explored; **C "Mint Paper"** approved by Idris. Tokens saved to `tokens.css` (now `apps/emc_web/web/styles/tokens.css`).
- 2026-11-11: Two `/reminders` layouts explored; **Layout 1 "Card stack"** chosen by Idris over Layout 2 "Next up".
- 2026-11-11: Home and `/reminders` Layout 1 approved by Idris. **M0 complete.**
