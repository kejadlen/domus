# frozen_string_literal: true

require_relative "layout"

module Domus
  module Views
    class Capture < Phlex::HTML
      ICONS_DIR = File.expand_path("../../public/icons", __dir__)

      def view_template
        doctype
        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { "Domus - Add document" }
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
            input(
              type: "file",
              name: "file",
              accept: "image/*,application/pdf",
              capture: "environment",
              class: "sr-only",
              "x-ref": "cameraInput",
              "@change": "onFileInput($event)"
            )
            input(
              type: "file",
              name: "file",
              accept: "image/*,application/pdf",
              class: "sr-only",
              "x-ref": "fileInput",
              "@change": "onFileInput($event)"
            )

            div("x-show": "state === 'capture'", class: "card-body") do
              h2(class: "card-title") { plain "Add a document" }
              p(class: "card-lead") { plain "Take a photo or pick a file to keep." }

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

            form(
              "x-show": "state === 'saved'",
              method: "post",
              action: "/files",
              enctype: "multipart/form-data",
              "@submit.prevent": "false"
            ) do
              div(class: "preview-zone") do
                img(
                  "x-show": "preview",
                  ":src": "preview",
                  alt: "Captured document"
                )
                div(
                  class: "preview-placeholder",
                  "x-show": "!preview"
                ) do
                  icon("image")
                  plain "captured file"
                end
              end

              div(class: "save-form") do
                div(class: "btn-row") do
                  button(type: "submit", class: "btn btn-primary") do
                    icon("check")
                    plain "Save document"
                  end
                  button(
                    type: "button",
                    class: "btn btn-ghost",
                    "@click": "reset()"
                  ) { plain "Discard" }
                end
              end
            end
          end
        end
      end

      def icon(name)
        raw safe(File.read(File.join(ICONS_DIR, "#{name}.svg")))
      end
    end
  end
end
