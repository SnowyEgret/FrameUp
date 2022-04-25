# frozen_string_literal: true

module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'sheet_base'))

  class Strapping < SheetBase

    def initialize(parameters, position)
      super(parameters, position)
    end

    def frame(group, modifier)
      name = 'strapping'
      parent_group = group
      group = parent_group.entities.add_group
      group.name = name.capitalize
      set_layer(group, name)
      set_color(group, name, COLOR_STRAPPING)

      bounds = modifier.definition.bounds
      rows = (bounds.depth / @par[:strap_spacing]).to_i
      length = bounds.width
      straps = []
      straps << @lumber.strap(group, @position, length)
      @position.z += @par[:strap_spacing] - @par[:strap_width] / 2
      straps = @lumber.straps(group, @position, rows, length)
      intersect(straps, modifier)
    end
  end
end
end
