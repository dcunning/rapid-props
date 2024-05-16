# frozen_string_literal: true

require "active_support/duration"

module RapidProps
  # Internal class used to parse and serialize duration properties
  class DurationProperty < Property
    TYPE = "duration"

    REGEX = /\A([0-9\.\,]+)\ ([a-z]+)\Z/
    UNITS = %w[seconds minutes hours days months years].freeze

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when ActiveSupport::Duration
        raise InvalidPropertyError, value if value.parts.length > 1

        value.freeze
      when String
        self.class.parse_string(value).freeze

      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      value.parts.collect do |(unit, amount)|
        unit = unit.to_s
        unit = unit[0..unit.length - 2] if amount == 1
        "#{amount} #{unit}"
      end.join(" and ")
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # Defines duration properties
    module Builder
      # Duration property definition
      #
      # === Valid values
      #
      # Values not listed below will raise an RapidProps::InvalidPropertyError error.
      #
      #   # valid values:
      #   # any instance of ActiveSupport::Duration with more than one part
      #   ["10 seconds", "1.4 minutes", "400 hours", "1 day", "5 months", "2,000 years"]
      #
      #   # invalid values:
      #   ["10 parsecs", "1"]
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
      def duration(id, default: nil, null: true, method_name: id)
        prop = DurationProperty.new(
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

    class << self
      def parse_string(value)
        raise InvalidPropertyError, value unless REGEX =~ value

        amount = Regexp.last_match(1).remove(",")
        unit = Regexp.last_match(2)
        unit = "#{unit}s" unless unit[unit.length - 1] == "s"
        raise InvalidPropertyError, value unless UNITS.include?(unit)

        amount = amount.include?(".") ? amount.to_f : amount.to_i
        ActiveSupport::Duration.send(unit, amount)
      end
    end
  end
end
