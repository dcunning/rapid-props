# frozen_string_literal: true

module RapidProps
  # Internal class used to parse and serialize string properties
  class StringProperty < Property
    TYPE = "string"

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when String
        value
      when Numeric, Symbol, Pathname
        value.to_s
      else
        raise InvalidPropertyError, "#{value.inspect} (#{value.class})"
      end
    end

    def serialize(value, context: nil)
      value
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # :nodoc:
    module Builder
      # String property definition
      #
      # === Valid values
      #
      # Values not listed below will raise an RapidProps::InvalidPropertyError error.
      #
      #   # valid values:
      #   # any instance of String, Numeric, Symbol, or Pathname
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
      def string(id, default: nil, null: true, method_name: id)
        prop = StringProperty.new(
          id,
          klass:,
          default:,
          null:,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop)

        prop
      end

      # Defines an array of strings
      #
      # Minimum usage that automatically creates a child class:
      #
      #   properties do |p|
      #     p.strings :tags
      #   end
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
      def strings(id, default: nil, null: true)
        embeds_many(id, default:, null:, class_name: "String", scalar: true)
      end
    end
  end
end
