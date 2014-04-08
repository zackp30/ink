module Octopress
  module Ink
    module Plugins
      @plugins = []
      @user_plugins = []
      @site = nil

      def self.theme
        @theme
      end

      def self.each(&block)
        plugins.each(&block)
      end

      def self.size
        plugins.size
      end

      def self.plugin(slug)
        if slug == 'theme'
          @theme
        else
          found = plugins.reject { |p| p.slug != slug }
          if found.empty?
            raise IOError.new "No Theme or Plugin with the slug '#{slug}' was found."
          end
          found.first
        end
      end

      def self.plugins
        [@theme].concat(@plugins).concat(@user_plugins).compact
      end

      def self.register(site)
        unless @site
          @site = site
          plugins.each do |p| 
            p.register
          end
        end
      end

      def self.add_files
        add_assets(%w{images pages files fonts docs})
        plugin('octopress-asset-pipeline').register_assets
        AssetPipeline.add_stylesheets
        add_javascripts
      end

      def self.add_assets(assets)
        plugins.each do |p| 
          p.add_asset_files(assets)
        end
      end

      def self.site
        @site
      end

      def self.register_plugin(plugin, options=nil)
        new_plugin = plugin.new(options)

        case new_plugin.type
        when 'theme'
          @theme = new_plugin
        else
          if new_plugin.local
            @user_plugins << new_plugin
          else
            @plugins << new_plugin
          end
        end
      end

      def self.config
        if @config
          @config
        else
          @config            = {}
          @config['plugins'] = {}
          @config['theme']   = @theme.nil? ? {} : @theme.config

          plugins.each do |p| 
            unless p == @theme
              @config['plugins'][p.slug] = p.config
            end
          end

          @config
        end
      end

      # Docs pages for each plugin
      #
      # returns: Array of plugin doc pages
      #
      def self.doc_pages
        plugin_docs = {}
        plugins.clone.map do |p|
          if pages = p.doc_pages
            plugin_docs[p.slug] = {
              "name" => p.name,
              "pages" => pages
            }
          end
        end
        plugin_docs
      end

      def self.include(name, file)
        p = plugin(name)
        p.include(file)
      end

      def self.custom_dir
        site.config['plugins']
      end

      def self.combined_javascript_path
        print = ''

        if @js_fingerprint
          print = "-" + @js_fingerprint
        end

        File.join('javascripts', "all#{print}.js")
      end

      def self.write_combined_javascript
        js = combine_javascripts
        write_files(js, combined_javascript_path) unless js == ''
      end

      def self.combine_javascripts
        unless @combined_javascripts
          js = ''
          plugins.each do |plugin| 
            paths = plugin.javascript_paths
            @js_fingerprint = fingerprint(paths)
            paths.each do |file|
              js.concat Pathname.new(file).read
            end
          end
          @combined_javascripts = js
        end
        @combined_javascripts
      end

      def self.combined_javascript_tag
        unless combine_javascripts == ''
          "<script src='#{Filters.expand_url(combined_javascript_path)}'></script>"
        end
      end

      def self.javascript_tags
        if Ink.config['concat_js']
          combined_javascript_tag
        else
          js = []
          plugins.each do |plugin| 
            js.concat plugin.javascript_tags
          end
          js
        end
      end

      def self.write_files(source, dest)
        Plugins.site.static_files << StaticFileContent.new(source, dest)
      end

      def self.fingerprint(paths)
        paths = [paths] unless paths.is_a? Array
        Digest::MD5.hexdigest(paths.clone.map! { |path| "#{File.mtime(path).to_i}" }.join)
      end

      # Copy/Generate Javascripts
      #
      def self.add_javascripts

        if Ink.config['concat_js']
          write_combined_javascript
        else
          add_assets(['javascripts'])
        end

      end

    end
  end
end

