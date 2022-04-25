module DS
module FrameUp

  if Sketchup.version.to_i < REQUIRED_SU_VERSION
    msg = "#{EXTENSION.name} requires SketchUp 20#{REQUIRED_SU_VERSION} or later to run."
    UI.messagebox(msg)
    raise msg
  end

  Sketchup.require(File.join(PLUGIN_DIR, 'menus'))
  Menus.new

  # See https://github.com/SketchUp/sketchup-ruby-api-tutorials/wiki/Development-Setup
  # Reload extension by running this method from the Ruby Console
  def self.reload
    verbose = $VERBOSE
    $VERBOSE = nil

    pattern = File.join(PLUGIN_DIR, '**/*.{rb,rbe}')
    Dir.glob(pattern).each { |f| load f }.size
    $VERBOSE = verbose
  end
end
end
