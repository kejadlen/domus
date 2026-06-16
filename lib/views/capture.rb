# frozen_string_literal: true

require_relative "layout"
require_relative "icons"
require_relative "capture_form"

module Domus
  module Views
    class Capture < Phlex::HTML
      include Icons

      def view_template
        doctype
        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { "Domus - Add image" }
            link(rel: "stylesheet", href: "/app.css")
            script(defer: true, src: "/capture.js")
            script(defer: true, src: "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js")
          end
          body do
            render_page
          end
        end
      end

      private

      def render_page
        div(class: "page") do
          render_header
          render_main
        end
      end

      def render_header
        header(class: "topbar") do
          a(href: "/", class: "logo") do
            span(class: "logo-mark")
            plain "domus"
          end
        end
      end

      def render_main
        main(class: "content") do
          div(
            class: "card",
            "x-data": "captureApp()",
            "@dragover.prevent": "dragging = true",
            "@dragleave.prevent": "dragging = false",
            "@drop.prevent": "onDrop($event)",
            ":data-drag": "dragging ? 'over' : null"
          ) do
            div("x-show": "state === 'capture'", class: "card-body") do
              h2(class: "card-title") { plain "Add an image" }
              p(class: "card-lead") { plain "Take a photo or pick an image to keep." }

              div(class: "btn-stack") do
                button(
                  type: "button",
                  class: "btn btn-primary",
                  "@click": "$refs.cameraInput.click()"
                ) do
                  icon("camera")
                  plain "Take a photo"
                end

                button(
                  type: "button",
                  class: "btn",
                  "@click": "$refs.fileInput.click()"
                ) do
                  icon("folder")
                  plain "Browse files"
                end
              end

              p(class: "drop-hint") { plain "or drop a file onto this card" }
            end

            render CaptureForm.new
          end
        end
      end
    end
  end
end
