---
name: utopia
description: "Use this skill when working with Domus's fluid type and space scales — the Utopia-generated clamp() tokens (--step-* and --space-*) in docs/design/domus-tokens.css and public/app.css. Triggers: adding or regenerating a fluid type/space step, computing a clamp() value, changing the viewport/body/ratio config, or reasoning about why a size scales the way it does. Utopia (utopia.fyi) makes type and spacing interpolate fluidly between a min and max viewport with a single clamp() per step, so there are no breakpoints to manage."
---

# Utopia fluid type & space

Domus scales type and spacing with [Utopia](https://utopia.fyi): each step is
one `clamp()` that interpolates between a **min** size (at the min viewport)
and a **max** size (at the max viewport). Below the min viewport the value
pins to the min; above the max viewport it pins to the max — so there are no
breakpoints to manage.

Everything is in `rem`, never `px`. That isn't cosmetic: a `px`-bounded
`clamp()` can't be zoomed, which fails WCAG 1.4.4 (resize text). Keep the
bounds in `rem` so the scale tracks the user's browser font-size and zoom.

## Where the tokens live

- **`docs/design/domus-tokens.css`** — canonical token set referenced by the
  design system spec (`docs/design/design-system.md`).
- **`public/app.css`** — the tokens actually shipped to the browser.

Keep these consistent: regenerate from the same config and update both.

## Project config

The design-system scale uses:

| Setting | Min (320px viewport) | Max (1240px viewport) |
|---|---|---|
| Viewport | 320px | 1240px |
| Body (step 0) | 18px | 20px |
| Type ratio | 1.20 (Minor Third) | 1.25 (Major Third) |
| Space base | = body (18px) | = body (20px) |

Space multiples off the base: 0.25 / 0.5 / 0.75 / 1 / 1.5 / 2 / 3 / 4 / 6
(→ `3xs` … `3xl`). Utopia can also emit one-up pairs (`--space-s-m`, …).

> `public/app.css` and `docs/design/domus-tokens.css` are in sync — same
> config, identical `--step-*` / `--space-*` clamps. The only difference is
> the one-up pairs (`--space-s-m`, etc.), which live in `domus-tokens.css`
> but aren't shipped in `app.css` because no rule uses them yet. When you
> change the scale, regenerate from the config above and update both files.

## How a step is computed

For a step that goes from `minPx` (at `minVw` = 320) to `maxPx` (at `maxVw` =
1240):

```
slope        = (maxPx - minPx) / (maxVw - minVw)
vw           = slope * 100                       # the vw coefficient
interceptPx  = minPx - slope * minVw             # the rem offset, in px
clamp( minPx/16 rem , interceptPx/16 rem + vw·vw , maxPx/16 rem )
```

Worked example — body (step 0), 18→20px:

```
slope       = (20 - 18) / (1240 - 320) = 0.0021739
vw          = 0.21739vw
interceptPx = 18 - 0.0021739 * 320 = 17.30435px → 1.0815rem
→ clamp(1.125rem, 1.0815rem + 0.2174vw, 1.25rem)
```

Type steps are derived by multiplying/dividing the body by the ratio
(`step n = body * ratio^n`), using the **min ratio** for min sizes and the
**max ratio** for max sizes. Negative steps (`--step--1`, `--step--2`) divide
instead of multiply; Utopia keeps these shallow because deep negatives become
illegible. Space steps are the base size times the multiples above.

> **Accessibility check.** A step where `max` is more than ~2.5× its `min` can
> fail the 200%-zoom requirement. Utopia's calculators now flag these; keep
> type bounds within that ratio. (For Domus this is comfortably satisfied —
> body only goes 18→20px.)

## Generating tokens

Use the math above to compute a step by hand, or feed the project config
into the interactive generators:

- Type — <https://utopia.fyi/type/calculator>
- Space — <https://utopia.fyi/space/calculator>

Set viewport 320 → 1240, body 18 → 20, ratio 1.20 → 1.25, then copy the
emitted `--step-*` / `--space-*` clamps. Verify a new value against an
existing one in `docs/design/domus-tokens.css` (e.g. step 0 must stay
`clamp(1.125rem, 1.0815rem + 0.2174vw, 1.25rem)`) so the scale matches.

The space calculator can also emit **one-up pairs** like `--space-s-m` —
a single `clamp()` whose min is step `s` and max is step `m`, useful for a gap
that grows by a full step across the viewport range. Add them only if a layout
needs them; don't bulk-generate pairs.

> Newer Utopia tooling can target `cqi`/`cqw` (container queries) or `vi`
> (logical inline axis) instead of `vw`. Domus's tokens are `vw`-based — stay
> on `vw` unless you're deliberately introducing container-relative scaling.

## Using the tokens

Reference the custom properties; never hard-code sizes.

```css
.h1   { font-size: var(--step-3); }
.body { font-size: var(--step-0); }
.card { padding: var(--space-m); gap: var(--space-s); }
```

Type steps: `--step--2` (catalog labels) → `--step-5` (cover display).
Space steps: `--space-3xs` (hairline gaps) → `--space-3xl` (cover whitespace).
See `docs/design/design-system.md` for the role each step plays.
