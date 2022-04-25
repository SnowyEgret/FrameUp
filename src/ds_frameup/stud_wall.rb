# frozen_string_literal: true

module DS
  module FrameUp
    class StudWall
      def initialize(parameters, position, length, height)
        @par = parameters
        @position = position
        @length = length
        @height = height
        @lumber = Lumber.new(parameters)
      end

      def frame(group)
        group = group.entities.add_group
        group.name = 'Wall'
        # Studs
        @lumber.studs(group, stud_l_position, stud_length, num_studs)
        @lumber.stud(group, stud_r_position, stud_length)

        # Plates
        @lumber.bottom_plate(group, plate_b_position, @length)
        @lumber.top_plate(group, plate_t_position, @length)
      end

      def num_studs
        last_stud_spacing_factor = 1.7
        n = (@length + @par[:stud_spacing] / last_stud_spacing_factor) / @par[:stud_spacing]
        n.to_i - 1
      end

      def stud_l_position
        p = @position.clone
        p.z += @par[:stud_thickness]
        p
      end

      def stud_length
        @height - 2 * @par[:stud_thickness]
      end

      def stud_r_position
        p = stud_l_position
        p.x += @length - @par[:stud_thickness]
        p
      end

      def plate_b_position
        stud_l_position
      end

      def plate_t_position
        p = plate_b_position
        p.z += @height - @par[:stud_thickness]
        p
      end

      def self.test
        model = Sketchup.active_model
        model.start_operation('Test', true)

        # TEST: position of second to last stud
        # 12.times do |i|
        #   position = Geom::Point3d.new(0, i * 6, 0)
        #   wall = StudWall.new(position, 80 + i, 120)
        #   wall.frame(model)
        # end

        # TEST: flag to create subgroup
        position = Geom::Point3d.new(0, 0, 0)
        wall = StudWall.new(Parameters.new.parameters, position, 80, 120)
        # wall.frame(model)
        wall.frame(model, CREATE_SUBGROUP)

        model.commit_operation
      end
    end
  end
end
