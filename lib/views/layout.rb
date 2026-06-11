# frozen_string_literal: true

require "phlex"

module Domus
  module Views
    class Layout < Phlex::HTML
      def initialize(title: "Domus", &content)
        @title = title
        @content = content
      end

      def view_template
        doctype

        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { @title }
            link(rel: "preconnect", href: "https://fonts.googleapis.com")
            link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
            link(rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;550;600;650;700&family=JetBrains+Mono:wght@400;500&display=swap")
            link(rel: "stylesheet", href: "/app.css")
            script(defer: true, src: "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js")
          end

          body do
            yield
          end
        end
      end
    end
  end
end
