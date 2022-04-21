module DS
  module FrameUp
    class StudOpening
      # TODO: Simplify constructor
      # def initialize(bounds, height_wall)
      def initialize(parameters, bounds_wall, bounds_opening)
        @par = parameters
        @bounds_wall = bounds_wall
        @bounds_opening = bounds_opening
        @lumber = Lumber.new(parameters)
      end

      def self.test
        model = Sketchup.active_model
        model.start_operation('Test', true)

        # Set x to same as opening bounds x
        min = Geom::Point3d.new(0, 0, 0)
        max = Geom::Point3d.new(0, 16, 120)
        bounds_wall = Geom::BoundingBox.new.add(min, max)

        min = Geom::Point3d.new(0, 0, 30)
        max = Geom::Point3d.new(34, 16, 84)
        bounds_opening = Geom::BoundingBox.new.add(min, max)

        opening = StudOpening.new(Parameters.new.parameters, bounds_wall, bounds_opening)
        opening.frame(model, CREATE_SUBGROUP)
        model.commit_operation
      end

      def frame(group)
        group = group.entities.add_group
        group.name = 'Opening'

        # Headers
        @lumber.header(group, header_f_position, header_length)
        @lumber.header(group, header_b_position, header_length)

        # Jacks
        @lumber.jack(group, jack_l_position, jack_length)
        @lumber.jack(group, jack_r_position, jack_length)

        # Kings
        @lumber.king(group, king_l_position, king_length)
        @lumber.king(group, king_r_position, king_length)

        # Cripples
        StudWall.new(@par, cripple_t_position, cripple_t_length, cripple_t_height).frame(group)

        # Plates
        @lumber.top_plate(group, plate_t_position, plate_length)
        return if door?

        @lumber.bottom_plate(group, plate_b_position, plate_length)
        StudWall.new(@par, cripple_b_position, cripple_b_length, cripple_b_height).frame(group)
      end

      private

      def height
        @bounds_opening.depth
      end

      def width
        @bounds_opening.width
      end

      def thickness
        @bounds_wall.height
      end

      def height_wall
        @bounds_wall.depth
      end

      def height_sill
        @bounds_opening.min.z - @bounds_wall.min.z
      end

      def door?
        height_sill <= @par[:stud_thickness] + @par[:buck_thickness]
      end

      # All other positions will be derived from left jack
      def jack_l_position
        p = @bounds_wall.min
        # p.x -= @par[:stud_thickness] + @par[:buck_thickness]
        p.x += @par[:stud_thickness]
        p.z += @par[:stud_thickness] unless door?
        p
      end

      def jack_r_position
        p = jack_l_position
        p.x += width + 2 * @par[:buck_thickness] + @par[:stud_thickness]
        p
      end

      def jack_length
        length = height_sill + height + @par[:buck_thickness] - @par[:stud_thickness]
        length += @par[:stud_thickness] if door?
        length
      end

      def king_l_position
        p = jack_l_position
        p.x -= @par[:stud_thickness]
        p
      end

      def king_r_position
        p = king_l_position
        p.x += width + 2 * @par[:buck_thickness] + 3 * @par[:stud_thickness]
        p
      end

      def king_length
        length = height_wall - 2 * @par[:stud_thickness]
        length += @par[:stud_thickness] if door?
        length
      end

      def plate_b_position
        p = king_l_position
        p
      end

      def plate_t_position
        p = king_l_position
        p.z += king_length + @par[:stud_thickness]
        p
      end

      def header_f_position
        p = jack_l_position
        p.z += jack_length
        p
      end

      def header_b_position
        p = header_f_position
        p.y += @par[:stud_depth] - @par[:stud_thickness]
        p
      end

      def header_length
        width + 2 * @par[:buck_thickness] + 2 * @par[:stud_thickness]
      end

      def plate_length
        header_length + 2 * @par[:stud_thickness]
      end

      def cripple_b_position
        p = @bounds_wall.min
        p.x += 2 * @par[:stud_thickness]
        p.z += @par[:stud_thickness]
        p
      end

      def cripple_t_position
        p = header_f_position
        p.z += @par[:header_depth]
        p
      end

      def cripple_b_length
        width + 2 * @par[:buck_thickness]
      end

      def cripple_t_length
        cripple_b_length + 2 * @par[:stud_thickness]
      end

      def cripple_b_height
        height_sill - @par[:stud_thickness] - @par[:buck_thickness]
      end

      def cripple_t_height
        plate_t_position.z - cripple_t_position.z - @par[:stud_thickness]
      end
    end
  end
end
