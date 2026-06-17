---
name: roda
description: "Use this skill when working on Domus's HTTP layer — the Roda app in lib/web.rb and its wiring in config.ru. Triggers: adding or changing a route, handling params/uploads, returning redirects or error statuses, enabling a Roda plugin, injecting the App dependency via opts, or writing rack-test request specs. Domus uses Roda 3.x, a routing-tree web toolkit where requests are matched by walking a block."
---

# Roda routing

Domus serves HTTP with [Roda](https://roda.jeremyevans.net) 3.103. The whole
app is one class, `Domus::Web < Roda`, in `lib/web.rb`. Roda is a *routing
tree*: the `route` block runs fresh per request and the request object `r`
walks the path one segment at a time, executing the first branch that matches.

Roda's core is tiny — almost every feature is a **plugin** you opt into. When
you reach for behavior, check the
[plugin list](https://roda.jeremyevans.net/documentation.html) before
hand-rolling it.

## The routing tree

```ruby
class Web < Roda
  plugin :public
  plugin :all_verbs
  plugin :error_handler do |e|
    raise e unless e.is_a?(ClientError)
    response.status = e.status
    e.message
  end

  route do |r|
    r.public                       # serve a matching file from public/

    r.root do                      # GET "/"  (only the exact root)
      r.get { Views::Capture.new.call }
    end

    r.on "files" do                # path PREFIX "files" — keeps descending
      r.post do                    # POST "/files"
        save_file(r.params)
        r.redirect "/"
      end
    end
  end
end
```

### `r.on` vs `r.is` — the distinction that bites

- **`r.on(matcher)`** matches a path *prefix* and keeps walking the tree. Use
  it to branch: `r.on "files" do … end` handles `/files`, `/files/123`, etc.
- **`r.is(matcher)`** matches only when the path is *fully consumed* after the
  matcher. Use it for a terminal/leaf route.
- **`r.root`** is sugar for `GET /` exactly.
- **`r.get` / `r.post`** (and, via `:all_verbs`, `r.put`/`r.patch`/`r.delete`)
  match the HTTP verb. Inside `r.on`, pair them with the verb to pin a route.

Domus only branches on `r.on "files"` today; if you add `/files/:id` actions,
prefer `r.on "files" do … r.is Integer do |id| … end … end` so the bare
`/files` collection and the `/files/123` member don't collide.

### Matchers and captures

- **String** — `r.on "files"` matches that segment.
- **Class** — `r.is Integer do |id|` matches a numeric segment and yields it;
  `String` matches any non-empty segment.
- **Array** — `r.on %w[new edit]` matches either, yields the match.
- **Regexp** — yields capture groups as block args.

Captured segments arrive as block parameters: `r.is("user", Integer) { |id| }`.

### What a matched block returns

The return value of the matched block becomes the response body (a string).
That's why `r.get { Views::Capture.new.call }` works — the Phlex string is the
body. Default status is 200 with a body, 404 with none.

## Request and response

- **`r.params`** — merged GET/POST params (the upload `Hash` for a multipart
  file lives here as `params["file"]`).
- **`r.redirect "/"`** — 302 (pass a status for others); halts the route.
- **`response.status = 422`**, `response["Header"] = "…"` — set on the
  response object directly.
- **`r.halt`** — short-circuit with a full Rack response (needs the `:halt`
  plugin; not currently loaded).

## Error handling

Domus defines a `ClientError` carrying an HTTP status:

```ruby
class ClientError < StandardError
  attr_reader :status
  def initialize(message, status: 422) = (super(message); @status = status)
end
```

Route code raises it for bad input (`raise ClientError, "Choose a file…"`).
The **`:error_handler`** plugin wraps the whole route in a rescue: it renders a
`ClientError` with its status, and re-raises anything else (so real bugs still
surface as 500s). Prefer raising `ClientError` over poking `response.status`
in handlers — it keeps the status next to the reason.

## Plugins in use

- **`:public`** — serve static files from `public/` via `r.public` (GET only,
  guards against directory traversal).
- **`:all_verbs`** — adds `r.put`, `r.patch`, `r.delete`, … matchers.
- **`:error_handler`** — the rescue wrapper described above.

Worth knowing for later: `:render` (Tilt templates — Domus uses Phlex
instead), `:json`, `:head`, `:not_found`, `:sessions`, and **`:route_csrf`**
(request-specific CSRF tokens; reach for it before adding any browser-facing
state-changing form beyond the current trusted-header setup).

## Dependency injection via `opts`

The app object (DB + config) is injected through Roda's class-level `opts`
rather than a global. `config.ru` sets it; the route reads it:

```ruby
# config.ru
Domus::Web.opts[:app] = app

# lib/web.rb
def app = opts.fetch(:app)
def db  = app.db
```

Use `opts.fetch(:app)` (not `[]`) so missing wiring fails loudly. Tests set
the same key against an in-memory app. In production you can `Web.freeze` to
lock `opts` and catch accidental runtime mutation / thread-safety bugs.

## Bootstrapping

`config.ru` builds the `App`, runs pending Sequel migrations, wires
`opts[:app]`, then `run Domus::Web`. The dev server is `rake dev` (port 9292).

## Testing

Request specs use `rack-test` with `Domus::Web` as the app:

```ruby
class TestApp < Minitest::Test
  include Rack::Test::Methods
  def app = Domus::Web

  def test_upload
    post "/files", "file" => upload("photo.png", "image/png", "bytes")
    assert_equal 302, last_response.status
  end
end
```

Assert on `last_response.status` and `.body`. See `test/test_app.rb` for the
upload happy-path and the `422` rejection cases.
