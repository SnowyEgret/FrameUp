# frozen_string_literal: true

module DS
  module FrameUp

    Sketchup.require(File.join(PLUGIN_DIR, 'trimmable'))
    Sketchup.require(File.join(PLUGIN_DIR, 'util'))

    class Buck
      include Trimmable
      include Util

      def initialize(parameters, bounds, modifier)
        @par = parameters
        @modifier = modifier
        @bounds = bounds
        @lumber = Lumber.new(parameters)
      end

      def frame(group)
        name = 'buck'
        group = group.entities.add_group
        group.name = name.capitalize
        set_layer(group, name)
        set_color(group, name, COLOR_BUCK)

        bucks = []
        bucks << @lumber.buck_vertical(group, buck_l_position)
        bucks << @lumber.buck_vertical(group, buck_r_position)
        intersect(bucks, shrink_back(@modifier))
        subtract(bucks, shrink_edges(@modifier))
        bucks.clear
        bucks << @lumber.buck_horizontal(group, buck_t_position)
        bucks << @lumber.buck_horizontal(group, buck_b_position)
        intersect(bucks, shrink_back(@modifier))
        # Horizontal panels overlap with vertical on right side of buck
        subtract(bucks, shrink_edges_except_left_facing(@modifier))
      end

      def shrink_back(modifier)
        copy = modifier.copy
        copy.name = 'buck_shrink_back_modifier'
        faces = copy.entities.grep(Sketchup::Face)
        faces.each do |face|
          case normal(face)
          when [0, 1, 0]
            face.pushpull(-@par[:drywall_thickness])
          end
        end
        copy
      end

      def shrink_edges(modifier)
        copy = modifier.copy
        copy.name = 'buck_shrink_edges_modifier'
        faces = copy.entities.grep(Sketchup::Face)
        faces.each do |face|
          case normal(face)
          when [1, 0, 0], [-1, 0, 0], [0, 0, 1], [0, 0, -1]
            face.pushpull(-@par[:buck_thickness])
          end
        end
        copy
      end

      def shrink_edges_except_left_facing(modifier)
        copy = modifier.copy
        copy.name = 'buck_shrink_edges_modifier'
        faces = copy.entities.grep(Sketchup::Face)
        faces.each do |face|
          case normal(face)
          when [1, 0, 0], [0, 0, 1], [0, 0, -1]
            face.pushpull(-@par[:buck_thickness])
          end
        end
        copy
      end

      def buck_l_position
        p = @bounds.min
        p.x -= @par[:buck_thickness]
        p.z -= @par[:buck_thickness]
        p
      end

      def buck_r_position
        p = buck_l_position
        p.x += width + @par[:buck_thickness]
        p
      end

      def buck_b_position
        p = @bounds.min
        # p.z += @par[:buck_thickness]
        p
      end

      def buck_t_position
        p = @bounds.min
        p.z += height + @par[:buck_thickness]
        p
      end

      def width
        @bounds.width
      end

      def height
        @bounds.depth
      end

      def self.test
        model = Sketchup.active_model
        model.start_operation('Test', true)
        sel = model.selection
        sel.add(model.active_entities.first) if sel.empty?
        min = Geom::Point3d.new(0, 0, 0)
        max = Geom::Point3d.new(16, 0, 30)
        bounds = Geom::BoundingBox.new.add(min, max)

        buck = Buck.new(Parameters.new.parameters, bounds, sel.first)
        buck.frame(model, true)
        model.commit_operation
      end
    end
  end
end
