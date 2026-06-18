# rbs_inline: enabled
# frozen_string_literal: true

require "pathname"

module Domus
  module Views
    # Inlines the SVG files from public/icons so they inherit currentColor
    # and can be sized and recoloured with CSS. Mixed into the Phlex views
    # that draw icons.
    module Icons
      ICONS_DIR = (Pathname(__dir__.to_s) / "../../public/icons").expand_path

      ICONS = Hash.new do |cache, name|
        cache[name] = (ICONS_DIR / "#{name}.svg").read.freeze
      end

      # : (String name) -> void
      def icon(name)
        raw safe(ICONS[name])
      end
    end
  end
end
