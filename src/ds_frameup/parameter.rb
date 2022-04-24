module DS
module FrameUp
  class Parameter
    attr_accessor :value, :prompt, :default, :list

    def initialize(prompt, options_hash)
      @value = options_hash.keys.first
      @prompt = prompt
      # default = options_hash.values.first
      @default = options_hash.values.first
      @list = bar_separated_list(options_hash.values)
    end

    def bar_separated_list(array_of_strings)
      list = ''
      array_of_strings.each do |s|
        list << s
        list << '|'
      end
      list
    end
  end
end
end
