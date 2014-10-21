require 'pocketsphinx/configuration/setting_definition'

module Pocketsphinx
  class Configuration
    attr_reader :ps_config
    attr_reader :setting_definitions

    private_class_method :new

    def initialize(ps_arg_defs)
      @ps_arg_defs = ps_arg_defs
      @setting_definitions = SettingDefinition.from_arg_defs(ps_arg_defs)

      # Sets default settings based on definitions
      @ps_config = API::Sphinxbase.cmd_ln_parse_r(nil, ps_arg_defs, 0, nil, 1)

      # Sets default grammar and language model if they are not set explicitly and
      # are present in the default search path.
      API::Pocketsphinx.ps_default_search_args(@ps_config)
    end

    def self.default
      new(API::Pocketsphinx.ps_args)
    end

    def setting_names
      setting_definitions.keys.sort
    end

    # Get details for one or all configuration settings
    #
    # @param [String] name Name of setting to get details for. Gets details for all settings if nil.
    def details(name = nil)
      details = [name || setting_names].flatten.map do |name|
        definition = find_definition(name)

        {
          name: name,
          type: definition.type,
          default: definition.default,
          required: definition.required?,
          value: self[name],
          info: definition.doc
        }
      end

      name ? details.first : details
    end

    # Get a configuration setting
    def [](name)
      case find_definition(name).type
      when :integer
        API::Sphinxbase.cmd_ln_int_r(@ps_config, "-#{name}")
      when :float
        API::Sphinxbase.cmd_ln_float_r(@ps_config, "-#{name}")
      when :string
        API::Sphinxbase.cmd_ln_str_r(@ps_config, "-#{name}")
      when :boolean
        API::Sphinxbase.cmd_ln_int_r(@ps_config, "-#{name}") != 0
      when :string_list
        raise NotImplementedException
      end
    end

    # Set a configuration setting with type checking
    def []=(name, value)
      check_type(name, type = find_definition(name).type, value)

      case type
      when :integer
        API::Sphinxbase.cmd_ln_set_int_r(@ps_config, "-#{name}", value.to_i)
      when :float
        API::Sphinxbase.cmd_ln_set_float_r(@ps_config, "-#{name}", value.to_f)
      when :string
        API::Sphinxbase.cmd_ln_set_str_r(@ps_config, "-#{name}", value.to_s)
      when :boolean
        API::Sphinxbase.cmd_ln_set_int_r(@ps_config, "-#{name}", value ? 1 : 0)
      when :string_list
        raise NotImplementedException
      end
    end

    private

    def find_definition(name)
      setting_definitions[name] or raise "Configuration setting '#{name}' does not exist"
    end

    def check_type(name, expected_type, value)
      conversion_method = case expected_type
        when :integer then :to_i
        when :float then :to_f
      end

      if conversion_method && !value.respond_to?(conversion_method)
        raise "Configuration setting '#{name}' must be of type #{expected_type.to_s.capitalize}"
      end
    end
  end
end
