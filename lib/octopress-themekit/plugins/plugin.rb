
module ThemeKit
  class Plugin

    def initialize(name)
      @name = name
      @layouts     = []
      @embeds      = []
      @stylesheets = []
      @javascripts = []
      @images      = []
      @fonts       = []
      @files       = []
      add_assets
      add_layouts
      add_embeds
    end

    def name
      @name
    end

    def assets_path
      @assets_path
    end

    def add_stylesheet(file, media=nil)
      @stylesheets << Stylesheet.new(self, Plugins::STYLESHEETS_DIR, file, media)
    end

    def add_stylesheets(files, media=nil)
      files.each { |f| add_stylesheet(f, media) }
    end

    def add_javascript(file)
      @javascripts << Javascript.new(self, Plugins::JAVASCRIPTS_DIR, file)
    end

    def add_javascripts(files)
      files.each { |f| add_javascript(f) }
    end

    def add_layouts
      @layouts = Template.new(self, Plugins::LAYOUTS_DIR)
    end

    def add_embeds
      @embeds = Template.new(self, Plugins::EMBEDS_DIR)
    end

    def stylesheet_paths(site)
      get_paths(@stylesheets, site)
    end

    def stylesheets
      @stylesheets
    end

    def javascripts
      @javascripts
    end

    def javascript_paths(site)
      get_paths(@javascripts, site)
    end

    def stylesheet_tags
      get_tags(@stylesheets)
    end

    def javascript_tags
      get_tags(@javascripts)
    end

    def get_paths(files, site)
      files.dup.map { |f| f.path(site) }
    end

    def get_tags(files)
      files.dup.map { |f| f.tag }
    end

    def embed(file, site)
      @embeds.file(file, site)
    end

    def layout(file, site)
      @layouts.file(file, site)
    end
  end
end