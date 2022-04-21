module DS
module FrameUp

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
        cmd.menu_text = 'Frame Panel'.freeze
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

    def prompts(dialog_parameters)
      prompts = []
      dialog_parameters.values.each do |par|
        prompts << par.prompt
      end
      prompts
    end

    def defaults(dialog_parameters)
      defaults = []
      dialog_parameters.values.each do |par|
        defaults << par.default
      end
      defaults
    end

    def lists(dialog_parameters)
      lists = []
      dialog_parameters.values.each do |par|
        lists << par.list
      end
      lists
    end

    def show_parameters_dialog
      dialog_pars = @parameters.dialog_parameters
      constants = @parameters.constants

      inputs = UI.inputbox(prompts(dialog_pars), defaults(dialog_pars), lists(dialog_pars), 'FrameUp Parameters')
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
      return true unless selection.length > 1
      # TODO: Instantiate a panel and catch exceptions
    end
  end
end
end
