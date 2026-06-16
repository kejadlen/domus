# frozen_string_literal: true

module Domus
  module Views
    # Inlines the SVG files from public/icons so they inherit currentColor
    # and can be sized and recoloured with CSS. Mixed into the Phlex views
    # that draw icons.
    module Icons
      ICONS_DIR = File.expand_path("../../public/icons", __dir__)

      ICONS = Hash.new do |cache, name|
        cache[name] = File.read(File.join(ICONS_DIR, "#{name}.svg")).freeze
      end

      def icon(name)
        raw safe(ICONS[name])
      end
    end
  end
end
