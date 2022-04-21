#-------------------------------------------------------------------------------
#
#    Author: Duncan Swain
#    Copyright: Copyright (c) 2022
#    License: MIT
#
#-------------------------------------------------------------------------------
require 'extensions.rb'

module DS
  module FrameUp
    path = __FILE__
    path.force_encoding('UTF-8') if path.respond_to?(:force_encoding)

    PLUGIN_ID = File.basename(path, '.*')
    PLUGIN_DIR = File.join(File.dirname(path), PLUGIN_ID)
    REQUIRED_SU_VERSION = 14
    EXTENSION = SketchupExtension.new('FrameUp', File.join(PLUGIN_DIR, 'main'))

    EXTENSION.creator     = 'Duncan Swain (SnowyEgret)'
    EXTENSION.description = 'Frames a panel'
    EXTENSION.version     = '1.0'
    EXTENSION.copyright   = "2022, #{EXTENSION.creator}"
    Sketchup.register_extension(EXTENSION, true)
  end
end
