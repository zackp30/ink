module Octopress
  module Ink
    module AssetPipeline

      def self.compile_sass_file(path, options=nil)
        options ||= sass_options
        ::Sass.compile_file(path, options)
      end

      def self.compile_sass(contents, options)
        ::Sass.compile(contents, options)
      end

      def self.sass_options
        config = Plugins.site.config['sass']
        
        defaults = {
          'style'        => :compressed,
          'trace'        => false,
          'line_numbers' => false
        }

        options = defaults.deep_merge(config || {}).symbolize_keys
        options = options.each{ |k,v| options[k] = v.to_sym if v.is_a? String }
        options
      end

      def self.combined_stylesheet_tag
        tags = ''
        combine_stylesheets.keys.each do |media|
          tags.concat "<link href='#{Filters.expand_url(combined_stylesheet_path(media))}' media='#{media}' rel='stylesheet' type='text/css'>"
        end
        tags
      end

      def self.combine_stylesheets
        unless @combined_stylesheets
          css = {}
          paths = {}
          Plugins.plugins.each do |plugin|
            if plugin.type == 'theme'
              plugin_header = "/* Theme: #{plugin.name} */\n"
            else
              plugin_header = "/* Plugin: #{plugin.name} */\n"
            end
            stylesheets = plugin.stylesheets
            stylesheets.each do |file|
              css[file.media] ||= {}
              css[file.media][:contents] ||= ''
              css[file.media][:contents] << plugin_header
              css[file.media][:paths] ||= []
              
              # Add Sass files
              if file.respond_to? :compile
                css[file.media][:contents].concat file.compile
              else
                css[file.media][:contents].concat file.path.read.strip
              end
              css[file.media][:paths] << file.path
              plugin_header = ''
            end
          end

          css.keys.each do |media|
            css[media][:fingerprint] = fingerprint(css[media][:paths])
          end
          @combined_stylesheets = css
        end
        @combined_stylesheets
      end

      def self.write_combined_stylesheet
        css = combine_stylesheets
        css.keys.each do |media|
          contents = compile_sass(css[media][:contents], sass_options)
          contents = AutoprefixerRails.process(contents)
          write_files(contents, combined_stylesheet_path(media)) 
        end
      end

      def self.write_files(source, dest)
        Plugins.site.static_files << StaticFileContent.new(source, dest)
      end

      def self.combined_stylesheet_path(media)
        File.join('stylesheets', "#{media}-#{@combined_stylesheets[media][:fingerprint]}.css")
      end

      def self.fingerprint(paths)
        paths = [paths] unless paths.is_a? Array
        Digest::MD5.hexdigest(paths.clone.map! { |path| "#{File.mtime(path).to_i}" }.join)
      end
      
    end
  end
end
