require_relative 'constants.rb'
module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'lumber'))
  Sketchup.require(File.join(PLUGIN_DIR, 'trimmable'))
  Sketchup.require(File.join(PLUGIN_DIR, 'util'))

  class Perimeter
    include Trimmable
    include Util

    def initialize(parameters, panel)
      @par = parameters
      @panel = panel
      @lumber = Lumber.new(parameters)
    end

    def frame(group)
      name = 'perimeter'
      group = group.entities.add_group
      group.name = name.capitalize

      name = 'buck'
      group_bucks = group.entities.add_group
      group_bucks.name = name.capitalize
      set_layer(group_bucks, name)
      set_color(group_bucks, name, COLOR_BUCK)

      name = 'plates'
      group_plates = group.entities.add_group
      group_plates.name = name.capitalize
      set_layer(group_plates, 'framing')
      set_color(group_plates, 'framing', COLOR_FRAMING)

      @panel.faces_perimeter.each do |face|
        bounds = face.bounds
        bucks = []
        case normal(face)
        when [1, 0, 0]
          bucks << frame_right(group_bucks, bounds)
        when [-1, 0, 0]
          bucks << frame_left(group_bucks, bounds)
        when [0, 0, 1]
          bucks += frame_top(group_bucks, group_plates, bounds)
        when [0, 0, -1]
          bucks += frame_bottom(group_bucks, group_plates, bounds)
        end
        intersect(bucks, shrink_back(@panel.group))
        subtract(bucks, shrink_edges(@panel.group))
      end
    end

    def shrink_back(modifier)
      copy = modifier.copy
      copy.name = 'perimeter_shrunk_back_modifier'
      faces = copy.entities.grep(Sketchup::Face)
      faces.each do |face|
        case normal(face)
        when [0, 1, 0]
          face.pushpull(-@par[:drywall_thickness]) if face.plane.last.abs == @panel.thickness
        end
      end
      copy
    end

    def shrink_edges(modifier)
      copy = modifier.copy
      copy.name = 'perimeter_shrunk_edges_modifier'
      faces = copy.entities.grep(Sketchup::Face)
      faces.each do |face|
        case normal(face)
        when [1, 0, 0], [-1, 0, 0], [0, 0, 1], [0, 0, -1]
          face.pushpull(-@par[:buck_thickness])
        end
      end
      copy
    end

    def frame_right(group, bounds)
      p = bounds.min
      p.x -= @par[:buck_thickness]
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      @lumber.buck_vertical(group, p)
    end

    def frame_left(group, bounds)
      p = bounds.min
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      @lumber.buck_vertical(group, p)
    end

    def frame_top(group_bucks, group_plates, bounds)
      # Top faces are either at top of panel or at top of low walls at corner windows
      # Length and x position must be adjusted for corner window conditions
      # TODO: Array of bucks
      p = bounds.min
      p.x += @par[:buck_thickness]
      p.x -= 2 * @par[:buck_thickness] if right_corner_sill?(bounds.min)
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      length = bounds.width - 2 * @par[:buck_thickness]
      length += 2 * @par[:buck_thickness] if corner_sill?(bounds.min)
      num_bucks = (length / @par[:sheet_length]).to_i
      bucks = @lumber.bucks_horizontal(group_bucks, p, num_bucks)
      p.z -= @par[:buck_thickness]
      @lumber.top_plate(group_plates, p, length)
      p.y += buck_width - @par[:stud_depth]
      @lumber.top_plate(group_plates, p, length)
      bucks
    end

    def frame_bottom(group_bucks, group_plates, bounds)
      p = bounds.min
      p.x += @par[:buck_thickness]
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      p.z += @par[:buck_thickness]
      length = bounds.width - 2 * @par[:buck_thickness]
      num_bucks = (length / @par[:sheet_length]).to_i
      bucks = @lumber.bucks_horizontal(group_bucks, p, num_bucks)
      p.z += @par[:stud_thickness]
      @lumber.bottom_plate(group_plates, p, length)
      p.y += @panel.thickness - 2 * @par[:stud_depth] - @par[:drywall_thickness] - @par[:strap_thickness] - 2 * @par[:sheet_ext_thickness]
      @lumber.bottom_plate(group_plates, p, length)
      # Bottom plate on ledge
      p.y += @par[:stud_depth] + @par[:sheet_int_thickness]
      p.z += @panel.height_ledge - @par[:buck_thickness]
      @lumber.bottom_plate(group_plates, p, length)
      bucks
    end

    def corner_sill?(position)
      position.z != @panel.height_front
    end

    def right_corner_sill?(position)
      corner_sill?(position) && position.x != 0
    end

    def buck_width
      @panel.thickness - @par[:sheet_ext_thickness] - @par[:strap_thickness] - @par[:drywall_thickness]
    end

    def buck_b_width
      buck_width - @par[:stud_depth]
    end
  end
end
end
