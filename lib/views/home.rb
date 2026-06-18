# rbs_inline: enabled

require "phlex"
require_relative "layout"
require_relative "icons"
require_relative "capture_form"
require_relative "../relative_time"

module Domus
  module Views
    # The home page — the archive's front door. Capture actions live in a
    # thumb-reachable dock and open the picker in place: the whole page is one
    # captureApp() Alpine component, so choosing a file swaps the recent-asset
    # list for the save form.
    class Home < Phlex::HTML
      include Icons

      # : (assets: Array[Hash[Symbol, untyped]], total: Integer) -> void
      def initialize(assets:, total:)
        @assets = assets
        @total = total
      end

      def view_template
        render Layout.new(scripts: ["/capture.js"]) do
          div(class: "page", "x-data": "captureApp()") do
            topbar
            recent_assets
            save_panel
            dock
          end
        end
      end

      private

      def topbar
        header(class: "topbar") do
          a(href: "/", class: "logo") do
            span(class: "logo-mark") { icon("logo") }
            plain "domus"
          end
        end
      end

      # A single split button: the primary action opens the picker
      # captureApp() chooses for the viewport (upload on desktop, camera on
      # mobile), and the caret opens a drop-up menu with the alternate.
      # Both labels are rendered and toggled by media query.
      def capture_control
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

      def recent_assets
        main(class: "wrap", "x-show": "state === 'capture'") do
          section do
            div(class: "sec-h") do
              h3 { plain "Recent assets" }
              span(class: "sub") { plain "#{@total} tracked" } if @total.positive?
            end
            if @assets.empty?
              empty_state
            else
              archive
            end
          end
        end
      end

      def archive
        div(class: "archive") do
          @assets.each do |asset|
            div(class: "entry") do
              span(class: "chip") { icon("box") }
              div(class: "body") do
                div(class: "nm") { plain asset[:name] }
              end
              span(class: "time") { plain RelativeTime.format(asset[:created_at]) }
            end
          end
        end
      end

      def empty_state
        div(class: "archive empty") do
          p(class: "empty-line") { plain "Nothing tracked yet." }
        end
      end

      # The capture save step, shown once a photo or file has been chosen.
      def save_panel
        div(class: "content", "x-show": "state === 'saved'", "x-cloak": true) do
          div(class: "card") do
            render CaptureForm.new
          end
        end
      end

      # The capture front door: a dock fixed to the bottom of the viewport on
      # every screen, so the primary action stays reachable and out of the
      # header.
      def dock
        div(class: "dock", "x-show": "state === 'capture'") do
          capture_control
        end
      end
    end
  end
end
