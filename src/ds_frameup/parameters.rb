module DS
module FrameUp

  Sketchup.require(File.join(PLUGIN_DIR, 'parameter'))

  class Parameters
    attr_accessor(
      :dialog_parameters,
      :constants,
      :parameters,
      :stud_depths,
      :stud_spacings,
      :header_depths,
      :strap_widths,
      :strap_spacings,
      :sheathing_types,
      :drywall_types,
      :thicknesses
    )

    def initialize
      @stud_depths =
        {
          3.5 => '2x4',
          5.5 => '2x6'
        }

      @stud_spacings =
        {
          16 => '16"',
          24 => '24"'
        }

      @header_depths =
        {
          5.5 => '2x6',
          7.5 => '2x8',
          9.5 => '2x10'
        }

      @strap_widths =
        {
          2.5 => '1x3',
          3.5 => '1x4'
        }

      @strap_spacings =
        {
          16 => '16"',
          24 => '24"'
        }

      @sheathing_types =
        {
          zip_7_16: 'ZIP System 7/16 Wall Panel',
          zip_1_2: 'ZIP System 1/2 Roof Panel',
          zip_5_8: 'ZIP System 5/8 Roof Panel',
          osb_5_8: 'OSB 5/8'
        }

      @drywall_types =
        {
          dry_1_2: 'Gyproc 1/2',
          dry_5_8: 'Gyproc 5/8'
        }

      @thicknesses =
        {
          zip_7_16: 0.4375,
          zip_1_2: 0.5,
          zip_5_8: 0.625,
          osb_5_8: 0.625,
          dry_1_2: 0.5,
          dry_5_8: 0.625
        }

      # Each entry will appear in the dialog_parameters dialog for setting
      @dialog_parameters =
        {
          stud_depth: Parameter.new('Stud:', @stud_depths),
          stud_spacing: Parameter.new('Stud Spacing:', @stud_spacings),
          header_depth: Parameter.new('Header:', @header_depths),
          strap_width: Parameter.new('Strapping:', @strap_widths),
          strap_spacing: Parameter.new('Strap Spacing:', @strap_spacings),
          sheet_int_type: Parameter.new('Interior Sheathing:', @sheathing_types),
          sheet_ext_type: Parameter.new('Exterior Sheathing:', @sheathing_types),
          drywall_type: Parameter.new('Drywall:', @drywall_types)
        }

      # Dimensions which are not set in the dialog
      # Sheathing and drywall thicknesses are here because their change is implied
      # by type which is set above
      @constants =
        {
          stud_thickness: 1.5,
          header_thickness: 1.5,
          strap_thickness: 0.75,
          strap_length: 96,
          buck_thickness: 0.625,
          sheet_int_thickness: 0.4375,
          sheet_ext_thickness: 0.4375,
          sheet_int_width: 48,
          sheet_int_length: 96,
          sheet_ext_width: 48,
          sheet_ext_length: 96,
          sheet_width: 48,
          sheet_length: 96,
          drywall_thickness: 0.5,
          drywall_width: 48,
          drywall_length: 96
        }

      @parameters = merge_dialog_parameters_and_constants
    end

    def merge_dialog_parameters_and_constants
      pars = {}
      @dialog_parameters.each_pair do |key, par|
        pars[key] = par.value
      end
      pars.merge! @constants
      pars
    end

    def update
      @parameters = merge_dialog_parameters_and_constants
    end

    def self.test
      pars = Parameters.new
      # p pars.dialog_parameters
      # p pars.constants
      p pars.parameters
    end
  end
end
end
