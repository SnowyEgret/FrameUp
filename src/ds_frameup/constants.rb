# frozen_string_literal: true

module DS
  module FrameUp
    DIM_3_8 = 0.375
    DIM_1_2 = 0.5
    DIM_7_16 = 0.4375
    DIM_5_8 = 0.625
    DIM_3_4 = 0.75

    WALL_CORNER_FIRST = 0
    WALL_CORNER_LAST = 1
    WALL_AFTER_CORNER = 2
    WALL_BEFORE_CORNER = 3
    WALL_TYPICAL = 4
    OPENING = 5

    COLOR_SHEATHING = [241, 239, 222].freeze
    COLOR_STRAPPING = [241, 239, 222].freeze
    COLOR_FRAMING = [215, 208, 202].freeze
    COLOR_BUCK = [171, 103, 80].freeze
    COLOR_DRYWALL = [239, 239, 239].freeze
    COLOR_SHEET_INT = [239, 239, 239].freeze
    COLOR_SHEET_EXT = [239, 239, 239].freeze
    COLOR_INSULATION = [239, 239, 239].freeze

    CREATE_SUBGROUP = true
  end
end
