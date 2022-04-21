require_relative 'solid_operations.rb'

module DS
module FrameUp
module SolidTests
  def self.test
    model = Sketchup.active_model
    model.start_operation('Test', true)
    # sel = model.selection
    ents = model.active_entities

    # Trim one target with one modifier
    # modifier = sel.first
    # target = sel[1]
    # p Eneroth::SolidTools::SolidOperations.trim(target, modifier)

    # Trim one target with multiple modifiers
    targets = ents.select { |ent| ent.name == 'target' }
    modifiers_group = ents.select { |ent| ent.name == 'modifiers' }.first
    modifiers = modifiers_group.entities.select { |ent| ent.name == 'modifier' }
    targets.each do |modifier|
      p 'target=' + modifier.name
    end
    modifiers.each do |modifier|
      p 'modifier=' + modifier.name
    end
    # Eneroth::SolidTools::BulkSolidOperations.trim(targets, modifiers)
    Eneroth::SolidTools::SolidOperations.trim(targets.first, modifiers.first)

    model.commit_operation
  end
end
end
end
