# frozen_string_literal: true

# DS::FrameUp.reload;DS::FrameUp::Panel.test

module DS
  module FrameUp

    Sketchup.require(File.join(PLUGIN_DIR, 'perimeter'))
    Sketchup.require(File.join(PLUGIN_DIR, 'wall'))
    Sketchup.require(File.join(PLUGIN_DIR, 'opening'))
    Sketchup.require(File.join(PLUGIN_DIR, 'drywall'))
    Sketchup.require(File.join(PLUGIN_DIR, 'sheathing_interior'))
    Sketchup.require(File.join(PLUGIN_DIR, 'sheathing_exterior'))
    Sketchup.require(File.join(PLUGIN_DIR, 'strapping'))
    Sketchup.require(File.join(PLUGIN_DIR, 'insulation'))
    Sketchup.require(File.join(PLUGIN_DIR, 'constants'))
    Sketchup.require(File.join(PLUGIN_DIR, 'util'))

    class Panel
      include Util

      attr_reader :group

      def initialize(parameters, group)
        @par = parameters
        @group = group
        @faces = init_faces
        @faces_hash = init_faces_hash
        init_dimensions
        check_axes
        @walls = init_walls
        @openings = init_openings
        @perimeter = Perimeter.new(@par, self)
        @strapping = Strapping.new(@par, position_strapping)
        @drywall = Drywall.new(@par, position_drywall)
        @sheathing_interior = SheathingInterior.new(@par, position_sheathing_int)
        @sheathing_exterior = SheathingExterior.new(@par, position_sheathing_ext)
        @insulation = Insulation.new(@par)
      end

      # Not named parameters just because I want a shorter name
      def parameters
        @par
      end

      def init_group_top
        group_top = @group.parent.entities.add_group
        group_top.name = @group.name
        group_top.transform!(@group.transformation)
        group_top
      end

      def position_strapping
        p = position.clone
        p
      end

      def position_sheathing_ext
        p = position.clone
        p.y += @par[:strap_thickness]
        p
      end

      def position_sheathing_int
        p = position.clone
        p.y += thickness - @par[:drywall_thickness] - @par[:stud_depth] - @par[:sheet_int_thickness]
        p
      end

      def position_drywall
        p = position.clone
        p.y += thickness - @par[:drywall_thickness]
        # p.z += height_ledge
        p.z += height_ledge if ledge_at_bottom?
        p
      end

      def frame
        top = init_group_top
        frame_openings(top)
        frame_walls(top)
        frame_drywall(top)
        frame_sheathing_interior(top)
        frame_sheathing_exterior(top)
        frame_strapping(top)
        frame_perimeter(top)
        @insulation.fill(top, @group) unless @par[:insulation_type] == :insulation_none
        @group.visible = false
        Sketchup.active_model.selection.clear
      end

      def frame_openings(group)
        @openings.each do |opening|
          # No copy here
          opening.frame(group, @group)
        end
      end

      def frame_walls(group)
        @walls.each do |wall|
          wall.frame(group)
        end
      end

      def frame_perimeter(group)
        @perimeter.frame(group)
      end

      def frame_drywall(group)
        @drywall.frame(group, @group.copy)
      end

      def frame_sheathing_interior(group)
        @sheathing_interior.frame(group, modifier_sheathing_interior)
      end

      def frame_sheathing_exterior(group)
        @sheathing_exterior.frame(group, @group.copy)
      end

      def frame_strapping(group)
        @strapping.frame(group, @group.copy)
      end

      def init_faces
        @faces = @group.definition.entities.grep(Sketchup::Face)
        # @faces = @group.entities.grep(Sketchup::Face)
        # Maybe not necessary because face_front uses normal instead of largest area
        @faces.sort! { |a, b| b.area <=> a.area }
      end

      def init_faces_hash
        faces_hash = {}
        @faces.each do |face|
          normal = normal(face)
          if faces_hash.key? normal
            faces_hash[normal] << face
          else
            faces_hash[normal] = [face]
          end
        end
        sort_faces_hash(faces_hash)
      end

      def sort_faces_hash(faces_hash)
        faces_hash.each do |normal, faces|
          case normal
          when [-1, 0, 0], [0, -1, 0], [0, 0, -1]
            faces.sort! { |a, b| a.plane.last <=> b.plane.last }
          else
            faces.sort! { |a, b| b.plane.last <=> a.plane.last }
          end
        end
        faces_hash
      end

      # This approach drops faces retaining only their position along each axis
      def init_dimensions
        @x = []
        @y = []
        @z = []
        @faces.each do |face|
          d = face.plane.last
          case normal(face)
          when [1, 0, 0], [-1, 0, 0]
            @x << d
          when [0, 1, 0], [0, -1, 0]
            @y << d
          when [0, 0, 1], [0, 0, -1]
            @z << d
          end
        end
        sort_dimensions([@x, @y, @z])
      end

      def sort_dimensions(dimensions)
        dimensions.each do |d|
          d.sort! { |a, b| a.abs <=> b.abs }
        end
        dimensions
      end

      def check_axes
        raise 'Axes are not oriented correctly' unless face_front.normal == [0, -1, 0]
        raise 'Axes are not positioned correctly' unless @group.definition.bounds.min == [0, 0, 0]
      end

      def position
        Geom::Point3d.new(0, 0, 0)
      end

      def thickness
        face_back.plane.last.abs
      end

      def thickness_bottom
        face_back_ledge.plane.last.abs
      end

      def length
        @faces_hash[[1, 0, 0]].last.plane.last.abs
      end

      def height_front
        @faces_hash[[0, 0, 1]].last.plane.last.abs
      end

      def height_back
        # TODO: This will no longer work when ledge can be at top
        # Instead, get z of bounds of back face
        # height_front - @faces_hash[[0, 0, -1]][1].plane.last.abs
        face_back.bounds.depth
      end

      def height_ledge
        height_front - height_back
      end

      def position_z_ledge
      # Issue #14 partly implemented
        # TODO: Error here. max if min is zero
        # face_back.bounds.min.z
        face_back.bounds.min.z == height_ledge ? 0.0 : face_back.bounds.max.z
      end

      def ledge_at_bottom?
        position_z_ledge.zero?
      end

      def face_back
        @faces_hash[[0, 1, 0]].last
      end

      def face_back_ledge
        @faces_hash[[0, 1, 0]].first
      end

      def face_front
        @faces_hash[[0, -1, 0]].first
      end

      def faces_perimeter
        l = outer_loop(face_front)
        faces_common_to_loop(l).reject do |face|
          face.normal == [0, 1, 0] || face.normal == [0, -1, 0]
        end
      end

      def faces_edge
        @faces.reject do |face|
          face.normal == [0, 1, 0] || face.normal == [0, -1, 0]
        end
      end

      # Returns faces common to loop
      def faces_common_to_loop(loop)
        faces = []
        edges = loop.edges
        edges.each do |edge|
          edge.faces.each do |face|
            faces << face unless faces.include?(face)
          end
        end
        faces
      end

      def faces_left
        @faces_hash[[-1, 0, 0]]
      end

      def faces_right
        @faces_hash[[1, 0, 0]]
      end

      def faces_left_right
        f = faces_left + faces_right
        f.sort! { |a, b| b.plane.last.abs <=> a.plane.last.abs }
        f
      end

      def faces_top
        @faces_hash[[0, 0, 1]]
      end

      def inner_loops(face)
        face.loops.reject(&:outer?)
      end

      def outer_loop(face)
        face.loops.select(&:outer?).first
      end

      def init_openings
        openings = []
        inner_loops(face_front).each do |loop|
          # Must use inner loops because openings might have different sill and header heights
          # Bounding box of loop is flat. Class Opening will get thickness from wall bounds
          # Move the opening bounds back by thickness of sheathing

          # Bounds of opening
          bounds_opening = Geom::BoundingBox.new
          loop.vertices.each do |vertex|
            point = vertex.position
            point.y += @par[:sheet_ext_thickness] + @par[:strap_thickness]
            bounds_opening.add point
          end

          # Bounds of enclosing wall
          min = bounds_opening.min
          min.x -= @par[:buck_thickness] + 2 * @par[:stud_thickness]
          min.z = @par[:buck_thickness] + @par[:stud_thickness]

          max = bounds_opening.max
          max.x += @par[:buck_thickness] + 2 * @par[:stud_thickness]
          max.z = height_front - @par[:buck_thickness] - @par[:stud_thickness]
          max.y = thickness

          bounds_wall = Geom::BoundingBox.new.add(min, max)

          openings << Opening.new(@par, bounds_wall, bounds_opening, self)
          # TODO: Simplify contstructor
          # @openings << Opening.new(bounds_opening, height_wall, height_ledge)
        end
        openings
      end

      def init_walls
        walls = []
        @x.each_with_index do |x, i|
          x_next = @x[i + 1]
          x_next_next = @x[i + 2]
          # p "x=#{x} x_next=#{x_next}"
          next if x_next.nil?

          # Init for corner and after corner walls
          pos = Geom::Point3d.new(
            x.abs + @par[:buck_thickness],
            @par[:sheet_ext_thickness] + @par[:strap_thickness],
            @par[:buck_thickness] + @par[:stud_thickness]
          )
          len = x_next.abs - pos.x
          ht = height_front - 2 * @par[:buck_thickness] - 2 * @par[:stud_thickness]
          # Issue #14 partly implemented
          corner_window_wall = false
          # puts
          # p i
          # p x
          # p x_next
          # p x_next_next
          # p wall_type(x, x_next, x_next_next, i)
          case wall_type(x, x_next, x_next_next, i)
          when WALL_OPENING
            next
          when WALL_CORNER_WINDOW_FIRST
            len += @par[:buck_thickness]
            ht = sill_height(x, x_next) - 2 * @par[:stud_thickness] - 2 * @par[:buck_thickness]
            # Issue #14 partly implemented
            corner_window_wall = true
          when WALL_CORNER_WINDOW_LAST
            pos.x -= 2 * @par[:buck_thickness]
            len += @par[:buck_thickness]
            ht = sill_height(x, x_next) - 2 * @par[:stud_thickness] - 2 * @par[:buck_thickness]
            # Issue #14 partly implemented
            corner_window_wall = true
          when WALL_AFTER_CORNER_WINDOW
            len -= 2 * @par[:stud_thickness] + @par[:buck_thickness]
          when WALL_BEFORE_CORNER_WINDOW
            pos.x += 2 * @par[:stud_thickness]
            len -= 2 * @par[:stud_thickness] + @par[:buck_thickness]
          when WALL_FIRST
            # pos.x += 2 * @par[:stud_thickness]
            len -= 2 * @par[:stud_thickness] + @par[:buck_thickness]
          when WALL_LAST
            pos.x += 2 * @par[:stud_thickness]
            len -= 2 * @par[:stud_thickness] + @par[:buck_thickness]
          when WALL
            pos.x += 2 * @par[:stud_thickness]
            len -= 4 * @par[:stud_thickness] + @par[:buck_thickness]
          end

          # Issue #14 partly implemented
          # walls << Wall.new(@par, pos, len, ht, thickness, height_ledge)
          # walls << Wall.new(@par, pos, len, ht, thickness, height_ledge, position_z_ledge, corner_window_wall)
          walls << Wall.new(@par, pos, len, ht, thickness, height_ledge, ledge_at_bottom?, corner_window_wall)
        end
        walls
      end

      def init_perimeter
        Perimeter.new(@par, self)
      end

      # Value of x is positive if plane is facing left
      def wall_type(x, x_next, x_next_next, i)

        return WALL_OPENING if i.positive? && x.negative? && x_next.positive?
        return WALL_CORNER_WINDOW_FIRST if i.zero? && x_next.positive?
        return WALL_CORNER_WINDOW_LAST if i.positive? && x.negative? && x_next.negative?
        return WALL_AFTER_CORNER_WINDOW if i == 1 && x.positive?
        return WALL_BEFORE_CORNER_WINDOW if x.positive? && !x_next_next.nil? && x_next_next&.negative?
        return WALL_FIRST if i.zero? && x_next.negative?
        return WALL_LAST if x.positive? && x_next.negative? && x_next_next.nil?
        return WALL if x.positive? && x_next.negative?

        raise 'No wall type found'
      end

      def sill_height(x, x_next)
        range = (x.abs..x_next.abs)
        faces_top.each do |face|
          center = face.bounds.center
          return center.z if range.cover? center.x
        end
        raise 'No top face found above wall"'
      end

      def sort_by_distance_from_position(vertices)
        vertices.sort! do |a, b|
          Geom::Vector3d.new(a.position.to_a).length <=> Geom::Vector3d.new(b.position.to_a).length
        end
      end

      def modifier_sheathing_interior
        copy = @group.copy
        copy.name = 'modifier_sheathing_interior'
        faces = copy.entities.grep(Sketchup::Face)
        faces.each do |face|
          case normal(face)
          when [0, 1, 0]
            face.pushpull(-@par[:drywall_thickness]) if face.plane.last.abs == thickness
          when [0, -1, 0]
            face.pushpull(-@par[:sheet_ext_thickness] - @par[:strap_thickness])
          when [1, 0, 0], [-1, 0, 0], [0, 0, 1], [0, 0, -1]
            face.pushpull(-@par[:buck_thickness])
          end
        end
        copy
      end

      def self.test
        model = Sketchup.active_model
        model.start_operation('Test', true)
        sel = model.selection
        sel.add(model.active_entities.first) if sel.empty?
        panel = Panel.new(Parameters.new.parameters, sel.first)

        # panel.frame_openings(model, CREATE_SUBGROUP)
        # panel.frame_perimeter(model, CREATE_SUBGROUP)
        # panel.frame_sheathings(model, CREATE_SUBGROUP)
        panel.frame

        # color_faces(panel.faces_edge)
        # color_faces(panel.faces_perimeter)
        # color_face(panel.face_front)
        # p panel.modifier(model, true)

        model.commit_operation
      end

      def self.color_faces(faces)
        faces.each do |face|
          face.material = 'red'
        end
      end

      def self.color_face(face)
        face.material = 'red'
      end
    end
  end
end
