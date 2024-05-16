# frozen_string_literal: true

module RapidProps
  # Internal class used to parse and serialize date properties
  class DateProperty < Property
    TYPE = "date"

    REGEX = /\A\d{4}-\d{2}-\d{2}\Z/

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Date
        value.freeze
      when String
        raise InvalidPropertyError, value unless REGEX =~ value

        begin
          Date.parse(value).freeze
        rescue ArgumentError
          raise InvalidPropertyError, value
        end
      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      value.to_s
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # Defines date properties
    module Builder
      # Date property definition
      #
      # === Valid values
      #
      # Values not listed below will raise an RapidProps::InvalidPropertyError error.
      #
      #   # valid values
      #   ["2023-08-12", Date.new("2023-08-12")]
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
      def date(id, default: nil, null: true, method_name: id)
        prop = DateProperty.new(
          id,
          klass: klass,
          default: default,
          null: null,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop)

        prop
      end
    end
  end
end
