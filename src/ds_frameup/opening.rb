module DS
  module FrameUp

    Sketchup.require(File.join(PLUGIN_DIR, 'stud_opening'))
    Sketchup.require(File.join(PLUGIN_DIR, 'constants'))
    Sketchup.require(File.join(PLUGIN_DIR, 'buck'))
    Sketchup.require(File.join(PLUGIN_DIR, 'util'))

    class Opening
      include Util

      #TODO: Simmplify constructotr
      # def initialize(bounds_opening, height_wall, height_ledge)
      # def initialize(bounds_wall, bounds_opening, height_ledge)
      def initialize(parameters, bounds_wall, bounds_opening, panel)
      # def initialize(parameters, bounds_wall, bounds_opening)
        @par = parameters
        @panel = panel
        @bounds_wall = bounds_wall
        @bounds_opening = bounds_opening
        @front = StudOpening.new(parameters, bounds_wall_front, bounds_opening)
        @back = StudOpening.new(parameters, bounds_wall_back, bounds_opening)
        @buck = Buck.new(parameters, bounds_opening)
      end

      def frame(group, modifier)
        group = group.entities.add_group
        group.name = 'Opening'
        name = 'framing'
        set_layer(group, name)
        set_color(group, name, COLOR_FRAMING)

        @front.frame(group)
        @back.frame(group)
        @buck.frame(group, modifier)
      end

      def bounds_wall_front
        @bounds_wall
      end

      def bounds_wall_back
        min = @bounds_wall.min
        min.y += thickness - @par[:stud_depth] - @par[:drywall_thickness]
        # TODO: Move height_ledge to parameters
        min.z += @panel.height_ledge - @par[:buck_thickness]
        # min.z += @panel.height_ledge - @par[:stud_thickness] - @par[:buck_thickness]
        max = @bounds_wall.max
        max.y = min.y
        Geom::BoundingBox.new.add(min, max)
      end

      def thickness
        @bounds_wall.height
      end
    end
  end
end
