module Jekyll
  module Convertible
    alias_method :do_layout_orig, :do_layout

    def do_layout(payload, layouts)
      # The contentblock tags needs access to the converter to process it while rendering.
      config = Octopress::Ink::Plugins.config
      payload['plugins']   = config['plugins']
      payload['theme']     = config['theme']
      payload['converter'] = self.converter
      payload['octopress'] = {}
      payload['octopress']['version'] = Octopress::Ink.version
      if Octopress::Ink.config['docs_mode']
        payload['doc_pages'] = Octopress::Ink::Plugins.doc_pages
      end
      do_layout_orig(payload, layouts)
    end
  end

  # Create a new page class to allow partials to trigger Jekyll Page Hooks.
  class ConvertiblePage
    include Convertible
    
    attr_accessor :name, :content, :site, :ext, :output, :data
    
    def initialize(site, name, content)
      @site     = site
      @name     = name
      @ext      = File.extname(name)
      @content  = content
      @data     = { layout: "no_layout" } # hack
      
    end
    
    def render(payload)
      do_layout(payload, { no_layout: nil })
    end
  end
end
