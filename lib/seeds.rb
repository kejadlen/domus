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

    # A seed photo. +key+ names the cache file; +url+ is the source download.
    Photo = Data.define(
      :key, #: Symbol
      :url, #: String
    )

    # An asset to seed, with zero or more attached photos.
    Asset = Data.define(
      :name, #: String
      :description, #: String
      :photos, #: Array[Photo]
    )

    # CC0 cat photos. CC0 needs no attribution, but the Wikimedia Commons file
    # pages document the license and provenance:
    #   https://creativecommons.org/publicdomain/zero/1.0/
    #   commons.wikimedia.org/wiki/File:Domestic_shorthair_cat_portrait_in_grass.jpg
    #   commons.wikimedia.org/wiki/File:Tabby_cat_with_blue_eyes-3336579.jpg
    #   commons.wikimedia.org/wiki/File:Domestic_cat_paw.jpg
    #   commons.wikimedia.org/wiki/File:A_mother_cat_of_Meitei_domestic_cat_breed_(Meitei_house_cat_variety)_suckling_her_only_little_newborn_baby_kitten_05.jpg
    GRASS = Photo.new(:grass, "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Domestic_shorthair_cat_portrait_in_grass.jpg/960px-Domestic_shorthair_cat_portrait_in_grass.jpg")
    TABBY = Photo.new(:tabby, "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Tabby_cat_with_blue_eyes-3336579.jpg/960px-Tabby_cat_with_blue_eyes-3336579.jpg")
    PAW = Photo.new(:paw, "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/Domestic_cat_paw.jpg/960px-Domestic_cat_paw.jpg")
    KITTEN = Photo.new(:kitten, "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/A_mother_cat_of_Meitei_domestic_cat_breed_%28Meitei_house_cat_variety%29_suckling_her_only_little_newborn_baby_kitten_05.jpg/960px-A_mother_cat_of_Meitei_domestic_cat_breed_%28Meitei_house_cat_variety%29_suckling_her_only_little_newborn_baby_kitten_05.jpg")

    # Sample household assets. The drill is intentionally photoless so the
    # asset page's add-photo affordance shows up in dev.
    ASSETS = [
      Asset.new(
        name: "Bosch 800 dishwasher",
        description: "Stainless interior, third rack. Replaces the GE that flooded.",
        photos: [GRASS],
      ),
      Asset.new(
        name: "LG French-door refrigerator",
        description: "Counter-depth, craft-ice maker. Bought refurbished in 2023.",
        photos: [TABBY, KITTEN],
      ),
      Asset.new(
        name: "Weber Genesis grill",
        description: "Three-burner propane. Cover lives in the shed over winter.",
        photos: [PAW],
      ),
      Asset.new(
        name: "Ryobi cordless drill",
        description: "18V ONE+. Two batteries, charger in the garage drawer.",
        photos: [],
      ),
    ] #: Array[Asset]

    # Seeds the database when it's empty, returning true when it inserted data
    # and false when assets already exist. The empty check keeps repeated dev
    # runs and CI idempotent. Photos download (and cache) outside the
    # transaction so a slow network doesn't hold the write lock open.
    # : (App) -> bool
    def self.call(app)
      db = app.db
      return false unless db[:assets].empty?

      photos = ASSETS.flat_map(&:photos).uniq #: Array[Photo]
      sources = photos.to_h { |photo| [photo, fetch(photo)] } #: Hash[Photo, Pathname]

      db.transaction do
        now = Time.now
        ASSETS.each do |asset|
          asset_id = db[:assets].insert(name: asset.name, description: asset.description, created_at: now)
          asset.photos.each do |photo|
            file_id = db[:files].insert(extension: ".jpg", created_at: now)
            dest = app.file_path(id: file_id, extension: ".jpg")
            FileUtils.mkdir_p(dest.dirname)
            FileUtils.cp(sources.fetch(photo), dest)
            db[:asset_attachments].insert(asset_id:, file_id:, created_at: now)
          end
        end
      end
      true
    end

    # Returns the cached path to a seed photo, downloading it on first use.
    # : (Photo) -> Pathname
    def self.fetch(photo)
      path = cache_dir / "#{photo.key}.jpg"
      return path if path.exist?

      cache_dir.mkpath
      data = URI.parse(photo.url).open("User-Agent" => USER_AGENT, &:read) #: String
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
