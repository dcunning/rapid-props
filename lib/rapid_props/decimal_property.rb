# frozen_string_literal: true

module RapidProps
  # = Decimal property definition
  #
  # Minimum usage:
  #
  #   properties do |p|
  #     p.decimal :price_cents
  #   end
  #
  # TODO: document options
  class DecimalProperty < Property
    TYPE = "decimal"

    REGEX = /\A[-+]?\d+(\.\d+)?\Z/

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Numeric
        value
      when String
        raise InvalidPropertyError, value unless REGEX =~ value

        value.to_f
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
      # TODO: precision and scale
      def decimal(id, default: nil, null: true, method_name: id)
        prop = DecimalProperty.new(
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
