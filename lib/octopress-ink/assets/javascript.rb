module Octopress
  module Ink
    module Assets
      class Javascript < Asset
        def tag
          "<script src='#{Filters.expand_url(File.join(dir, file))}'></script>"
        end

        def destination
          File.join(base, plugin.slug, file)
        end
      end
    end
  end
end

