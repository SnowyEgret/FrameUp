# frozen_string_literal: true

module DS
  module FrameUp

    Sketchup.require(File.join(PLUGIN_DIR, 'parameters'))
    Sketchup.require(File.join(PLUGIN_DIR, 'constants'))

    class Lumber
      attr_reader(
        :studs_hash,
        :straps_hash,
        :sheets_hash
      )

      def initialize(parameters)
        @par = parameters
        @studs_hash =
          {
            3.5 => definition('spruce 2X4', @par[:stud_thickness], 3.5, 12),
            5.5 => definition('spruce 2X6', @par[:stud_thickness], 5.5, 12),
            7.5 => definition('spruce 2X8', @par[:stud_thickness], 7.5, 12)
          }
        @straps_hash =
          {
            2.5 => definition('spruce 1x3', @par[:strap_thickness], 2.5, @par[:strap_length]),
            3.5 => definition('spruce 1x4', @par[:strap_thickness], 3.5, @par[:strap_length])
          }
        @sheets_hash =
          {
            zip_7_16: definition('ZIP 7/16', @par[:sheet_length], DIM_7_16, @par[:sheet_width], 'zip_7_16.skm'),
            zip_1_2: definition('ZIP 1/2', @par[:sheet_length], DIM_1_2, @par[:sheet_width], 'zip_1_2.skm'),
            zip_5_8: definition('ZIP 5/8', @par[:sheet_length], DIM_5_8, @par[:sheet_width], 'zip_5_8.skm'),
            osb_5_8: definition('OSB 5/8', @par[:sheet_length], DIM_5_8, @par[:sheet_width], 'avantech.skm'),
            ply_3_8: definition('plywood 5/8', @par[:sheet_length], DIM_3_8, @par[:sheet_width], 'ply.skm'),
            ply_1_2: definition('plywood 1/2', @par[:sheet_length], DIM_1_2, @par[:sheet_width], 'ply.skm'),
            ply_5_8: definition('plywood 5/8', @par[:sheet_length], DIM_5_8, @par[:sheet_width], 'ply.skm'),
            ply_3_4: definition('plywood 3/4', @par[:sheet_length], DIM_3_4, @par[:sheet_width], 'ply.skm'),
            dry_1_2: definition('drywall 1/2', @par[:drywall_length], DIM_1_2, @par[:drywall_width]),
            dry_5_8: definition('drywall 5/8', @par[:drywall_length], DIM_5_8, @par[:drywall_width])
          }
      end

      def self.test
        model = Sketchup.active_model
        model.start_operation('Test', true)
        lumber = Lumber.new(Parameters.new.parameters)
        # p lumber.studs_hash
        # p lumber.straps_hash
        # p lumber.sheets_hash
        # p lumber.sheets_hash[:dry_1_2]
        # lumber.stud(model, Geom::Point3d.new(0, -12, 0), 96)
        # lumber.drywall(model, Geom::Point3d.new(0, -12, 0), 3, 4)
        lumber.sheathing(model, :ply_1_2, Geom::Point3d.new(0, -12, 0), 3, 4)
        model.commit_operation
      end

      def definition(name, dim_x, dim_y, dim_z, material_file = nil)
        defs = Sketchup.active_model.definitions
        definition = defs[name]
        return definition unless definition.nil?

        definition = defs.add(name)
        points = [
          Geom::Point3d.new(0, 0, 0),
          Geom::Point3d.new(dim_x, 0, 0),
          Geom::Point3d.new(dim_x, dim_y, 0),
          Geom::Point3d.new(0, dim_y, 0)
        ]
        face = definition.entities.add_face(points)
        face.pushpull(-dim_z)
        texture_sheet(definition, material_file) unless material_file.nil?
        definition
      end

      def texture_sheet(def_or_group, material_file)
        path = File.join(PLUGIN_DIR, 'materials', material_file)
        mat = Sketchup.active_model.materials.load(path)
        faces = def_or_group.entities.grep(Sketchup::Face)
        faces.each do |face|
          face.material = mat if face.normal.y.to_i.abs == 1
        end
      end

      def stud(group, position, length)
        _stud(group, position, length, 'stud')
      end

      def studs(group, position, stud_length, num_studs)
        stud = stud(group, position, stud_length)
        array(group, stud, [@par[:stud_spacing], 0, 0], num_studs)
      end

      def jack(group, position, length)
        _stud(group, position, length, 'jack stud')
      end

      def king(group, position, length)
        _stud(group, position, length, 'king stud')
      end

      def top_plate(group, position, length)
        rotation = Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], 90.degrees)
        _stud(group, position, length, 'top plate', rotation)
      end

      def bottom_plate(group, position, length, stud_depth = nil)
        rotation = Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], 90.degrees)
        # _stud(group, position, length, 'bottom plate', rotation)
        _stud(group, position, length, 'bottom plate', rotation, stud_depth)
      end

      def sill_plate(group, position, length)
        rotation = Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], 90.degrees)
        _stud(group, position, length, 'sill plate', rotation)
      end

      def header(group, position, length)
        tr = Geom::Transformation.new position
        tr *= Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], 90.degrees)
        tr *= Geom::Transformation.rotation([0, 0, 0], [0, 0, 1], 90.degrees)
        tr *= Geom::Transformation.scaling(1, 1, length / 12.0)
        definition = @studs_hash[@par[:header_depth]]
        instance = group.entities.add_instance(definition, tr)
        instance.name = 'header'
        instance
      end

      def buck_vertical(group, position)
        rotation = Geom::Transformation.rotation([0, 0, 0], [-1, 0, 0], 90.degrees)
        rotation *= Geom::Transformation.rotation([0, 0, 0], [0, 0, -1], 90.degrees)
        _buck(group, position, rotation)
      end

      def bucks_vertical(group, position, num_bucks)
        buck = buck_vertical(group, position)
        bucks = array(group, buck, Geom::Vector3d.new(@par[:sheet_length], 0, 0), num_bucks)
        bucks << buck
      end

      def buck_horizontal(group, position)
        rotation = Geom::Transformation.rotation([0, 0, 0], [-1, 0, 0], 90.degrees)
        _buck(group, position, rotation)
      end

      def bucks_horizontal(group, position, num_bucks)
        buck = buck_horizontal(group, position)
        bucks = array(group, buck, Geom::Vector3d.new(@par[:sheet_length], 0, 0), num_bucks)
        bucks << buck
      end

      def sheathing(parent, width, position, num_rows, num_columns)
        definition = @sheets_hash[width]
        raise "Sheet #{width} not found in sheets hash" if definition.nil?

        staggered_grid(
          parent,
          definition,
          'sheet',
          position,
          num_rows,
          num_columns,
          @par[:sheet_width],
          @par[:sheet_length]
        )
      end


      def staggered_grid(
        parent,
        definition,
        name,
        position,
        num_rows,
        num_columns,
        def_width,
        def_length
      )
        instances = []
        x = position.x
        # Must add another column because of stagger
        # num_columns += 1
        num_rows.times do |i|
          stagger = i.odd? ? -def_length / 2 : 0
          position.x += stagger
          num_columns.times do
            tr = Geom::Transformation.new position
            instance = parent.entities.add_instance(definition, tr)
            instance.name = name
            instances << instance
            position.x += def_length
          end
          position.z += def_width
          position.x = x
        end
        instances
      end

      def straps(group, position, rows, length)
        straps = []
        rows.times do
          straps << strap(group, position, length)
          position.z += @par[:strap_spacing]
        end
        straps
      end

      def strap(group, position, length)
        tr = Geom::Transformation.new position
        tr *= Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], 90.degrees)
        tr *= Geom::Transformation.rotation([0, 0, 0], [0, 0, 1], 90.degrees)
        tr *= Geom::Transformation.scaling(1, 1, length / 96.0)
        definition = @straps_hash[@par[:strap_width]]
        instance = group.entities.add_instance(definition, tr)
        instance.name = 'strap'
        instance
      end

      # For testing
      def sheet(group, position, width, name = 'sheet', rotation = IDENTITY)
        tr = Geom::Transformation.new position
        tr *= rotation
        definition = @sheets_hash[width]
        instance = group.entities.add_instance(definition, tr)
        instance.name = name
        instance
      end

      # Copied over from class Framer
      def array(group, instance, vector, num_copies)
        copies = []
        tr = instance.transformation
        num_copies.times do
          tr *= Geom::Transformation.translation(Geom::Vector3d.new(vector))
          copy = group.entities.add_instance(instance.definition, tr)
          copy.name = instance.name
          copies << copy
        end
        copies
      end

      # TODO: Add argument to override current stud depth
      def _stud(group, position, length, name, rotation = IDENTITY, stud_depth = nil)
        tr = Geom::Transformation.new position
        tr *= rotation
        tr *= Geom::Transformation.scaling(1, 1, length / 12.0)
        depth = stud_depth.nil? ? @par[:stud_depth] : stud_depth
        # definition = @studs_hash[@par[:stud_depth]]
        definition = @studs_hash[depth]
        instance = group.entities.add_instance(definition, tr)
        instance.name = name
        instance
      end

      # TODO: Use full sheet trimmed to panel for bucks
      # This way sheet will be textured and sheet definition for sheathing can be used
      # No neeed for @buck
      def _buck(group, position, rotation = IDENTITY)
        tr = Geom::Transformation.new position
        tr *= rotation
        definition = @sheets_hash[:osb_5_8]
        raise 'Buck not found in sheets hash' if definition.nil?

        instance = group.entities.add_instance(definition, tr)
        instance.name = 'panel'
        instance
        # trim(instance, modifier)
      end
    end
  end
end
