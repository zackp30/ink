class TestPlugin < Octopress::Ink::Plugin
  def initialize(name, type)
    @assets_path = File.expand_path(File.join(File.dirname(__FILE__)))
    @description = "Test some plugins y'all"
    super
  end

  def add_assets
    add_css 'plugin-test.css'
    add_css 'plugin-media-test.css', 'print'
    super
  end
end

Octopress::Ink.register_plugin(TestPlugin, 'awesome-sauce')
