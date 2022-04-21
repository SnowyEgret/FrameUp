module DS
module FrameUp
  class ShopDrawing
    def self.test
      path = File.join(__dir__, 'layout/test.layout')
      # doc = Layout::Document.new(path)
      doc = Layout::Document.new

      bounds = Geom::Bounds2d.new(1, 1, 4, 4)
      rows = 16
      columns = 4
      table = Layout::Table.new(bounds, rows, columns)
      doc.add_entity(table, doc.layers.first, doc.pages.first)

      anchor_type = Layout::FormattedText::ANCHOR_TYPE_TOP_LEFT
      start_point = Geom::Point2d.new(1, 1)
      text = Layout::FormattedText.new("Hello LayOut", start_point, anchor_type)
      table[1, 1].data = text


      doc.grid.show = false
      doc.save(path)

      # entities = doc.shared_entities
      # p entities.length
      # entities.each do |ent|
      #   p ent
      # end
    end
  end
end
end
