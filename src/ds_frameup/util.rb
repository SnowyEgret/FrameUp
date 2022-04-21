module DS
module FrameUp
  module Util
    def set_layer(group, name)
      layers = Sketchup.active_model.layers
      layer = layers[name]
      layer = layers.add(name) if layer.nil?
      group.layer = layer
    end

    def set_color(group, name, color)
      materials = Sketchup.active_model.materials
      material = materials[name]
      if material.nil?
        material = materials.add(name)
        material.color = color
      end
      group.material = material
    end

    def remove_material(group)
      group.definition.entities.each do |ent|
        ent.material = nil
      end
    end

    def normal(face)
      normal = face.normal.to_a
      normal[0] = normal[0].to_i
      normal[1] = normal[1].to_i
      normal[2] = normal[2].to_i
      normal
    end
  end
end
end
