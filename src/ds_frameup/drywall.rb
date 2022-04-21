# frozen_string_literal: true

module DS
module FrameUp
  Sketchup.require(File.join(PLUGIN_DIR, 'sheet_base'))

  class Drywall < SheetBase
    def initialize(parameters, position, modifier)
      super(parameters, position, modifier)
    end

    def frame(group)
      name = 'drywall'
      parent_group = group
      group = parent_group.entities.add_group
      group.name = name.capitalize
      set_layer(group, name)
      set_color(group, name, COLOR_DRYWALL)

      bounds = @modifier.definition.bounds
      rows = (bounds.depth / @par[:drywall_width]).to_i + 1
      columns = (bounds.width / @par[:drywall_length]).to_i + 1
      sheets = @lumber.sheathing(group, @par[:drywall_type], @position, rows, columns)
      intersect(sheets, @modifier)
    end
  end
end
end
