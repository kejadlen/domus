# frozen_string_literal: true

require "phlex"
require_relative "icons"
require_relative "capture_form"

module Domus
  module Views
    # The home page — the archive's front door. Capture actions live in the
    # header (and a thumb-reachable dock on small screens) and open the
    # picker in place: the whole page is one captureApp() Alpine component,
    # so choosing a file swaps the recent-asset list for the save form.
    class Home < Phlex::HTML
      include Icons

      def initialize(assets:, total:)
        @assets = assets
        @total = total
      end

      def view_template
        doctype
        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { "Domus" }
            link(rel: "stylesheet", href: "/app.css")
            script(defer: true, src: "/capture.js")
            script(defer: true, src: "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js")
          end
          body do
            div(class: "page", "x-data": "captureApp()") do
              render_header
              render_main
              render_capture
              render_dock
            end
          end
        end
      end

      private

      def render_header
        header(class: "topbar") do
          a(href: "/", class: "logo") do
            span(class: "logo-mark")
            plain "domus"
          end
        end
      end

      # A single split button: the primary action opens the picker
      # captureApp() chooses for the viewport (upload on desktop, camera on
      # mobile), and the caret opens a drop-up menu with the alternate.
      # Both labels are rendered and toggled by media query.
      def render_capture_control
        div(class: "capture", "@click.outside": "menuOpen = false") do
          div(class: "split") do
            button(
              type: "button",
              class: "add-btn split-main",
              "@click": "capturePrimary()"
            ) do
              span(class: "when-wide") { icon("folder"); plain "Upload a file" }
              span(class: "when-narrow") { icon("camera"); plain "Take a photo" }
            end
            button(
              type: "button",
              class: "add-btn split-toggle",
              "aria-label": "More capture options",
              ":aria-expanded": "menuOpen",
              ":class": "{ 'is-open': menuOpen }",
              "@click": "menuOpen = !menuOpen"
            ) { icon("chevron") }
          end

          div(
            class: "menu",
            role: "menu",
            "x-show": "menuOpen",
            "x-cloak": true,
            "x-transition.opacity.duration.120ms": true,
            "@keydown.escape.window": "menuOpen = false"
          ) do
            button(
              type: "button",
              class: "menu-item",
              role: "menuitem",
              "@click": "captureAlternate()"
            ) do
              span(class: "when-wide") { icon("camera"); plain "Take a photo" }
              span(class: "when-narrow") { icon("folder"); plain "Upload a file" }
            end
          end
        end
      end

      def render_main
        main(class: "wrap", "x-show": "state === 'capture'") do
          section do
            div(class: "sec-h") do
              h3 { plain "Recent assets" }
              span(class: "sub") { plain "#{@total} tracked" } if @total.positive?
            end
            if @assets.empty?
              render_empty
            else
              render_archive
            end
          end
        end
      end

      def render_archive
        div(class: "archive") do
          @assets.each do |asset|
            div(class: "entry") do
              span(class: "chip") { icon("box") }
              div(class: "body") do
                div(class: "nm") { plain asset[:name] }
              end
              span(class: "time") { plain relative_time(asset[:created_at]) }
            end
          end
        end
      end

      def render_empty
        div(class: "archive empty") do
          p(class: "empty-line") { plain "Nothing tracked yet." }
        end
      end

      # The capture save step, shown once a photo or file has been chosen.
      def render_capture
        div(class: "content", "x-show": "state === 'saved'", "x-cloak": true) do
          div(class: "card") do
            render CaptureForm.new
          end
        end
      end

      # The capture front door: a dock fixed to the bottom of the viewport on
      # every screen, so the primary action stays reachable and out of the
      # header.
      def render_dock
        div(class: "dock", "x-show": "state === 'capture'") do
          render_capture_control
        end
      end

      # Compact, archival relative time — "now", "5m", "3h", "2d", "1w", "4mo".
      def relative_time(at)
        return "" unless at

        seconds = (Time.now - at).to_i
        return "now" if seconds < 60

        minutes = seconds / 60
        return "#{minutes}m" if minutes < 60

        hours = minutes / 60
        return "#{hours}h" if hours < 24

        days = hours / 24
        return "#{days}d" if days < 7

        weeks = days / 7
        return "#{weeks}w" if days < 30

        months = days / 30
        return "#{months}mo" if months < 12

        "#{days / 365}y"
      end
    end
  end
end
