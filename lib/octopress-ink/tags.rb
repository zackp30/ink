module Octopress
  module Ink
    module Tags
      autoload :IncludeTag,           'octopress-ink/tags/include'
      autoload :AssignTag,            'octopress-ink/tags/assign'
      autoload :ReturnTag,            'octopress-ink/tags/return'
      autoload :FilterTag,            'octopress-ink/tags/filter'
      autoload :RenderTag,            'octopress-ink/tags/render'
      autoload :CaptureTag,           'octopress-ink/tags/capture'
      autoload :JavascriptTag,        'octopress-ink/tags/javascript'
      autoload :StylesheetTag,        'octopress-ink/tags/stylesheet'
      autoload :ContentForTag,        'octopress-ink/tags/content_for'
      autoload :YieldTag,             'octopress-ink/tags/yield'
      autoload :WrapTag,              'octopress-ink/tags/wrap'
      autoload :AbortTag,             'octopress-ink/tags/abort'
      autoload :LineCommentTag,       'octopress-ink/tags/line_comment'
      autoload :DocUrlTag,            'octopress-ink/tags/doc_url'
    end
  end
end

