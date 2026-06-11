# frozen_string_literal: true

require "phlex"

module Domus
  module Views
    class Layout < Phlex::HTML
      UTOPIA_CSS = <<~CSS
        /* Utopia fluid type scale - min 320px/1rem, max 1280px/1.25rem, ratio 1.25 */
        :root {
          --step--2: clamp(0.64rem, calc(0.62rem + 0.11vw), 0.72rem);
          --step--1: clamp(0.80rem, calc(0.76rem + 0.20vw), 0.94rem);
          --step-0:  clamp(1.00rem, calc(0.93rem + 0.33vw), 1.25rem);
          --step-1:  clamp(1.25rem, calc(1.14rem + 0.54vw), 1.56rem);
          --step-2:  clamp(1.56rem, calc(1.40rem + 0.82vw), 1.95rem);
          --step-3:  clamp(1.95rem, calc(1.72rem + 1.18vw), 2.44rem);

          /* Utopia fluid space scale */
          --space-3xs: clamp(0.25rem, calc(0.23rem + 0.11vw), 0.31rem);
          --space-2xs: clamp(0.50rem, calc(0.46rem + 0.22vw), 0.63rem);
          --space-xs:  clamp(0.75rem, calc(0.70rem + 0.27vw), 0.94rem);
          --space-s:   clamp(1.00rem, calc(0.93rem + 0.33vw), 1.25rem);
          --space-m:   clamp(1.50rem, calc(1.40rem + 0.54vw), 1.88rem);
          --space-l:   clamp(2.00rem, calc(1.85rem + 0.76vw), 2.50rem);
          --space-xl:  clamp(3.00rem, calc(2.78rem + 1.09vw), 3.75rem);
          --space-2xl: clamp(4.00rem, calc(3.70rem + 1.52vw), 5.00rem);
          --space-3xl: clamp(6.00rem, calc(5.56rem + 2.17vw), 7.50rem);

          /* Design tokens */
          --bg:         oklch(0.985 0.002 255);
          --surface:    #ffffff;
          --ink:        oklch(0.24 0.012 262);
          --ink-2:      oklch(0.50 0.010 262);
          --ink-3:      oklch(0.68 0.008 262);
          --line:       oklch(0.905 0.004 262);
          --line-2:     oklch(0.82 0.006 262);
          --fill:       oklch(0.967 0.003 262);
          --fill-2:     oklch(0.945 0.004 262);
          --accent:     oklch(0.50 0.17 290);
          --accent-ink: oklch(0.42 0.17 290);
          --accent-soft:oklch(0.96 0.03 290);
          --radius:     10px;
          --font-ui:    "Hanken Grotesk", system-ui, -apple-system, sans-serif;
          --font-mono:  "JetBrains Mono", ui-monospace, "SF Mono", monospace;
        }

        *, *::before, *::after { box-sizing: border-box; }

        html, body {
          margin: 0; padding: 0;
          background: var(--bg);
          font-family: var(--font-ui);
          color: var(--ink);
          -webkit-font-smoothing: antialiased;
        }

        .sr-only {
          position: absolute; width: 1px; height: 1px;
          padding: 0; margin: -1px; overflow: hidden;
          clip: rect(0,0,0,0); white-space: nowrap; border: 0;
        }
      CSS

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
            style { raw safe(UTOPIA_CSS) }
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
