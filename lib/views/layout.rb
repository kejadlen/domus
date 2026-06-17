# frozen_string_literal: true

require "phlex"

module Domus
  module Views
    class Layout < Phlex::HTML
      ALPINE = "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"

      # `scripts` are emitted (deferred) before Alpine so page scripts that
      # register Alpine components — e.g. /capture.js defining captureApp() —
      # run first. Order matters: deferred scripts execute in document order.
      def initialize(title: "Domus", scripts: [])
        @title = title
        @scripts = scripts
      end

      def view_template(&block)
        doctype

        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { @title }
            link(rel: "icon", type: "image/svg+xml", href: "/favicon.svg")
            link(rel: "stylesheet", href: "/app.css")
            @scripts.each { |src| script(defer: true, src:) }
            script(defer: true, src: ALPINE)
          end

          body(&block)
        end
      end
    end
  end
end
