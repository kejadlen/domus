# Agent instructions

## Task management

Use the `ranger` CLI to track all work. Every task should correspond to
a backlog entry before you start it.

The default backlog for this project is `domus`. The `RANGER_DEFAULT_BACKLOG`
environment variable is set to `domus`, so you can omit `--backlog` from all
ranger commands.

## Design system

Domus follows the **Calm Archive** design system — warm paper, deep warm
ink, one muted accent (Clay), web-safe type, and minimal motion. The full
spec lives in [`docs/design/design-system.md`](docs/design/design-system.md),
with the fluid type/space and color tokens in
[`docs/design/domus-tokens.css`](docs/design/domus-tokens.css).

When building or changing any UI:

- Read the spec before touching styles, and match its visual output. These
  are guidelines for real implementation (Phlex views, `public/app.css`),
  not files to copy verbatim.
- Reference the design tokens (`--w-*`, `--step-*`, `--space-*`) rather than
  hard-coding colors, font sizes, or spacing. Use the fluid `--step-*` /
  `--space-*` scales for type and spacing instead of fixed pixels.
- **Design prototypes are written in fixed `px` — do not copy those values
  verbatim.** When implementing, map every font size, gap, padding, and
  margin onto the nearest `--step-*` / `--space-*` token. Only structural
  details stay in `px`: border widths, icon and fixed tap-target dimensions,
  `border-radius`, container `max-width`, media-query breakpoints, and
  shadow offsets.
- Keep it calm: flat surfaces, hairline rules, one accent per view, no
  gradients or bounce. Mono uppercase labels for field/meta/catalog text.
- Write copy in the archival voice — plain and unhurried, never marketing.

## Scaling — Utopia

Type and space are fluid, generated with [Utopia](https://utopia.fyi). When
you need to add, regenerate, or reason about a `clamp()` step on the scale,
use the **utopia** skill (`.claude/skills/utopia/`) — it documents the
project's Utopia config and how to derive the tokens.
