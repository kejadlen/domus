# frozen_string_literal: true

require "phlex"

module Views
end

class Views::Layout < Phlex::HTML
  def initialize(title: "Domus", &content)
    @title = title
    @content = content
  end

  def view_template
    doctype

    html(lang: "en") do
      head do
        title { @title }
        script defer: true, src: "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"
      end

      body do
        yield
      end
    end
  end
end
