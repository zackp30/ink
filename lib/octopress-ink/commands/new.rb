module Octopress
  module Ink
    module Commands
      class New
        def self.process_command(p)
          p.command(:new) do |c|
            c.syntax "new <PLUGIN_NAME> [options]"
            c.description "Create a new Octopress Ink plugin with Ruby gem scaffolding."
            c.option "theme", "--theme", "Create a new theme."
            c.option "path", "--path PATH", "Create a plugin at a specified path (defaults to current directory)."

            c.action do |args, options|
              if args.empty?
                raise "Please provide a plugin name, e.g. my_awesome_plugin."
              else
                @options = options
                @options['name'] = args[0]
                new_plugin
              end
            end
          end
        end

        def self.new_plugin
          path = @options['path'] ||= Dir.pwd
          gem_name = @options['name']
          path_to_gem = File.join(path, gem_name)

          if !Dir.exist?(path)
            raise "Directory not found: #{File.expand_path(path)}."
          end

          if !Dir["#{path_to_gem}/*"].empty?
            raise "Directory not empty: #{File.expand_path(path_to_gem)}."
          end

          FileUtils.cd path do
            create_gem(gem_name)

            settings = gem_settings(path_to_gem)
            settings[:type] = @options['theme'] ? 'theme' : 'plugin'

            add_dependency(settings)
            add_plugin(settings)
            add_asset_dirs(settings)
            add_demo_files(settings)
          end
        end

        # Create a new gem with Bundle's gem command
        #
        def self.create_gem(name)
          begin
            require 'bundler/cli'
            bundler = Bundler::CLI.new
          rescue LoadError
            raise "To use this feautre you'll need to install the bundler gem with `gem install bundler`."
          end

          bundler.gem(name)
        end

        # Add Octopress Ink dependency to Gemspec
        #
        def self.add_dependency(settings)
          pos = settings[:gemspec].rindex("end")
          settings[:gemspec] = insert_before(settings[:gemspec], pos, indent(dependencies(settings[:spec_var])))

          File.open(settings[:gemspec_path], 'w+') {|f| f.write(settings[:gemspec]) }
        end

        # Returns lines which need to be added as a dependency
        #
        # spec_var - variable used to assign gemspec attributes,
        # e.g. "spec" as in spec.name = "gem name"
        #
        def self.dependencies(settings)
          minor_version = VERSION.scan(/\d\.\d/)[0]
          d  = "#{settings[:spec_var]}.add_development_dependency \"octopress\"\n\n"
          d += "#{settings[:spec_var]}.add_runtime_dependency \"octopress-ink\", \"~> #{minor_version}\", \">= #{VERSION}\"\n"
        end

        # Add Octopress Ink plugin to core module file
        #
        def self.add_plugin(settings)
          # Grab the module directory from the version.rb require.
          # If a gem is created with dashes e.g. "some-gem", Bundler puts the module file at lib/some/gem.rb
          file = File.join(settings[:path], settings[:module_path])
          mod = File.open(file).read
          mod = add_simple_plugin mod

          File.open(file, 'w+') {|f| f.write(mod) }
        end

        def self.add_asset_dirs(settings)
          dirs = %w{docs images fonts pages files layouts includes stylesheets javascripts}.map do |asset|
            File.join(settings[:path], 'assets', asset)
          end
          create_empty_dirs dirs
        end

        # New plugin uses a simple configuration hash
        #
        def self.add_simple_plugin(settings, mod)
          mod  = "#{settings[:require_version]}\n"
          mod += "require 'octopress-ink'\n"
          mod += "\nOctopress::Ink.add_plugin({\n#{indent(plugin_config)}\n})"
        end


        # Return an Ink Plugin configuration hash desinged for this gem
        #
        def self.plugin_config(settings)
          depth = settings[:module_path].count('/')
          assets_path = ("../" * depth) + 'assets'

          config = <<-HERE
name:          "#{settings[:module_name]}",
slug:          "#{settings[:name]}",
assets_path:   File.expand_path(File.join(File.dirname(__FILE__), "#{assets_path}")),
type:          "#{settings[:type]}",
version:       #{settings[:version]},
description:   "",
website:       ""
          HERE
          config.rstrip
        end

        # Creates a blank Jekyll site for testing out a new plugin
        #
        def self.add_demo_files(settings)
          demo_dir = File.join(settings[:path], 'demo')

          dirs = %w{_layouts _posts}.map! do |d|
            File.join(demo_dir, d)
          end

          create_empty_dirs dirs

          index = File.join(demo_dir, 'index.html')
          action = File.exist?(index) ? "exists".rjust(12).blue.bold : "create".rjust(12).green.bold
          FileUtils.touch index
          puts "#{action}  #{index}"

          gemfile = <<-HERE
source 'https://rubygems.org'

group :octopress do
  gem 'octopress'
  gem '#{settings[:name]}', path: '../'
end
          HERE

          gemfile_path = File.join(demo_dir, 'Gemfile')
          action = File.exist?(gemfile_path) ? "written".rjust(12).blue.bold : "create".rjust(12).green.bold

          File.open(gemfile_path, 'w+') do |f| 
            f.write(gemfile)
          end
          puts "#{action}  #{gemfile_path}"
        end

        def self.create_empty_dirs(dirs)
          dirs.each do |d|
            dir = File.join(d)
            action = Dir.exist?(dir) ? "exists".rjust(12).blue.bold : "create".rjust(12).green.bold
            FileUtils.mkdir_p dir
            puts "#{action}  #{dir}/"
          end
        end

        # Read gem settings from the gemspec
        #
        def self.gem_settings(gem_path)
          gemspec_path = Dir.glob(File.join(gem_path, "/*.gemspec")).first

          if gemspec_path.nil?
            raise "No gemspec file found at #{gem_path}/. To create a new plugin use `octopress ink new <PLUGIN_NAME>`"
          end

          gemspec = File.open(gemspec_path).read
          require_version = gemspec.scan(/require.+version.+$/)[0]
          module_subpath = require_version.scan(/['"](.+)\/version/).flatten[0]
          version = gemspec.scan(/version.+=\s+(.+)$/).flatten[0]
          module_name = format_name(version.split('::')[-2])

          {
            path: gem_path,
            gemspec: gemspec,
            spec_var: gemspec.scan(/(\w+)\.name/).flatten[0],
            version: gemspec.scan(/version.+=\s+(.+)$/).flatten[0],
            name: gemspec.scan(/name.+['"](.+)['"]/).flatten[0],
            version: version,
            require_version: require_version,
            module_path: File.join('lib', module_subpath + '.rb'),
            module_name: module_name
          }
        end

        # Add spaces between capital letters
        #
        def self.format_name(name)
          name.scan(/.*?[a-z](?=[A-Z]|$)/).join(' ')
        end

        # Indent each line of a string
        #
        def self.indent(input, level=1)
          input.gsub(/^/, '  ' * level)
        end

        # Insert a string before a position
        #
        def self.insert_before(str, pos, input)
          if pos
            str[0..(pos - 1)] + input + str[pos..-1]
          else
            str
          end
        end
      end
    end
  end
end
