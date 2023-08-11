# frozen_string_literal: true

module RapidProps
  # = Date property definition
  #
  # Minimum usage:
  #
  #   properties do |p|
  #     p.date :birthday
  #   end
  #
  # TODO: document options
  class DateProperty < Property
    TYPE = "date"

    REGEX = /\A\d{4}-\d{2}-\d{2}\Z/

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Date
        value
      when String
        raise InvalidPropertyError, value unless REGEX =~ value

        begin
          Date.parse(value)
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

    # :nodoc:
    module Builder
      def date(id, default: nil, null: true, method_name: id)
        prop = DateProperty.new(
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
