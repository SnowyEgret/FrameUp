# frozen_string_literal: true

module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'stud_wall'))
  Sketchup.require(File.join(PLUGIN_DIR, 'constants'))
  Sketchup.require(File.join(PLUGIN_DIR, 'util'))

  class Wall
    include Util

    # Issue #14 partly implemented
    # def initialize(parameters, position, length, height, thickness, height_ledge)
    def initialize(
      parameters,
      position,
      length,
      height,
      thickness,
      height_ledge,
      position_z_ledge,
      corner_window_wall
    )
      @par = parameters
      @position = position
      @height = height
      @thickness = thickness
      @height_ledge = height_ledge
      @position_z_ledge = position_z_ledge
      @corner_window_wall = corner_window_wall

      @stud_wall_front = StudWall.new(parameters, wall_f_position, length, wall_f_height)
      @stud_wall_back = StudWall.new(parameters, wall_b_position, length, wall_b_height)
    end

    def frame(group)
      group = group.entities.add_group
      group.name = 'Wall'
      name = 'framing'
      set_layer(group, name)
      set_color(group, name, COLOR_FRAMING)

      @stud_wall_front.frame(group)
      @stud_wall_back.frame(group)
    end

    def wall_f_position
      @position.clone
    end

    def wall_b_position
      p = wall_f_position
      p.y += @thickness - @par[:stud_depth] - @par[:strap_thickness] - @par[:sheet_ext_thickness] - @par[:drywall_thickness]
      # Issue #14 partly implemented
      # p.z += @height_ledge - @par[:buck_thickness]
      p.z += @position_z_ledge - @par[:buck_thickness] unless @position_z_ledge.zero?
      p
    end

    def wall_f_height
      @height
    end

    def wall_b_height
      # Issue #14 partly implemented
      # wall_f_height + @par[:buck_thickness] - @height_ledge
      if @position_z_ledge.zero? && @corner_window_wall
        wall_f_height
      else
        wall_f_height + @par[:buck_thickness] - @height_ledge
      end
    end

    def self.test
      model = Sketchup.active_model
      model.start_operation('Test', true)
      pos = Geom::Point3d.new(0, 0, 0)
      wall = Wall.new(Parameters.new.parameters, pos, 80, 120, 16, 12)
      wall.frame(model, CREATE_SUBGROUP)
      model.commit_operation
    end
  end
end
end
