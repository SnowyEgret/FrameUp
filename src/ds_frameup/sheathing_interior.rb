module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'sheet_base'))

  class SheathingInterior < SheetBase

    def initialize(parameters, position, modifier)
      super(parameters, position, modifier)
    end

    def frame(group)
      parent_group = group
      group = parent_group.entities.add_group
      group.name = 'Sheathing (interior)'
      name = 'sheathing-interior'
      set_layer(group, name)
      set_color(group, name, COLOR_SHEET_INT)

      bounds = @modifier.definition.bounds
      rows = (bounds.depth / @par[:sheet_int_width]).to_i + 1
      columns = (bounds.width / @par[:sheet_int_length]).to_i + 1
      sheets = @lumber.sheathing(group, @par[:sheet_int_type], @position, rows, columns)
      intersect(sheets, @modifier)
    end
  end
end
end
