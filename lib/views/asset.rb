# frozen_string_literal: true

require "phlex"
require_relative "layout"

module Domus
  module Views
    # The asset detail page — the catalog card for a single tracked thing.
    # First version: the identifying title block (eyebrow + name), the
    # free-text description, and the attached photos. Tags, the maintenance
    # log, info and documents are held for later.
    class Asset < Phlex::HTML
      def initialize(asset:, images: [])
        @asset = asset
        @images = images
      end

      def view_template
        render Layout.new(title: "#{@asset[:name]} — Domus") do
          main(class: "wrap") do
            header(class: "asset-head") do
              p(class: "eyebrow") { plain "Asset" }
              h1(class: "title") { plain @asset[:name] }
            end
            description
            photos
          end
        end
      end

      private

      # Free-text description, rendered as paragraphs split on blank lines.
      # Omitted entirely when the asset has none yet.
      def description
        text = @asset[:description].to_s.strip
        return if text.empty?

        div(class: "desc") do
          text.split(/\n{2,}/).each do |para|
            p { plain para.strip }
          end
        end
      end

      # The captionless photo grid. Each tile is an <img> served by the
      # GET /files/:id route. Omitted entirely when nothing is attached.
      def photos
        return if @images.empty?

        section(class: "asset-photos") do
          h2(class: "photos-h") { plain "Photos" }
          div(class: "photos") do
            @images.each do |file|
              div(class: "shot") do
                img(src: "/files/#{file[:id]}#{file[:extension]}", alt: "Photo of #{@asset[:name]}", loading: "lazy")
              end
            end
          end
        end
      end
    end
  end
end
