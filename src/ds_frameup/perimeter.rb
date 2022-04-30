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
      # Issue #14 partly implemented
      @lumber.top_plate(group_plates, position_plate_ledge(bounds), length) unless @panel.ledge_at_bottom?
      bucks
    end

    def frame_bottom(group_bucks, group_plates, bounds)
      length = bounds.width - 2 * @par[:buck_thickness]
      num_bucks = (length / @par[:sheet_length]).to_i
      bucks = @lumber.bucks_horizontal(group_bucks, position_bucks_horizontal_bottom(bounds), num_bucks)
      # @lumber.bottom_plate(group_plates, position_bottom_plate_front(bounds), length)
      # @lumber.bottom_plate(group_plates, position_bottom_plate_back(bounds), length)
      # TODO: Check bottom_b_with to see if two current stud widths will fit
      # 2X6 likely too deep if ledge is at bottom
      overide_stud_depth = 3.5
      @lumber.bottom_plate(group_plates, position_bottom_plate_front(bounds), length, overide_stud_depth)
      @lumber.bottom_plate(group_plates, position_bottom_plate_back(bounds), length, overide_stud_depth)
      # @lumber.bottom_plate(group_plates, position_plate_ledge(bounds), length)
      # Issue #14 partly implemented
      @lumber.bottom_plate(group_plates, position_plate_ledge(bounds), length) if @panel.ledge_at_bottom?
      bucks
    end

    def corner_sill?(position)
      position.z != @panel.height_front
    end

    def corner_sill_right?(position)
      corner_sill?(position) && position.x != 0
    end

    # Top bucks and plate positions
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
      unless @panel.ledge_at_bottom?
        # TODO: Create method Panel#ledge_depth (Panel#ledge_position_z, Panel#ledge_height)
        # TODO: check buck_b_width
        p.y = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth] - 3.5 - @par[:sheet_int_thickness]
      else
        p.y = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth]
      end
      p
    end

    # Bottom bucks and plate positions
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
      # p.y = @panel.thickness - @par[:drywall_thickness] - 2 * @par[:stud_depth] - @par[:sheet_int_thickness]
      # When ledge is at bottom studs must be 2x4 else they will overlap
      if @panel.ledge_at_bottom?
        # TODO: Create method Panel#ledge_depth (Panel#ledge_position_z, Panel#ledge_height)
        # TODO: check buck_b_width
        p.y = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth] - 3.5 - @par[:sheet_int_thickness]
      else
        p.y = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth]
      end
      p
    end

    # Ledge plate either top or bottom
    # TODO: Start from bounds not b
    # def position_plate_ledge(bounds)
    #   p = position_bottom_plate_back(bounds)
    #   p.y = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth]
    #   if @panel.ledge_at_bottom?
    #     p.z += @panel.height_ledge - @par[:buck_thickness]
    #   else
    #     p.z -= @panel.height_ledge - @par[:buck_thickness]
    #   end
    #   p
    # end

    def position_plate_ledge(bounds)
      p = bounds.min
      p.x = @par[:buck_thickness]
      p.y = @panel.thickness - @par[:drywall_thickness] - @par[:stud_depth]
      if @panel.ledge_at_bottom?
        p.z = @panel.height_ledge + @par[:stud_thickness]
      else
        p.z = @panel.position_z_ledge
      end
      p
    end

    # Buck widths
    def buck_width
      @panel.thickness - @par[:sheet_ext_thickness] - @par[:strap_thickness] - @par[:drywall_thickness]
    end

    def buck_b_width
      buck_width - @par[:stud_depth]
    end
  end
end
end
