# Domus — Design System

**Calm Archive** — the quiet system for keeping a home's documents.

Domus treats the screen like good paper and labels things like a library
catalog. Surfaces are warm, ink is deep, motion is minimal. The interface
recedes so the documents — receipts, warranties, manuals, deeds — are what
you notice.

| | |
|---|---|
| **Version** | 1.0 — June 2026 |
| **Voice** | Plain, archival, unhurried |
| **Surface** | Warm paper & deep warm ink |
| **Accent** | Clay (swappable) |
| **Type** | Georgia · Helvetica · system mono (no custom fonts) |
| **Scaling** | [Utopia](https://utopia.fyi) fluid type & space |

Tokens live in [`domus-tokens.css`](domus-tokens.css) — import it once and
reference the custom properties below.

---

## Principles

1. **Calm over clever.** No performing buttons, no gradients, no bounce.
   Components sit flat and quiet. Emphasis comes from one calm accent and
   generous space — not from shadow and shine.
2. **Paper, not screen.** Warm stock, hairline rules, a faint 45° grain on
   placeholders. The feel of a well-kept filing cabinet, rendered crisply —
   never skeuomorphic.
3. **Label like a catalog.** Monospace, uppercase, letter-spaced labels mark
   every field and meta value — the way an archivist tags a folder.
4. **The tool recedes.** Capture is one tap; naming is one line; everything
   else waits. Structure (tags, details) arrives only when the moment calls
   for it.

---

## Foundations

### Scaling — Utopia

Type and space are **fluid**: a single `clamp()` per step interpolates
between a min and max as the viewport moves, so there are no breakpoints to
manage. The scale is generated with [Utopia](https://utopia.fyi).

| Setting | Min | Max |
|---|---|---|
| Viewport | 320px | 1240px |
| Body (step 0) | 18px | 20px |
| Type ratio | 1.20 — Minor Third | 1.25 — Major Third |

Below 320px the value pins to the min; above 1240px it pins to the max.
Everything is expressed in `rem`, so it also respects the user's browser
font-size preference.

#### Type scale

| Token | Min → Max | Role |
|---|---|---|
| `--step-5`  | 44.8 → 61.0px | Cover display |
| `--step-4`  | 37.3 → 48.8px | Section display |
| `--step-3`  | 31.1 → 39.1px | H1 / page title |
| `--step-2`  | 25.9 → 31.3px | H2 / section title |
| `--step-1`  | 21.6 → 25.0px | Lead · H3 |
| `--step-0`  | 18.0 → 20.0px | Body |
| `--step--1` | 15.0 → 16.0px | Small · chips · captions |
| `--step--2` | 12.5 → 12.8px | Eyebrows · catalog labels |

```css
:root {
  --step--2: clamp(0.7813rem, 0.7747rem + 0.0326vw, 0.8rem);
  --step--1: clamp(0.9375rem, 0.9158rem + 0.1087vw, 1rem);
  --step-0:  clamp(1.125rem,  1.0815rem + 0.2174vw, 1.25rem);
  --step-1:  clamp(1.35rem,   1.2761rem + 0.3696vw, 1.5625rem);
  --step-2:  clamp(1.62rem,   1.5041rem + 0.5793vw, 1.9531rem);
  --step-3:  clamp(1.944rem,  1.771rem  + 0.8651vw, 2.4414rem);
  --step-4:  clamp(2.3328rem, 2.0827rem + 1.2504vw, 3.0518rem);
  --step-5:  clamp(2.7994rem, 2.4462rem + 1.7658vw, 3.8147rem);
}
```

#### Space scale

Built from the body size, so spacing breathes in step with type. Use these
for padding, gap, and margins instead of fixed pixels.

| Token | Min → Max | Typical use |
|---|---|---|
| `--space-3xs` | 4.5 → 5px | Hairline gaps, icon insets |
| `--space-2xs` | 9 → 10px | Chip padding, tight stacks |
| `--space-xs`  | 13.5 → 15px | Label-to-field, button padding-y |
| `--space-s`   | 18 → 20px | Default gap inside a card |
| `--space-m`   | 27 → 30px | Card padding |
| `--space-l`   | 36 → 40px | Section gap |
| `--space-xl`  | 54 → 60px | Between sections |
| `--space-2xl` | 72 → 80px | Page padding |
| `--space-3xl` | 108 → 120px | Cover whitespace |

```css
:root {
  --space-3xs: clamp(0.2813rem, 0.2704rem + 0.0543vw, 0.3125rem);
  --space-2xs: clamp(0.5625rem, 0.5408rem + 0.1087vw, 0.625rem);
  --space-xs:  clamp(0.8438rem, 0.8111rem + 0.163vw,  0.9375rem);
  --space-s:   clamp(1.125rem,  1.0815rem + 0.2174vw, 1.25rem);
  --space-m:   clamp(1.6875rem, 1.6223rem + 0.3261vw, 1.875rem);
  --space-l:   clamp(2.25rem,   2.163rem  + 0.4348vw, 2.5rem);
  --space-xl:  clamp(3.375rem,  3.2446rem + 0.6522vw, 3.75rem);
  --space-2xl: clamp(4.5rem,    4.3261rem + 0.8696vw, 5rem);
  --space-3xl: clamp(6.75rem,   6.4891rem + 1.3043vw, 7.5rem);
}
```

> Utopia also generates **one-up pairs** (`--space-s-m`, `--space-m-l`, …) for
> asymmetric rhythm — a few are included in `domus-tokens.css`.

---

### Color

A warm, low-chroma neutral scale (whites and blacks tinted toward paper) plus
**one** muted accent. Never introduce a second accent in the same view.

#### Paper & ink

| Token | Hex | Role |
|---|---|---|
| `--w-desk`    | `#E9E3D6` | Page background / desk |
| `--w-bg`      | `#F3EFE6` | Warm paper |
| `--w-surface` | `#FDFBF6` | Card stock |
| `--w-fill`    | `#EFE9DC` | Recessed paper |
| `--w-fill-2`  | `#E9E2D2` | Recessed, deeper |
| `--w-line`    | `#E4DDCF` | Hairline |
| `--w-line-2`  | `#D4CBB8` | Rule |
| `--w-ink-3`   | `#9B9384` | Faint catalog label |
| `--w-ink-2`   | `#6B6458` | Muted text |
| `--w-ink`     | `#2A261F` | Warm near-black — body, the mark |

#### Accent — Clay (shipping default)

| Token | Value | Role |
|---|---|---|
| `--w-accent`      | `#9A5A3C` | Primary fill, the dot, FAB, active tab |
| `--w-accent-ink`  | `color-mix(… 80%, black)` | Hover, links, primary-tile label |
| `--w-accent-soft` | `color-mix(… 12%, white)` | Recommended-tile tint, selection |

`-ink` and `-soft` are **derived** from `--w-accent` via `color-mix`, so
swapping the accent updates the whole family.

#### Sanctioned accent palette

The accent is chosen at the brand level and held constant. Swap by changing
`--w-accent` only.

| Name | Hex |
|---|---|
| **Clay** *(default)* | `#9A5A3C` |
| Sage | `#3F6B53` |
| Ink blue | `#2B4A78` |
| Slate | `#5B6470` |
| Tobacco | `#7A5A3A` |

---

### Typography

Three web-safe families, each with a clear job. No custom font loading.

| Role | Family | Stack |
|---|---|---|
| Display / Serif | **Georgia** | `Georgia, "Times New Roman", "Iowan Old Style", serif` |
| Interface / Sans | **Helvetica** | `"Helvetica Neue", Helvetica, Arial, system-ui, sans-serif` |
| Catalog / Mono | **System mono** | `ui-monospace, Menlo, Consolas, "Courier New", monospace` |

**Conventions**

- Headings & the wordmark: `--font-serif`, slight negative tracking
  (`letter-spacing: -0.012em`).
- Body, controls, leads: `--font-ui`.
- Eyebrows, field labels, chips, shortcuts: `--font-mono`, uppercase,
  `letter-spacing: 0.06–0.16em`.

```css
.h1      { font: var(--step-3)/1.06 var(--font-serif); letter-spacing: -0.018em; }
.h2      { font: var(--step-2)/1.10 var(--font-serif); letter-spacing: -0.012em; }
.lead    { font-size: var(--step-1); color: var(--w-ink-2); line-height: 1.5; }
.body    { font-size: var(--step-0); }
.eyebrow { font: 500 var(--step--2)/1 var(--font-mono);
           text-transform: uppercase; letter-spacing: 0.16em; color: var(--w-ink-3); }
.label   { font: 500 var(--step--2) var(--font-mono);
           text-transform: uppercase; letter-spacing: 0.06em; color: var(--w-ink-2); }
```

---

### Radius, elevation & grain

- **Radius** — base `--radius: 14px` for cards. Nested controls subtract
  (`calc(var(--radius) - 5px)` for buttons, `- 6px` for inputs) so corners
  stay concentric. Inputs ≈ 8px, tiles ≈ 11px, cards 14px.
- **Elevation** — two levels only: **flat** (default) and **float** (the one
  shadow), via `--shadow-float`. No mid-tier shadows.
- **Grain** — placeholders use a faint 45° repeating stripe over `--w-fill`:

```css
.shot {
  background:
    repeating-linear-gradient(45deg, transparent 0 8px,
      rgba(60,52,36,.045) 8px 9px),
    var(--w-fill);
  border: 1px solid var(--w-line-2);
  border-radius: calc(var(--radius) - 4px);
}
```

---

## Components

### Buttons

Flat and quiet — they recede, they don't perform. Primary is a calm accent
fill; default is paper with a rule; dark is reserved for a single committing
action (e.g. *Save*).

```css
.btn {
  display: inline-flex; align-items: center; gap: var(--space-2xs);
  padding: var(--space-xs) var(--space-s);
  border: 1px solid var(--w-line-2);
  border-radius: calc(var(--radius) - 5px);
  background: var(--w-surface);
  font: 550 var(--step--1) var(--font-ui); letter-spacing: -0.01em;
  color: var(--w-ink); cursor: pointer;
  transition: background .14s ease, border-color .14s ease;
}
.btn:hover           { background: var(--w-fill); }
.btn.primary         { background: var(--w-accent); border-color: var(--w-accent); color: #fff; }
.btn.primary:hover   { background: var(--w-accent-ink); border-color: var(--w-accent-ink); }
.btn.dark            { background: var(--w-ink); border-color: var(--w-ink); color: var(--w-bg); }
```

- **Sizes** — `sm` / default / `lg` adjust padding only; font stays on the
  scale.
- **Split button** — primary action + alternate share one accent-outlined
  group (e.g. *Capture | Browse*).

### Fields

```css
.field  { display: flex; flex-direction: column; gap: var(--space-2xs); }
.label  { /* mono, uppercase — see Typography */ }
.input  {
  border: 1px solid var(--w-line-2);
  border-radius: calc(var(--radius) - 6px);
  background: var(--w-surface);
  padding: var(--space-xs) var(--space-s);
  font-size: var(--step--1); color: var(--w-ink);
}
.caret  { width: 1.5px; height: 1em; background: var(--w-accent);
          animation: blink 1.05s steps(2) infinite; }
@keyframes blink { 50% { opacity: 0; } }
```

The caret is tinted with the accent — the only animated element in a field.

### Chips & meta

Monospace pills for file metadata (name, size, type). `--w-fill` background,
`--w-line` border, `--step--2` mono text, 6px radius.

### Segmented control

Pill track (`--w-fill`), the active segment lifts to `--w-surface` with a
1px shadow. Use for filters (*All · Receipts · Warranties*), never for primary
navigation.

### Cards

Warm `--w-surface`, 1px `--w-line`, `--radius`. Apply `--shadow-float` only
for the focused/primary card (e.g. the capture card or a document preview).

### Capture methods

The capture chooser ships in three sanctioned treatments — pick one per
surface:

| Variant | When |
|---|---|
| **Tiles** | Two equal options; the recommended path gets the `accent-soft` tint. |
| **Keys** | Desktop, power users — full-width rows with mono shortcut hints (`⌘⇧N`). |
| **Minimal** | Mobile / focused capture — one primary button + a quiet "or browse" link. |

### Icons

Line icons, `1.6` stroke, round caps & joins, drawn on a 24px grid. Set:
`camera · upload · image · doc · folder · search · home · plus · check · x ·
chev · swap · sparkle · lock`. Match stroke to text color; size by context
(13–22px).

---

## Voice & labels

Plain words, archival labels. Write like a calm archivist, not a marketer.

**Catalog labels** (uppercase mono): `NAME` · `SAVED` · `EDITABLE` ·
`RECOMMENDED`.

| Write like this | Not like this |
|---|---|
| "Take a photo or pick a file to keep." | "Effortlessly supercharge your workflow!" |
| "Tags & details come later — for now, just keep it." | "Oops! Something went wrong 😬" |
| "or drop an image onto this card" | "UPLOAD NOW — it's FREE" |

---

*Domus · Calm Archive · Design System v1.0 · June 2026*
