# frozen_string_literal: true

module DS
module FrameUp

  require 'english.rb'
  Sketchup.require(File.join(PLUGIN_DIR, 'parameters'))
  Sketchup.require(File.join(PLUGIN_DIR, 'panel'))

  class Menus
    def initialize
      @parameters = Parameters.new

      return if file_loaded?(__FILE__)

      menu_extensions = UI.menu('Extensions')
      menu_frameup = menu_extensions.add_submenu('FrameUp')
      menu_frameup.add_item('Preferences') { show_parameters_dialog }

      UI.add_context_menu_handler do |context_menu|
        context_menu_frameup = context_menu.add_submenu('FrameUp')
        cmd = UI::Command.new('Frame Panel') { frame_panel }
        cmd.menu_text = 'Frame Panel'
        # cmd.small_icon = 'icons/foo.png'
        # cmd.status_bar_text = 'foo'
        cmd.set_validation_proc do
          selection_valid?(Sketchup.active_model.selection) ? MF_ENABLED : MF_GRAYED
        end
        context_menu_frameup.add_item cmd
        # context_menu_frameup.add_item('Frame Panel') { frame_panel }
      end
      file_loaded(__FILE__)
    end

    def show_parameters_dialog
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
      constants[:sheet_thickness] = @parameters.thicknesses[type]

      input = inputs[6]
      par = dialog_pars[:sheet_ext_type]
      type = @parameters.sheathing_types.key(input)
      par.value = type
      par.default = input
      constants[:sheet_thickness] = @parameters.thicknesses[type]

      input = inputs[7]
      par = dialog_pars[:drywall_type]
      type = @parameters.drywall_types.key(input)
      par.value = type
      par.default = input
      constants[:drywall_thickness] = @parameters.thicknesses[type]

      @parameters.update
      save_defaults
    end

    def save_defaults
      Sketchup.active_model.set_attribute('defaults', :defaults, @parameters.defaults)
    end

    def read_defaults
      Sketchup.active_model.get_attribute('defaults', :defaults)
    end

    def frame_panel
      model = Sketchup.active_model
      model.start_operation('Frame', true)
      sel = model.selection
      return if sel.length > 1

      panel = Panel.new(@parameters.parameters, sel.first)
      panel.frame
      model.commit_operation
    end

    def selection_valid?(selection)
      begin
        Panel.new(@parameters.parameters, selection.first)
      rescue
        warn $ERROR_INFO
        return false
      end
      return true unless selection.length > 1
    end
  end
end
end
