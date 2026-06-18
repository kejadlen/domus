# rbs_inline: enabled
# frozen_string_literal: true

require "phlex"
require_relative "icons"

module Domus
  module Views
    # The save step of a capture: the hidden camera/file inputs plus the
    # preview and asset-naming form. Driven by the captureApp() Alpine data,
    # and shared by both the capture page and the home page so the capture
    # actions can open the picker in place.
    class CaptureForm < Phlex::HTML
      include Icons

      def view_template
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
            img("x-show": "preview", ":src": "preview", alt: "Captured image")
            div(class: "preview-placeholder", "x-show": "!preview") do
              icon("image")
              plain "captured file"
            end
          end

          div(class: "save-form") do
            div(class: "asset-inputs") do
              p(class: "asset-inputs-label") { plain "Assets" }
              template("x-for": "(_, i) in assetNames", ":key": "i") do
                div(class: "asset-input-row") do
                  input(
                    type: "text",
                    name: "asset_names[]",
                    placeholder: "Asset name",
                    "x-model": "assetNames[i]",
                    "@keydown.enter.prevent": "addAsset()"
                  )
                  button(
                    type: "button",
                    class: "btn-remove-asset",
                    "@click": "removeAsset(i)"
                  ) { icon("trash") }
                end
              end
              button(
                type: "button",
                class: "asset-add-btn",
                "@click": "addAsset()"
              ) { plain "Add another" }
            end

            div(class: "btn-row") do
              button(type: "submit", class: "btn btn-primary") do
                icon("check")
                plain "Save image"
              end
              button(
                type: "button",
                class: "btn",
                "@click": "reset()"
              ) { plain "Discard" }
            end
          end
        end
      end
    end
  end
end
