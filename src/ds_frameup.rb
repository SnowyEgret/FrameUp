# Copyright 2022, Duncan Murray Swain
# All rights reserved

# License:    MIT
# Author:     Duncan Murray Swain, duncan.m.swain@gmail.com
# Repository: https://github.com/SnowyEgret/frameup
# Version:    v0.1.0
# Date:       4/25/2022
#
# This extension includes file solid_operations.rb from SketchUp extension SolidTools
# copyrighted by Julia Christina Eneroth in 2018 and
# published at https://github.com/Eneroth3/eneroth-solid-tools under MIT license

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
    EXTENSION.description = 'Frames a double stud wall prefab panel'
    EXTENSION.version     = '0.1.0'
    EXTENSION.copyright   = "2022, #{EXTENSION.creator}"
    Sketchup.register_extension(EXTENSION, true)
  end
end
