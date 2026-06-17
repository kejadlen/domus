---
name: phlex
description: "Use this skill when writing or editing Domus's HTML views — the Phlex components in lib/views/ (layout.rb, capture.rb). Triggers: adding a view or partial, rendering markup from a Roda route, emitting Alpine.js attributes, inlining SVG/raw HTML safely, or debugging why output is escaped or missing. Domus uses Phlex 2.x (a Ruby DSL where each HTML element is a method) from the kejadlen/phlex fork pinned in the Gemfile."
---

# Phlex views

Domus renders HTML with [Phlex](https://www.phlex.fun) 2.4 — views are Ruby
objects and every HTML element is a method call. No templates, no ERB. Output
is escaped by default, which is the whole point: Phlex is built to make XSS
structurally hard.

> The Gemfile pins a **fork** (`github.com/kejadlen/phlex.git`) that only
> silences the method-redefinition warnings Phlex 2.4 emits under `-w`. The
> API is upstream Phlex 2.x — treat the official docs as authoritative.

## Phlex 2 vs 1 — don't trust v1 examples

Phlex 2 renamed core API. Most blog posts and LLM memory describe v1; the
renames below will silently misbehave if you copy v1 code:

| v1 | v2 | gotcha if you use the old name |
|---|---|---|
| `def template` | **`def view_template`** | `template` now emits a `<template>` element |
| `text "x"` | **`plain "x"`** | `text` is gone (it clashed with SVG `<text>`) |
| `Phlex::View` | **`Phlex::HTML`** / `Phlex::SVG` | `Phlex::View` was removed |

## Where views live

- **`lib/views/`** — one class per view (`Layout`, `Capture`).
- Each subclasses `Phlex::HTML` and defines **`#view_template`**.
- A Roda route renders a view by instantiating and calling it:
  `Views::Capture.new.call` (see `lib/web.rb`). `#call` returns the HTML
  string.

## Anatomy of a view

```ruby
require "phlex"

module Domus
  module Views
    class Capture < Phlex::HTML
      def view_template
        doctype                       # => <!DOCTYPE html>
        html(lang: "en") do
          head { title { "Domus" } }
          body { render_main }
        end
      end

      private

      def render_main
        main(class: "content") { h2 { plain "Add an image" } }
      end
    end
  end
end
```

- **`view_template`** is the entry point — emit the page here.
- Every tag is a method: `div`, `header`, `a`, `button`, `input`, `img`, …
- A block becomes the element's children; nest blocks to nest markup.
- Split a view into `private` helper methods (`render_header`, `render_main`)
  and call them plainly — that's the house style in `capture.rb`. (To render
  *another component*, use `render OtherView.new(...)`, not a method call.)

## Text and content

- **`plain "text"`** — escaped text content. Use it for every literal string
  inside an element: `h2 { plain "Add an image" }`. A bare string inside a
  block is *not* emitted — you must call `plain`.
- **`whitespace`** — emit a single space (to let inline elements wrap).
- **`comment { "…" }`** — an HTML comment.

## Attributes

Pass attributes as keyword/hash arguments. Two key behaviors to know:

- **Symbol keys** convert underscores to dashes: `data_id: 1` → `data-id="1"`.
  There's also a nested shorthand: `data: { controller: "x" }` →
  `data-controller="x"`.
- **String keys** are emitted verbatim — required for names with `@`, `:`, or
  `.`, and the safe choice for anything non-trivial.
- **Booleans**: `disabled: true` emits `disabled`; `disabled: false` omits it.
- All attribute **values are escaped** automatically.

```ruby
input(type: "file", name: "file", accept: "image/*")   # symbol keys, simple
a(href: "/", class: "logo") { plain "domus" }
```

### Alpine.js attributes

Domus drives interactivity with Alpine, so views carry `x-`, `@`, and `:`
attributes. These are not valid Ruby symbol names, so use **string keys**:

```ruby
div(
  "x-data": "captureApp()",
  "@dragover.prevent": "dragging = true",
  ":data-drag": "dragging ? 'over' : null"
) do
  button(type: "button", "@click": "$refs.fileInput.click()") { plain "Browse" }
end
```

## Raw HTML and the escape boundary

Phlex escapes `plain` text and all attribute values. To emit HTML *verbatim*
you must opt out — and Phlex makes you do it in two deliberate steps:

```ruby
raw(safe(trusted_html))
```

- **`safe(str)`** wraps the string in a `Phlex::SGML::SafeObject`, asserting
  you trust it. `raw` only accepts a safe object (or it raises), so you can't
  emit unescaped HTML by accident.
- Domus uses this to inline pre-read SVG icon files:

```ruby
ICONS = Hash.new { |cache, name| cache[name] = File.read("…/#{name}.svg").freeze }

def icon(name)
  raw safe(ICONS[name])   # trusted, on-disk SVG — never user input
end
```

**Never** pass user input through `raw safe` — that reopens the XSS hole Phlex
closes. Keep it to static assets and HTML you generated yourself.

## Layouts

`Layout` takes the page content as a block and wraps it in the `<html>`
shell. Yield the block inside `view_template`:

```ruby
class Layout < Phlex::HTML
  def initialize(title: "Domus", &content)
    @title = title
    @content = content
  end

  def view_template
    doctype
    html(lang: "en") do
      head { title { @title }; link(rel: "stylesheet", href: "/app.css") }
      body { yield }
    end
  end
end
```

Store constructor args in instance variables (`@title`) and read them in
`view_template` — Phlex 2 is explicit, nothing is auto-copied in.

## Styling

Views reference the Calm Archive design tokens via CSS classes in
`public/app.css` — never inline colors or sizes. See `AGENTS.md` and the
**utopia** skill for the `--step-*` / `--space-*` scales.

## Testing

Views are exercised end-to-end through Roda routes with `rack-test`; assert on
`last_response.body` (see `test/test_app.rb`). There's no separate view unit
test — render through the route.
