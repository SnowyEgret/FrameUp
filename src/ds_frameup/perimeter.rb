# frozen_string_literal: true

module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'lumber'))
  Sketchup.require(File.join(PLUGIN_DIR, 'trimmable'))
  Sketchup.require(File.join(PLUGIN_DIR, 'util'))
  Sketchup.require(File.join(PLUGIN_DIR, 'constants'))

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

      bucks_horizontal = []
      bucks_vertical = []
      @panel.faces_perimeter.each do |face|
        bounds = face.bounds
        case normal(face)
        when [1, 0, 0]
          bucks_vertical += frame_right(group_bucks, bounds)
        when [-1, 0, 0]
          bucks_vertical += frame_left(group_bucks, bounds)
        when [0, 0, 1]
          bucks_horizontal += frame_top(group_bucks, group_plates, bounds)
        when [0, 0, -1]
          bucks_horizontal += frame_bottom(group_bucks, group_plates, bounds)
        end
      end
      intersect(bucks_vertical, modifier_buck_vertical)
      # Horizontal bucks overlap with veritical bucks on right end
      intersect(bucks_horizontal, modifier_intersect_horizontal)
      # One horizontal buck is too long if corner window is on left end
      subtract(bucks_horizontal, modifier_subtract_horizontal)
    end

    def modifier_buck_vertical
      copy = @panel.group.copy
      copy.name = 'modifier_buck_vertical'
      faces = copy.entities.grep(Sketchup::Face)
      faces.each do |face|
        case normal(face)
        when [0, 1, 0]
          pushpull_back_face(face)
        end
      end
      copy
    end

    def modifier_intersect_horizontal
      copy = @panel.group.copy
      copy.name = 'modifier_intersect_horizontal'
      faces = copy.entities.grep(Sketchup::Face)
      faces.each do |face|
        case normal(face)
        when [0, 1, 0]
          pushpull_back_face(face)
        when [1, 0, 0]
          face.pushpull(-@par[:buck_thickness])
        end
      end
      copy
    end

    def pushpull_back_face(face)
      if face.plane.last.abs == @panel.thickness
        face.pushpull(-@par[:drywall_thickness])
      else
        target = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth]
        delta = target - face.plane.last.abs
        face.pushpull(delta)
      end
    end

    def modifier_subtract_horizontal
      copy = @panel.group.copy
      copy.name = 'modifier_subtract_horizontal'
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
      num_bucks = (bounds.depth / @par[:sheet_length]).to_i
      @lumber.bucks_vertical(group, p, num_bucks)
    end

    def frame_left(group, bounds)
      p = bounds.min
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      num_bucks = (bounds.depth / @par[:sheet_length]).to_i
      @lumber.bucks_vertical(group, p, num_bucks)
    end

    def frame_top(group_bucks, group_plates, bounds)
      # Top faces are either at top of panel or at top of low walls at corner windows
      # Length and x position must be adjusted for corner window conditions
      length = bounds.width - 2 * @par[:buck_thickness]
      length += 2 * @par[:buck_thickness] if corner_sill?(bounds.min)
      num_bucks = (length / @par[:sheet_length]).to_i
      bucks = @lumber.bucks_horizontal(group_bucks, position_bucks_horizontal_top(bounds), num_bucks)
      @lumber.top_plate(group_plates, position_top_plate_front(bounds), length)
      @lumber.top_plate(group_plates, position_top_plate_back(bounds), length)
      bucks
    end

    # TODO: Extract position calculations to methods like elsewhere
    def frame_bottom(group_bucks, group_plates, bounds)
      length = bounds.width - 2 * @par[:buck_thickness]
      num_bucks = (length / @par[:sheet_length]).to_i
      bucks = @lumber.bucks_horizontal(group_bucks, position_bucks_horizontal_bottom(bounds), num_bucks)
      @lumber.bottom_plate(group_plates, position_bottom_plate_front(bounds), length)
      @lumber.bottom_plate(group_plates, position_bottom_plate_back(bounds), length)
      @lumber.bottom_plate(group_plates, position_bottom_plate_ledge(bounds), length)
      bucks
    end

    def corner_sill?(position)
      position.z != @panel.height_front
    end

    def corner_sill_right?(position)
      corner_sill?(position) && position.x != 0
    end

    def position_bucks_horizontal_top(bounds)
      p = bounds.min
      p.x += @par[:buck_thickness]
      p.x -= 2 * @par[:buck_thickness] if corner_sill_right?(bounds.min)
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      p
    end

    def position_top_plate_front(bounds)
      p = position_bucks_horizontal_top(bounds)
      p.z -= @par[:buck_thickness]
      p
    end

    def position_top_plate_back(bounds)
      p = position_top_plate_front(bounds)
      p.y += buck_width - @par[:stud_depth]
      p
    end

    def position_bucks_horizontal_bottom(bounds)
      p = bounds.min
      p.x += @par[:buck_thickness]
      p.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
      p.z += @par[:buck_thickness]
      p
    end

    def position_bottom_plate_front(bounds)
      p = position_bucks_horizontal_bottom(bounds)
      p.z += @par[:stud_thickness]
      p
    end

    def position_bottom_plate_back(bounds)
      p = position_bottom_plate_front(bounds)
      p.y += @panel.thickness - 2 * @par[:stud_depth] - @par[:drywall_thickness] - @par[:strap_thickness] - 2 * @par[:sheet_ext_thickness]
      p
    end

    def position_bottom_plate_ledge(bounds)
      p = position_bottom_plate_back(bounds)
      p.y += @par[:stud_depth] + @par[:drywall_thickness]
      p.z += @panel.height_ledge - @par[:buck_thickness]
      p
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
