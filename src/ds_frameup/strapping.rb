module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'sheet_base'))

  class Strapping < SheetBase

    def initialize(parameters, position, modifier)
      super(parameters, position, modifier)
    end

    def frame(group)
      name = 'strapping'
      parent_group = group
      group = parent_group.entities.add_group
      group.name = name.capitalize
      set_layer(group, name)
      set_color(group, name, COLOR_STRAPPING)

      bounds = @modifier.definition.bounds
      rows = (bounds.depth / @par[:strap_spacing]).to_i + 1
      straps = @lumber.straps(group, @position, rows, bounds.width)
      intersect(straps, @modifier)
    end
  end
end
end
