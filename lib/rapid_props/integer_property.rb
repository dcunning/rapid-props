# frozen_string_literal: true

module RapidProps
  class IntegerProperty < Property
    TYPE = "string"

    REGEX = /\A[-+]?\d+\Z/

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Integer
        value
      when String
        raise InvalidPropertyError, value unless REGEX =~ value

        value.to_i
      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      value
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # :nodoc:
    module Builder
      def integer(id, default: nil, null: true, method_name: id)
        prop = IntegerProperty.new(
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
