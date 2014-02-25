module Octopress
  module Ink
    class Page < Jekyll::Page

      # Override the destination for a page
      #
      # url - Path relative to destination directory.
      #       examples: 
      #         - '/' for the _site/index.html page
      #         - '/archive/' for the _site/archive/index.html page
      #
      def initialize(site, base, dir, name, config)
        @plugin_config = config
        super(site, base, dir, name)
      end

      def destination(dest)
        path = File.join(dest, self.url)
        path
      end

      # Allow pages to read url from plugin configuration
      #
      def url
        if @url
          @url
        else
          begin
            if path_config = self.data['url_config']
              config = @plugin_config
              path_config.split('.').each { |key| config = config[key] }
              @url = config if config.is_a? String
            end
          rescue; end

          if @url && @url =~ /\/$/
            if self.ext == '.xml'
              @url = File.join(@url, "index.xml")
            else
              @url = File.join(@url, "index.html")
            end
          end

          super
        end
      end
    end
  end
end

