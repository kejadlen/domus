# frozen_string_literal: true

require_relative "layout"

module Domus
  module Views
    class Capture < Phlex::HTML
      ALPINE_JS = <<~JS
        function captureApp() {
          return {
            state: 'capture',
            preview: null,
            dragging: false,

            handleFile(file) {
              if (!file) return;
              this.preview = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
              this.state = 'saved';
            },

            onFileInput(e) {
              this.handleFile(e.target.files[0]);
            },

            onDrop(e) {
              this.dragging = false;
              const file = e.dataTransfer?.files[0];
              if (file) {
                this.$refs.fileInput.files = e.dataTransfer.files;
                this.handleFile(file);
              }
            },

            reset() {
              if (this.preview) URL.revokeObjectURL(this.preview);
              this.state = 'capture';
              this.preview = null;
              this.$refs.fileInput.value = '';
              this.$refs.cameraInput.value = '';
            }
          }
        }
      JS

      def view_template
        doctype
        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { "Domus - Add document" }
            link(rel: "preconnect", href: "https://fonts.googleapis.com")
            link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
            link(rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;500;550;600;650;700&family=JetBrains+Mono:wght@400;500&display=swap")
            link(rel: "stylesheet", href: "/app.css")
            script(defer: true, src: "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js")
          end
          body do
            script { raw safe(ALPINE_JS) }
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
            span(class: "logo-dot") { plain "." }
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
                  camera_icon
                  plain "Take a photo"
                end

                button(
                  type: "button",
                  class: "btn",
                  "@click": "$refs.fileInput.click()"
                ) do
                  folder_icon
                  plain "Browse files"
                end
              end

              p(class: "drop-hint") { plain "or drop a file onto this card" }
            end

            form(
              "x-show": "state === 'saved'",
              method: "post",
              action: "/documents",
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
                  image_icon
                  plain "captured file"
                end
              end

              div(class: "save-form") do
                div(class: "btn-row") do
                  button(type: "submit", class: "btn btn-primary") do
                    check_icon
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

      def camera_icon
        raw safe(<<~SVG)
          <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/>
            <circle cx="12" cy="13" r="3"/>
          </svg>
        SVG
      end

      def folder_icon
        raw safe(<<~SVG)
          <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
          </svg>
        SVG
      end

      def image_icon
        raw safe(<<~SVG)
          <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
            <circle cx="8.5" cy="8.5" r="1.5"/>
            <polyline points="21 15 16 10 5 21"/>
          </svg>
        SVG
      end

      def check_icon
        raw safe(<<~SVG)
          <svg class="icon" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
        SVG
      end
    end
  end
end
