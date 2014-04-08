module Octopress
  module Ink
    module Tags
      class StylesheetTag < Liquid::Tag
        def render(context)
          AssetPipeline.stylesheet_tags
        end
      end
    end
  end
end

