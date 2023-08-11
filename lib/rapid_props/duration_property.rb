# frozen_string_literal: true

require "active_support/duration"

module RapidProps
  # = Duration property definition
  #
  # Minimum usage:
  #
  #   properties do |p|
  #     p.duration :ttl
  #   end
  #
  # TODO: document options
  class DurationProperty < Property
    TYPE = "duration"

    REGEX = /\A([0-9\.]+)\ ([a-z]+)\Z/
    UNITS = %w[seconds minutes hours days months years].freeze

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when ActiveSupport::Duration
        raise InvalidPropertyError, value if value.parts.length > 1

        value
      when String
        self.class.parse_string(value)

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

    # :nodoc:
    module Builder
      def duration(id, default: nil, null: true, method_name: id)
        prop = DurationProperty.new(
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
    end

    class << self
      def parse_string(value)
        raise InvalidPropertyError, value unless REGEX =~ value

        amount = Regexp.last_match(1)
        unit = Regexp.last_match(2)
        unit = "#{unit}s" unless unit[unit.length - 1] == "s"
        raise InvalidPropertyError, value unless UNITS.include?(unit)

        amount = amount.include?(".") ? amount.to_f : amount.to_i
        ActiveSupport::Duration.send(unit, amount)
      end
    end
  end
end
