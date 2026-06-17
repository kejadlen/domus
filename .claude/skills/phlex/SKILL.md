---
name: phlex
description: "Use this skill when writing or editing Domus's HTML views — the Phlex components in lib/views/ (layout.rb, capture.rb). Triggers: adding a view or partial, rendering markup from a Roda route, emitting Alpine.js attributes, inlining SVG/raw HTML safely, or debugging why output is escaped or missing. Domus uses Phlex 2.x (a Ruby DSL where each HTML element is a method) from the kejadlen/phlex fork pinned in the Gemfile."
---

# Phlex views

Domus renders HTML with [Phlex](https://www.phlex.fun) 2.4 — views are Ruby
objects, and every HTML element is a method call. No templates, no ERB.

> The Gemfile pins a **fork** (`github.com/kejadlen/phlex.git`) that silences
> the method-redefinition warnings Phlex 2.4 emits under `-w`. Treat the API
> as upstream Phlex 2.x.

## Where views live

- **`lib/views/`** — one class per view (`Layout`, `Capture`).
- Each subclasses `Phlex::HTML` and defines `#view_template`.
- A Roda route renders a view by instantiating it and calling `#call`:
  `Views::Capture.new.call` (see `lib/web.rb`).

## Anatomy of a view

```ruby
require "phlex"

module Domus
  module Views
    class Capture < Phlex::HTML
      def view_template
        doctype
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
- Each tag is a method: `div`, `header`, `a`, `button`, `input`, `img`, …
- A block becomes the element's children; nest blocks to nest markup.
- Break a view into `private` helper methods (`render_header`,
  `render_main`) — that's the house style in `capture.rb`.

## Attributes

Pass attributes as keyword/hash arguments. Use string keys for anything
that isn't a plain identifier (dashes, `@`, `:`, `x-`):

```ruby
div(class: "card", id: "main")                 # symbol keys for simple names
input(type: "file", name: "file", accept: "image/*")
a(href: "/", class: "logo") { plain "domus" }
```

### Alpine.js attributes

Domus drives interactivity with Alpine, so views are full of `x-`, `@`, and
`:` attributes. These must be **string keys**:

```ruby
div(
  "x-data": "captureApp()",
  "@dragover.prevent": "dragging = true",
  ":data-drag": "dragging ? 'over' : null"
) do
  button(type: "button", "@click": "$refs.fileInput.click()") { plain "Browse" }
end
```

## Text and raw HTML

- **`plain "text"`** — emit escaped text content. Use it for any literal
  string inside an element (`h2 { plain "Add an image" }`).
- **`raw safe(html)`** — emit a pre-trusted HTML string *without* escaping.
  Only for strings you control. Domus inlines SVG icons this way:

```ruby
ICONS = Hash.new { |cache, name| cache[name] = File.read("…/#{name}.svg").freeze }

def icon(name)
  raw safe(ICONS[name])   # safe() marks it trusted; raw emits it verbatim
end
```

Never pass user input to `raw safe` — that's an XSS hole. Everything else
(`plain`, attribute values) is escaped by Phlex automatically.

## Layouts

`Layout` takes the page content as a block and wraps it in the `<html>`
shell. Compose by yielding inside `view_template`:

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

## Styling

Views reference the Calm Archive design tokens via CSS classes in
`public/app.css` — never inline colors or sizes. See `AGENTS.md` and the
**utopia** skill for the `--step-*` / `--space-*` scales.

## Testing

Views are exercised end-to-end through Roda routes with `rack-test`; assert
on `last_response.body` (see `test/test_app.rb`). There's no separate view
unit test — render through the route.
