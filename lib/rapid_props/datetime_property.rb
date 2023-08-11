# frozen_string_literal: true

module RapidProps
  # = DateTime property definition
  #
  # Minimum usage:
  #
  #   properties do |p|
  #     p.datetime :published_at
  #   end
  #
  # TODO: document options
  class DatetimeProperty < Property
    TYPE = "datetime"

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Time
        value
      when DateTime
        value.to_time
      when String
        parse_string(value)
      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      value.to_s
    end
    # rubocop:enable Lint/UnusedMethodArgument

  private

    def parse_string(value)
      raise InvalidPropertyError, value if DateProperty::REGEX =~ value

      base = (Time.zone if Time.respond_to?(:zone)) || Time
      begin
        base.parse(value)
      rescue ArgumentError
        raise InvalidPropertyError, value
      end
    end

    # :nodoc:
    module Builder
      def datetime(id, default: nil, null: true, method_name: id)
        prop = DatetimeProperty.new(
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
  end
end
