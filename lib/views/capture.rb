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

            form(
              "x-show": "state === 'saved'",
              method: "post",
              action: "/files",
              enctype: "multipart/form-data",
              "@submit": "onSubmit()"
            ) do
              input(
                type: "file",
                name: "file",
                accept: "image/*",
                capture: "environment",
                class: "sr-only",
                "x-ref": "cameraInput",
                "@change": "onCameraInput($event)"
              )
              input(
                type: "file",
                name: "file",
                accept: "image/*",
                class: "sr-only",
                "x-ref": "fileInput",
                "@change": "onFileInput($event)"
              )
              div(class: "preview-zone") do
                img(
                  "x-show": "preview",
                  ":src": "preview",
                  alt: "Captured image"
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
                div(class: "asset-inputs") do
                  p(class: "asset-inputs-label") { plain "Create assets (optional)" }
                  template("x-for": "(_, i) in assetNames", ":key": "i") do
                    div(class: "asset-input-row") do
                      input(
                        type: "text",
                        name: "asset_names[]",
                        placeholder: "Asset name",
                        "@input": "assetNames[i] = $event.target.value"
                      )
                      button(
                        type: "button",
                        class: "btn-remove-asset",
                        "@click": "assetNames.splice(i, 1)"
                      ) { plain "×" }
                    end
                  end
                  button(
                    type: "button",
                    class: "asset-add-btn",
                    "@click": "assetNames.push('')"
                  ) { plain "+ Add asset" }
                end

                div(class: "btn-row") do
                  button(type: "submit", class: "btn btn-primary") do
                    icon("check")
                    plain "Save image"
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

      ICONS = Hash.new do |cache, name|
        cache[name] = File.read(File.join(ICONS_DIR, "#{name}.svg")).freeze
      end

      def icon(name)
        raw safe(ICONS[name])
      end
    end
  end
end
