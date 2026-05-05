# frozen_string_literal: true

source "https://rubygems.org"

gem "roda"
gem "puma"
gem "rackup"
# Fork silences the method-redefinition warnings phlex 2.4 emits
# under -w when its element methods are first generated.
gem "phlex", git: "https://github.com/kejadlen/phlex.git"
gem "sequel"
gem "sqlite3"
gem "rake"

group :development, :test do
  gem "minitest"
  gem "rack-test"
end
