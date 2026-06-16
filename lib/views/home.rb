# frozen_string_literal: true

require "phlex"

module Domus
  module Views
    # The home page — the archive's front door. Capture actions live in the
    # header (and a thumb-reachable dock on small screens); the recent assets
    # run as a single-column list below. Calm Archive language throughout.
    class Home < Phlex::HTML
      ICONS_DIR = File.expand_path("../../public/icons", __dir__)

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
          end
          body do
            div(class: "page") do
              render_header
              render_main
              render_footer
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
          render_actions(class: "actions")
        end
      end

      # The capture entry points. Both lead to the capture flow, where the
      # camera and file pickers live.
      def render_actions(**attrs)
        div(**attrs) do
          a(href: "/capture", class: "browse") { plain "Upload a file" }
          a(href: "/capture", class: "add-btn") do
            icon("camera")
            plain "Take a photo"
          end
        end
      end

      def render_main
        main(class: "wrap") do
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

      def render_footer
        footer(class: "foot") do
          span(class: "fm") { plain "v1.0" }
        end
      end

      # On small screens the capture actions move to a thumb-reachable dock
      # fixed to the bottom of the viewport; it's hidden on wider screens.
      def render_dock
        render_actions(class: "dock")
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

      ICONS = Hash.new do |cache, name|
        cache[name] = File.read(File.join(ICONS_DIR, "#{name}.svg")).freeze
      end

      def icon(name)
        raw safe(ICONS[name])
      end
    end
  end
end
