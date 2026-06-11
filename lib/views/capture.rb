# frozen_string_literal: true

require_relative "layout"

module Domus
  module Views
    class Capture < Phlex::HTML
      STYLES = <<~CSS
        /* ---- page shell ---- */
        .page {
          min-height: 100dvh;
          display: flex;
          flex-direction: column;
        }

        /* ---- header ---- */
        .topbar {
          display: flex;
          align-items: center;
          padding: 0 var(--space-m);
          height: 58px;
          border-bottom: 1px solid var(--line);
          background: color-mix(in oklch, var(--surface) 70%, var(--bg));
          backdrop-filter: blur(4px);
          position: sticky;
          top: 0;
          z-index: 10;
        }

        .logo {
          font-size: var(--step-1);
          font-weight: 700;
          letter-spacing: -0.03em;
          display: flex;
          align-items: center;
          gap: var(--space-2xs);
          color: var(--ink);
          text-decoration: none;
        }

        .logo-mark {
          width: 22px; height: 22px;
          border: 1.5px solid var(--ink);
          border-radius: 6px;
          position: relative;
          flex: none;
        }
        .logo-mark::after {
          content: "";
          position: absolute;
          inset: 4px 4px auto 4px;
          height: 1.5px;
          background: var(--ink);
          box-shadow: 0 4px 0 var(--ink), 0 8px 0 var(--accent);
        }

        .logo-dot { color: var(--accent); }

        /* ---- main content ---- */
        .content {
          flex: 1;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: var(--space-xl) var(--space-m);
        }

        /* ---- capture card ---- */
        .card {
          background: var(--surface);
          border: 1px solid var(--line);
          border-radius: var(--radius);
          box-shadow: 0 18px 50px -20px rgba(20,22,30,0.28), 0 2px 8px -4px rgba(20,22,30,0.12);
          width: min(420px, 100%);
          overflow: hidden;
        }

        .card-body {
          padding: var(--space-l);
        }

        .card-title {
          font-size: var(--step-1);
          font-weight: 650;
          letter-spacing: -0.02em;
          line-height: 1.12;
          margin: 0 0 var(--space-3xs) 0;
        }

        .card-lead {
          font-size: var(--step--1);
          color: var(--ink-2);
          margin: 0 0 var(--space-m) 0;
          line-height: 1.45;
        }

        /* ---- buttons ---- */
        .btn-stack {
          display: flex;
          flex-direction: column;
          gap: var(--space-2xs);
        }

        .btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: var(--space-2xs);
          padding: var(--space-xs) var(--space-m);
          border: 1px solid var(--line-2);
          border-radius: calc(var(--radius) - 2px);
          background: var(--surface);
          font-family: var(--font-ui);
          font-size: var(--step-0);
          font-weight: 550;
          letter-spacing: -0.01em;
          color: var(--ink);
          cursor: pointer;
          white-space: nowrap;
          width: 100%;
          transition: background .12s ease, border-color .12s ease;
          text-align: center;
        }

        .btn:hover { background: var(--fill); }

        .btn-primary {
          background: var(--accent);
          border-color: var(--accent);
          color: #fff;
        }
        .btn-primary:hover { background: var(--accent-ink); }

        .btn-ghost {
          background: transparent;
          border-color: transparent;
          color: var(--ink-2);
        }
        .btn-ghost:hover { background: var(--fill); }

        .drop-hint {
          font-family: var(--font-mono);
          font-size: var(--step--2);
          color: var(--ink-3);
          text-align: center;
          margin-top: var(--space-s);
        }

        /* ---- saved state ---- */
        .preview-zone {
          height: 210px;
          border-bottom: 1px solid var(--line);
          background: var(--fill-2);
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
        }

        .preview-zone img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .preview-placeholder {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: var(--space-2xs);
          color: var(--ink-3);
          font-family: var(--font-mono);
          font-size: var(--step--2);
        }

        .save-form {
          padding: var(--space-m);
          display: flex;
          flex-direction: column;
          gap: var(--space-m);
        }

        .field {
          display: flex;
          flex-direction: column;
          gap: var(--space-3xs);
        }

        .field-label {
          font-family: var(--font-mono);
          font-size: var(--step--2);
          letter-spacing: 0.06em;
          text-transform: uppercase;
          color: var(--ink-2);
        }

        .field-input {
          border: 1px solid var(--line-2);
          border-radius: calc(var(--radius) - 3px);
          background: var(--surface);
          padding: var(--space-xs) var(--space-s);
          font-family: var(--font-ui);
          font-size: var(--step-0);
          color: var(--ink);
          width: 100%;
          transition: border-color .15s ease, box-shadow .15s ease;
          outline: none;
        }

        .field-input:focus {
          border-color: var(--accent);
          box-shadow: 0 0 0 3px var(--accent-soft);
        }

        .btn-row {
          display: flex;
          align-items: center;
          gap: var(--space-2xs);
        }

        .btn-row .btn-primary { flex: 1; }

        /* ---- svg icons ---- */
        .icon { flex: none; }

        /* ---- dropzone drag feedback ---- */
        .card[data-drag="over"] {
          border-color: var(--accent);
          box-shadow: 0 0 0 3px var(--accent-soft), 0 18px 50px -20px rgba(20,22,30,0.28);
        }

        @media (max-width: 480px) {
          .content {
            padding: var(--space-m) var(--space-s);
            align-items: flex-start;
            padding-top: var(--space-l);
          }
        }
      CSS

      ALPINE_JS = <<~JS
        function captureApp() {
          return {
            state: 'capture',
            preview: null,
            name: '',
            dragging: false,

            handleFile(file) {
              if (!file) return;
              this.preview = file.type.startsWith('image/') ? URL.createObjectURL(file) : null;
              this.name = file.name.replace(/\\.[^.]+$/, '').replace(/[-_]/g, ' ');
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
              this.name = '';
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
            style { raw safe(Layout::UTOPIA_CSS) }
            style { raw safe(STYLES) }
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
                div(class: "field") do
                  label(class: "field-label", for: "doc-name") { plain "name" }
                  input(
                    type: "text",
                    id: "doc-name",
                    name: "name",
                    class: "field-input",
                    "x-model": "name",
                    placeholder: "Document name",
                    required: true,
                    "x-effect": "if (state === 'saved') $nextTick(() => $el.focus())"
                  )
                end

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
