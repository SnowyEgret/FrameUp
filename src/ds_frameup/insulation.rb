module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'trimmable'))
  Sketchup.require(File.join(PLUGIN_DIR, 'util'))
  Sketchup.require(File.join(PLUGIN_DIR, 'progressbar'))

  class Insulation
    include Trimmable
    include Util

    def initialize(parameters)
      @par = parameters
    end

    def walk(group, target, progress_bar, index)
      return if target.definition == group.definition

      tr = group.transformation.inverse
      tr *= target.transformation
      target = group.entities.add_instance(target.definition, tr)
      group.entities.each do |entity|
        if entity.is_a? Sketchup::Group
          index = walk(entity, target, progress_bar, index)
        else
          trim(target, entity) unless target.definition == entity.definition
          index += 1
          progress_bar.update(index)
        end
      end
      target.erase!
      index
    end

    def fill(group, target)
      target = shrink(group, target)
      target = target.to_component
      name = 'insulation'.freeze
      target.definition.name = name.capitalize
      num_leaves = count_leaves(group, 0)
      progress_bar = ProgressBar.new(num_leaves, 'Filling insulation...')
      walk(group, target, progress_bar, 0)
      remove_material(target)
      set_layer(target, name)
      set_color(target, name, COLOR_INSULATION)
    end

    def count_leaves(group, num_leaves)
      group.entities.each do |entity|
        if entity.is_a? Sketchup::Group
          num_leaves = count_leaves(entity, num_leaves)
        else
          num_leaves += 1
        end
      end
      num_leaves
    end

    # A modifier cannot be completely enclosed by the target
    # Reduce the size of the target so that modifiers are not enclosed
    def shrink(group, target)
      # copy = target.copy
      copy = group.entities.add_instance(target.definition, IDENTITY)
      copy.make_unique
      faces = copy.entities.grep(Sketchup::Face)
      back_faces = []
      faces.each do |face|
        case normal(face)
        when [0, -1, 0]
          face.pushpull(-@par[:strap_thickness] - @par[:sheet_ext_thickness])
        when [0, 1, 0]
          back_faces << face
        when [1, 0, 0], [-1, 0, 0], [0, 0, 1], [0, 0, -1]
          face.pushpull(-@par[:buck_thickness])
        end
      end
      back_faces.sort! { |a, b| a.area <=> b.area }
      back_faces[1].pushpull(-@par[:stud_depth] - @par[:drywall_thickness] - @par[:sheet_int_thickness])
      back_faces[0].pushpull(-@par[:sheet_int_thickness])
      copy
    end

    def self.test
      model = Sketchup.active_model
      ents = model.active_entities
      model.start_operation('Test', true)

      targets = ents.select { |ent| ent.name == 'target' }
      modifiers = ents.select { |ent| ent.name == 'modifiers' }
      insulation = Insulation.new(Parameters.new.parameters)

      # insulation.walk(modifiers.first, targets.first)
      p insulation.count_leaves(modifiers.first, 0)

      model.commit_operation
    end
  end
end
end
