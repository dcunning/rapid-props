# frozen_string_literal: true

module RapidProps
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

      def strings(id, default: nil, null: true)
        embeds_many(id, default:, null:, class_name: "String", scalar: true)
      end
    end
  end
end
