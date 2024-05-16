# frozen_string_literal: true

module RapidProps
  # Internal class used to parse and serialize decimal properties
  class DecimalProperty < Property
    TYPE = "decimal"

    REGEX = /\A[-+]?\d+(\.\d+)?\Z/

    with_options to: :@active_model_type do
      delegate :precision
      delegate :scale
    end

    def initialize(id, precision: nil, scale: nil, **props)
      super(id, **props)

      @active_model_type = ActiveModel::Type::Decimal.new(precision: precision, scale: scale)
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Numeric
        @active_model_type.cast(value)
      when String
        raise InvalidPropertyError, value unless REGEX =~ value

        @active_model_type.cast(value)
      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      case value
      when Numeric
        return value unless scale

        int = value.to_i
        fraction = format("%0.#{scale}f", value - int)
        "#{int}.#{fraction[2..]}"
      else
        value
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # Defines decimal properties
    module Builder
      # rubocop:disable Metrics/ParameterLists

      # Decimal property definition
      #
      # === Valid values
      #
      # Values not listed below will raise an RapidProps::InvalidPropertyError error.
      #
      #   # valid values:
      #   # any instance of Numeric
      #   ["10", "10.0", "-10.0", "+10.0"]
      #
      #   # invalid values:
      #   [".0", "+.0", ".0.0"]
      #
      # === Options
      #
      # The declaration can also include an +options+ hash to specialize the behavior of the property
      # [:default]
      #   Specify the default value for this property. This argument will be passed into the +#parse+
      #   function and supports a +proc+ that calculates the default value given the parent object.
      # [:null]
      #   When explicitly +false+ this property will raise an error when setting the property to a +nil+
      #   or when the property value is not specified.
      # [:method_name]
      #   The method used to access this property. By default it is the property's +id+. Especially useful
      #   when the property's name conflicts with built-in Ruby object methods (like +hash+ or +method+).
      def decimal(id, default: nil, null: true, precision: nil, scale: nil, method_name: id)
        prop = DecimalProperty.new(
          id,
          klass: klass,
          default: default,
          null: null,
          precision: precision,
          scale: scale,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop)

        prop
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
