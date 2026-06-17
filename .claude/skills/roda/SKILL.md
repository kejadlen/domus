---
name: roda
description: "Use this skill when working on Domus's HTTP layer — the Roda app in lib/web.rb and its wiring in config.ru. Triggers: adding or changing a route, handling params/uploads, returning redirects or error statuses, enabling a Roda plugin, injecting the App dependency via opts, or writing rack-test request specs. Domus uses Roda 3.x, a routing-tree web toolkit where requests are matched by walking a block."
---

# Roda routing

Domus serves HTTP with [Roda](https://roda.jeremyevans.net) 3.103. The whole
app is one class, `Domus::Web < Roda`, in `lib/web.rb`. Roda routes by
*walking a tree* — the `route` block matches segments of the path as it
descends, calling handlers when a branch matches.

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
    r.public                       # serve files from public/

    r.root do                      # GET "/"
      r.get { Views::Capture.new.call }
    end

    r.on "files" do                # path prefix "/files"
      r.post do                    # POST "/files"
        save_file(r.params)
        r.redirect "/"
      end
    end
  end
end
```

Key matchers (the request is the `r` yielded to `route`):

- **`r.root`** — matches `GET /` (combined with `r.get` inside).
- **`r.on "files"`** — matches the path *prefix* `files` and descends; nest
  verb matchers inside.
- **`r.get` / `r.post`** — match the HTTP verb (and optionally remaining path).
- **`r.params`** — merged GET/POST params.
- **`r.redirect "/"`** — 302 redirect (halts the route).
- **`r.public`** — serve a static file from `public/` if one matches.

Return value of the matched block is the response body. A view renders with
`Views::Capture.new.call` (a Phlex string).

## Plugins in use

- **`:public`** — static files from `public/` via `r.public`.
- **`:all_verbs`** — adds `r.put`, `r.patch`, `r.delete`, etc.
- **`:error_handler`** — wraps the route in a rescue; see error handling below.

Add a plugin with `plugin :name` at class level. Check the
[plugin list](https://roda.jeremyevans.net/documentation.html) before
hand-rolling behavior — Roda ships most of what you'd want.

## Error handling

Domus defines a `ClientError` carrying an HTTP status:

```ruby
class ClientError < StandardError
  attr_reader :status
  def initialize(message, status: 422) = (super(message); @status = status)
end
```

Route code raises it for bad input (`raise ClientError, "Choose a file…"`),
and the `:error_handler` plugin renders it with the right status. Anything
that isn't a `ClientError` is re-raised. Prefer raising `ClientError` over
manually setting `response.status` in handlers.

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

Use `opts.fetch(:app)` (not `[]`) so a missing wiring fails loudly. Tests set
the same key against an in-memory app.

## Bootstrapping

`config.ru` builds the `App`, runs pending Sequel migrations, wires
`opts[:app]`, then `run Domus::Web`. The dev server is `rake dev`
(port 9292).

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
