# rbs_inline: enabled

require "fileutils"
require "open-uri"
require "pathname"

module Domus
  # Development and test seed data. Populates a few sample assets so a fresh
  # checkout has something to look at, using real CC0 (public domain) cat
  # photos from Wikimedia Commons. Photos download once into an XDG cache and
  # are reused across runs, so dev and the test suite share both the seeder
  # and the cached images.
  module Seeds
    USER_AGENT = "domus-seed/1.0 (https://github.com/kejadlen/domus)"

    # CC0 cat photos keyed by a short name. CC0 needs no attribution, but the
    # Wikimedia Commons file pages document the license and provenance:
    #   https://creativecommons.org/publicdomain/zero/1.0/
    #   grass:  commons.wikimedia.org/wiki/File:Domestic_shorthair_cat_portrait_in_grass.jpg
    #   tabby:  commons.wikimedia.org/wiki/File:Tabby_cat_with_blue_eyes-3336579.jpg
    #   paw:    commons.wikimedia.org/wiki/File:Domestic_cat_paw.jpg
    #   kitten: commons.wikimedia.org/wiki/File:A_mother_cat_of_Meitei_domestic_cat_breed_(Meitei_house_cat_variety)_suckling_her_only_little_newborn_baby_kitten_05.jpg
    PHOTOS = {
      grass: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Domestic_shorthair_cat_portrait_in_grass.jpg/960px-Domestic_shorthair_cat_portrait_in_grass.jpg",
      tabby: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Tabby_cat_with_blue_eyes-3336579.jpg/960px-Tabby_cat_with_blue_eyes-3336579.jpg",
      paw: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Domestic_cat_paw.jpg/960px-Domestic_cat_paw.jpg",
      kitten: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/A_mother_cat_of_Meitei_domestic_cat_breed_%28Meitei_house_cat_variety%29_suckling_her_only_little_newborn_baby_kitten_05.jpg/960px-A_mother_cat_of_Meitei_domestic_cat_breed_%28Meitei_house_cat_variety%29_suckling_her_only_little_newborn_baby_kitten_05.jpg",
    } #: Hash[Symbol, String]

    # Sample household assets. The drill is intentionally photoless so the
    # asset page's add-photo affordance shows up in dev.
    ASSETS = [
      {
        name: "Bosch 800 dishwasher",
        description: "Stainless interior, third rack. Replaces the GE that flooded.",
        photos: %i[grass],
      },
      {
        name: "LG French-door refrigerator",
        description: "Counter-depth, craft-ice maker. Bought refurbished in 2023.",
        photos: %i[tabby kitten],
      },
      {
        name: "Weber Genesis grill",
        description: "Three-burner propane. Cover lives in the shed over winter.",
        photos: %i[paw],
      },
      {
        name: "Ryobi cordless drill",
        description: "18V ONE+. Two batteries, charger in the garage drawer.",
        photos: [],
      },
    ] #: Array[Hash[Symbol, untyped]]

    # Seeds the database when it's empty, returning true when it inserted data
    # and false when assets already exist. The empty check keeps repeated dev
    # runs and CI idempotent. Photos download (and cache) outside the
    # transaction so a slow network doesn't hold the write lock open.
    # : (App) -> bool
    def self.call(app)
      db = app.db
      return false unless db[:assets].empty?

      keys = ASSETS.flat_map { |spec| spec[:photos] }.uniq #: Array[Symbol]
      sources = keys.to_h { |key| [key, fetch(key)] } #: Hash[Symbol, Pathname]

      db.transaction do
        now = Time.now
        ASSETS.each do |spec|
          asset_id = db[:assets].insert(name: spec[:name], description: spec[:description], created_at: now)
          spec[:photos].each do |key|
            file_id = db[:files].insert(extension: ".jpg", created_at: now)
            dest = app.file_path(id: file_id, extension: ".jpg")
            FileUtils.mkdir_p(dest.dirname)
            FileUtils.cp(sources.fetch(key), dest)
            db[:asset_attachments].insert(asset_id:, file_id:, created_at: now)
          end
        end
      end
      true
    end

    # Returns the cached path to a seed photo, downloading it on first use.
    # : (Symbol) -> Pathname
    def self.fetch(key)
      path = cache_dir / "#{key}.jpg"
      return path if path.exist?

      cache_dir.mkpath
      data = URI.parse(PHOTOS.fetch(key)).open("User-Agent" => USER_AGENT, &:read) #: String
      path.binwrite(data)
      path
    end

    # The XDG cache directory for downloaded seed photos.
    # : () -> Pathname
    def self.cache_dir
      base = ENV["XDG_CACHE_HOME"]
      base = "#{Dir.home}/.cache" if base.nil? || base.empty?
      Pathname(base) / "domus" / "seeds"
    end
  end
end
