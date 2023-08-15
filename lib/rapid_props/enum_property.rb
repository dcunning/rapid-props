# frozen_string_literal: true

module RapidProps
  # Internal class used to define enum properties.
  class EnumProperty < Property
    class UnknownEnumError < InvalidPropertyError; end

    TYPE = "enum"

    attr_reader :choices

    def initialize(id, options = {})
      @choices = options.delete(:choices)
      super(id, **options)

      raise ArgumentError, "choices required" unless @choices
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      raise(UnknownEnumError, value) unless @choices.include?(value)

      value
    end

    def serialize(value, context: nil)
      value
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def to_hash
      super.merge(choices: @choices)
    end

    # :nodoc:
    module Builder
      # Embeds one property definition: nested hash.
      #
      # Minimum usage that automatically creates a child class:
      #
      #   properties do |p|
      #     p.enum :heat_level, choices: %w[mild medium hot]
      #   end
      #
      # === Options
      #
      # The declaration can also include an +options+ hash to specialize the behavior of the property
      #
      # Options are:
      # [:default]
      #   Specify the default value for this property. This argument will be passed into the +#parse+
      #   function and supports a +proc+ that calculates the default value given the parent object.
      # [:choices]
      #   The values accepted by this enum.
      # [:null]
      #   When explicitly +false+ this property will raise an error when setting the property to a +nil+
      #   or when the property value is not specified.
      # [:method_name]
      #   The method used to access this property. By default it is the property's `id`. Especially useful
      #   when the property's name conflicts with built-in Ruby object methods (like `hash` or `method`).
      def enum(id, choices:, default: nil, null: true, method_name: id)
        prop = EnumProperty.new(
          id,
          klass:,
          choices:,
          default:,
          null:,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop)

        prop
      end

      # def enums(id, choices:, default: nil, null: true)
      #   def_property ArrayProperty.new(
      #     id,
      #     default: default,
      #     null: null,
      #     klass: EnumProperty,
      #     # TODO: how to limit choices?
      #   )
      # end
    end
  end
end
