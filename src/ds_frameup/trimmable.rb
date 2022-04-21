module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'solid_operations'))

  module Trimmable
    def intersect(targets, modifier)
      # modifier = modifier.copy
      group_targets = targets.first.parent
      targets.each do |target|
        make_unique(target)
        mat = material_of(target)
        # Copy the modifier into the same group as the targets
        modifier_copy = group_targets.entities.add_instance(modifier.definition, IDENTITY)
        result = Eneroth::SolidTools::SolidOperations.intersect(target, modifier_copy)
        raise 'Could not intersect' if result.nil?
        raise 'Container is not solid' if result == false

        re_texture(target, mat)
      end
      modifier.erase!
    end

    def trim(target, modifier)
      # p ''
      # p target.definition.name
      # p modifier.definition.name
      result = Eneroth::SolidTools::SolidOperations.trim(target, modifier)
      raise 'Could not trim' if result.nil?
      raise 'Container is not solid' if result == false
    end

    def subtract(targets, modifier)
      group_targets = targets.first.parent
      targets.each do |target|
        make_unique(target)
        mat = material_of(target)
        # Copy the modifier into the same group as the targets
        modifier_copy = group_targets.entities.add_instance(modifier.definition, IDENTITY)
        result = Eneroth::SolidTools::SolidOperations.subtract(target, modifier_copy)
        raise 'Could not subtract' if result.nil?
        raise 'Container is not solid' if result == false

        # TODO: Remove co-planar edges
        re_texture(target, mat)
        delete_offcuts(target)
      end
      modifier.erase!
    end

    def re_texture(target, material)
      faces = target.definition.entities.grep(Sketchup::Face)
      faces.each do |face|
        face.material = material if face.normal.y.to_i.abs == 1
      end
    end

    def material_of(target)
      faces = target.definition.entities.grep(Sketchup::Face)
      faces.each do |face|
        return face.material if face.normal.y.to_i.abs == 1
      end
    end

    def delete_offcuts(targets)
      targets = [targets] unless targets.is_a? Array
      targets.each do |target|
        point = Geom::Point3d.new(0, 0, 0)
        point.transform(target.transformation)
        faces = target.definition.entities.grep(Sketchup::Face)
        next if faces.length.zero?

        face_on_point = face_on_point(faces, point)
        all_connected = face_on_point.all_connected
        target.definition.entities.to_a.each do |ent|
          ent.erase! unless all_connected.include?(ent) || ent.deleted?
        end
      end
    end

    def face_on_point(faces, point)
      # p faces.length
      faces.each do |face|
        result = face.classify_point(point)
        return face if result == Sketchup::Face::PointOnVertex
      end
      raise 'Could not find a face on point'
    end

    # Overides the default behavior of make_unique to do nothing when instance is already unique
    def make_unique(instance)
      definition = instance.definition
      if definition.instances.length == 1
        copy = Sketchup.active_model.active_entities.add_instance(definition, IDENTITY)
      end
      instance.make_unique
      copy&.erase!
    end

    # Cannot call methods from Trimmable.test unless they are defined with self and then cannot include
    class TrimmableTest
      include Trimmable

      def self.test
        model = Sketchup.active_model
        model.start_operation('Test', true)
        sel = model.selection
        sel.add(model.active_entities.first) if sel.empty?
        trimmable = TrimmableTest.new
        lumber = Lumber.new(Parameters.new.parameters)
        pt = Geom::Point3d.new(0, 0, 0)

        sheets = []
        sheets << lumber.sheet(model, pt, :osb_5_8)
        sheets << lumber.sheet(model, pt, :osb_5_8)
        sheets.each do |sheet|
          trimmable.make_unique(sheet)
        end

        # Test face_on_point
        # buck = lumber.buck_horizontal(model, pt)
        # faces = buck.definition.entities.grep(Sketchup::Face)
        # face = trimmable.face_on_point(faces, pt)
        # face.material = 'red'

        # delete_offcuts(sel.first)
        model.commit_operation
      end
    end
  end
end
end
