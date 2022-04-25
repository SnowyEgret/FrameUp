# frozen_string_literal: true

module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'sheet_base'))

  class SheathingExterior < SheetBase

    def initialize(parameters, position)
      super(parameters, position)
    end

    def frame(group, modifier)
      parent_group = group
      group = parent_group.entities.add_group
      group.name = 'Sheathing (exterior)'
      name = 'sheathing-exterior'
      set_layer(group, name)
      set_color(group, name, COLOR_SHEET_EXT)

      bounds = modifier.definition.bounds
      rows = (bounds.depth / @par[:sheet_ext_width]).to_i + 1
      columns = (bounds.width / @par[:sheet_ext_length]).to_i + 1
      sheets = @lumber.sheathing(group, @par[:sheet_ext_type], @position, rows, columns)
      intersect(sheets, modifier)
    end
  end
end
end
