# frozen_string_literal: true

require "phlex"
require_relative "layout"

module Domus
  module Views
    # The asset detail page — the catalog card for a single tracked thing.
    # First version: only the identifying title block (eyebrow + name) and the
    # free-text description. Tags, photos, the maintenance log, info and
    # documents are held for later.
    class Asset < Phlex::HTML
      def initialize(asset:)
        @asset = asset
      end

      def view_template
        render Layout.new(title: "#{@asset[:name]} — Domus") do
          main(class: "wrap") do
            header(class: "asset-head") do
              p(class: "eyebrow") { plain "Asset" }
              h1(class: "title") { plain @asset[:name] }
            end
            description
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
    end
  end
end
