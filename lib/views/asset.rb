# frozen_string_literal: true

require "phlex"
require_relative "layout"
require_relative "icons"

module Domus
  module Views
    # The asset detail page — the catalog card for a single tracked thing,
    # following the "Domus Asset" comp (Direction A, simplified). A breadcrumb
    # and the title/tags head, then a two-column catalog: description and the
    # maintenance log on the left; photos, info and documents on the right.
    #
    # Only the title, description and attached photos are wired to data yet.
    # The tags, maintenance log, info and documents are held space — rendered
    # as placeholders matching the comp until those features land.
    class Asset < Phlex::HTML
      include Icons

      def initialize(asset:, images: [])
        @asset = asset
        @images = images
      end

      def view_template
        render Layout.new(title: "#{@asset[:name]} — Domus") do
          main(class: "asset") do
            topbar
            head
            div(class: "asset-grid") do
              div(class: "col-main") do
                description
                maintenance_log
              end
              div(class: "col-side") do
                photos
                info
                documents
              end
            end
          end
        end
      end

      private

      def topbar
        div(class: "asset-top") do
          div(class: "crumbs") do
            a(href: "/") { icon("chev-left"); plain "Assets" }
          end
          div(class: "asset-actions") do
            button(type: "button", class: "iconbtn", "aria-label": "Asset actions") { icon("dots") }
          end
        end
      end

      def head
        header(class: "asset-head") do
          p(class: "eyebrow") { plain "Asset" }
          h1(class: "title") { plain @asset[:name] }
          tags
        end
      end

      # Placeholder tags until tagging is wired.
      def tags
        div(class: "tags") do
          span(class: "tag loc") { icon("pin"); plain "kitchen" }
          span(class: "tag") { plain "appliance" }
          span(class: "tag add") { plain "+ tag" }
        end
      end

      # Free-text description, rendered as paragraphs split on blank lines.
      # Omitted entirely when the asset has none yet.
      def description
        text = @asset[:description].to_s.strip
        return if text.empty?

        div(class: "desc") do
          text.split(/\n{2,}/).each { |para| p { plain para.strip } }
        end
      end

      # Held space: the date+text log. Shows only the add row until logging
      # is wired.
      def maintenance_log
        section(class: "panel") do
          div(class: "panel-h") do
            h2(class: "sec") { plain "Maintenance log" }
            span(class: "note mono") { plain "0 ENTRIES" }
          end
          div(class: "card log") do
            div(class: "logrow add") do
              span(class: "d") { plain "today" }
              div(class: "t") { plain "Log maintenance…" }
            end
          end
        end
      end

      # The captionless photo grid: each attached file plus an add affordance.
      def photos
        section(class: "panel") do
          div(class: "panel-h") { h3(class: "sub") { plain "Photos" } }
          div(class: "photos") do
            @images.each do |file|
              div(class: "shot") do
                img(src: "/files/#{file[:id]}#{file[:extension]}", alt: "Photo of #{@asset[:name]}", loading: "lazy")
              end
            end
            button(type: "button", class: "addphoto") { icon("camera"); plain "add" }
          end
        end
      end

      # Held space for purchase / model / serial details.
      def info
        section(class: "panel") do
          div(class: "panel-h") { h3(class: "sub") { plain "Info" } }
          div(class: "card empty") do
            div(class: "msg") { plain "Purchase, model, serial and more — add details when you have them." }
            button(type: "button", class: "ghostadd") { icon("plus"); plain "Add details" }
          end
        end
      end

      # Held space for attached documents.
      def documents
        section(class: "panel") do
          div(class: "panel-h") { h3(class: "sub") { plain "Documents" } }
          div(class: "card") do
            div(class: "doc addrow") do
              span(class: "dico") { icon("plus") }
              span(class: "nm") { plain "Attach a document…" }
            end
          end
        end
      end
    end
  end
end
