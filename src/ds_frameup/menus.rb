# frozen_string_literal: true

module DS
module FrameUp

  require 'english.rb'
  Sketchup.require(File.join(PLUGIN_DIR, 'parameters'))
  Sketchup.require(File.join(PLUGIN_DIR, 'panel'))

  module Menus
    @parameters = Parameters.new

    unless file_loaded?(__FILE__)

      menu_extensions = UI.menu('Extensions')
      menu_frameup = menu_extensions.add_submenu('FrameUp')
      menu_frameup.add_item('Preferences') { show_parameters_dialog }

      UI.add_context_menu_handler do |context_menu|
        context_menu_frameup = context_menu.add_submenu('FrameUp')
        # cmd = UI::Command.new('Frame Panel') { frame_panel }
        cmd = UI::Command.new('Frame Panel') { show_parameters_dialog }
        cmd.menu_text = 'Frame Panel'
        # cmd.small_icon = 'icons/foo.png'
        # cmd.status_bar_text = 'foo'
        cmd.set_validation_proc do
          selection_valid?(Sketchup.active_model.selection) ? MF_ENABLED : MF_GRAYED
        end
        context_menu_frameup.add_item cmd
      end
      file_loaded(__FILE__)
    end

    def self.show_parameters_dialog
      dialog_pars = @parameters.dialog_parameters
      constants = @parameters.constants

      defs = read_defaults
      defs = @parameters.defaults if defs.nil?
      inputs = UI.inputbox(@parameters.prompts, defs, @parameters.lists, 'FrameUp Preferences')
      return unless inputs

      input = inputs[0]
      par = dialog_pars[:stud_depth]
      par.value = @parameters.stud_depths.key(input)
      par.default = input

      input = inputs[1]
      par = dialog_pars[:stud_spacing]
      par.value = @parameters.stud_spacings.key(input)
      par.default = input

      input = inputs[2]
      par = dialog_pars[:header_depth]
      par.value = @parameters.header_depths.key(input)
      par.default = input

      input = inputs[3]
      par = dialog_pars[:strap_width]
      par.value = @parameters.strap_widths.key(input)
      par.default = input

      input = inputs[4]
      par = dialog_pars[:strap_spacing]
      par.value = @parameters.strap_spacings.key(input)
      par.default = input

      input = inputs[5]
      par = dialog_pars[:sheet_int_type]
      type = @parameters.sheathing_types.key(input)
      par.value = type
      par.default = input
      constants[:sheet_int_thickness] = @parameters.thicknesses[type]

      input = inputs[6]
      par = dialog_pars[:sheet_ext_type]
      type = @parameters.sheathing_types.key(input)
      par.value = type
      par.default = input
      constants[:sheet_ext_thickness] = @parameters.thicknesses[type]

      input = inputs[7]
      par = dialog_pars[:drywall_type]
      type = @parameters.drywall_types.key(input)
      par.value = type
      par.default = input
      constants[:drywall_thickness] = @parameters.thicknesses[type]

      input = inputs[8]
      par = dialog_pars[:insulation_type]
      type = @parameters.insulation_types.key(input)
      par.value = type
      par.default = input

      @parameters.update
      save_defaults
      frame_panel
    end

    def self.save_defaults
      Sketchup.active_model.set_attribute('defaults', :defaults, @parameters.defaults)
      # p read_defaults
    end

    def self.read_defaults
      Sketchup.active_model.get_attribute('defaults', :defaults)
    end

    # def self.remove_defaults
    #   Sketchup.active_model.set_attribute('defaults', nil, nil)
    # end

    def self.frame_panel
      model = Sketchup.active_model
      model.start_operation('Frame', true)
      sel = model.selection
      return if sel.length > 1

      panel = Panel.new(@parameters.parameters, sel.first)
      panel.frame
      model.commit_operation
    end

    def self.selection_valid?(selection)
      # Temporarily commented out because SketchUp tray and console periodically refreshing
      # begin
      #   Panel.new(@parameters.parameters, selection.first)
      # rescue
      #   warn $ERROR_INFO
      #   return false
      # end
      return true unless selection.length > 1
    end

    def self.test
      p read_defaults
      # remove_defaults
      # p read_defaults
    end
  end
end
end
