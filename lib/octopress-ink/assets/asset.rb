module Octopress
  module Assets
    class Asset

      def initialize(plugin, type, file)
        @file = file
        @type = type
        @plugin = plugin
        @plugin_type = plugin.type
        @root = plugin.assets_path
        @dir = File.join(plugin.namespace, type)
        @exists = {}
      end

      def file
        @file
      end

      def path(site)
        unless @found_file
          files = []
          files << user_path(site)
          files << plugin_path unless @plugin_type == 'local_plugin'
          files = files.flatten.reject { |f| !exists? f }

          unless files.size
            raise IOError.new "Could not find #{File.basename(@file)} at #{file}"
          end
          @found_file = Pathname.new files[0]
        end
        @found_file
      end

      def file(file, site)
        @file = file
        path(site)
      end

      def destination
        File.join(@dir, @file)
      end

      def copy(site)
        site.static_files << StaticFile.new(path(site), destination)
      end

      def plugin_dir
        File.join @root, @type
      end

      def plugin_path
        File.join plugin_dir, @file
      end

      def user_dir(site)
        File.join site.source, Plugins.custom_dir(site), @dir
      end

      def local_plugin_path(site)
        File.join site.source, @dir, @file
      end

      def user_override_path(site)
        File.join user_dir(site), @file
      end

      def user_path(site)
        if @plugin_type == 'local_plugin'
          local_plugin_path(site)
        else
          user_override_path(site)
        end
      end

      def alt_syntax_file
        ext = File.extname(@file)
        alt_ext = ext == 'scss' ? 'sass' : 'scss'
        @file.sub(/\.#{ext}/, ".#{alt_ext}")
      end

      def exists?(file)
        @exists[file] ||= File.exists?(file)
        @exists[file]
      end
    end
  end
end