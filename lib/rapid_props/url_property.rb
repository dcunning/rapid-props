# frozen_string_literal: true

require "uri"

module RapidProps
  class UrlProperty < Property
    TYPE = "url"

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when URI::Generic
        value
      when String
        URI(value)
      else
        raise InvalidPropertyError, value
      end
    rescue URI::InvalidURIError
      raise InvalidPropertyError, value
    end

    def serialize(value, context: nil)
      value.to_s
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # :nodoc:
    module Builder
      def url(id, default: nil, null: true, method_name: id)
        prop = UrlProperty.new(
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

      # def urls(id, default: nil, null: true)
      #   @properties[id] = ArrayProperty.new(
      #     UrlProperty.new(
      #       id,
      #       default: default,
      #     ),
      #     null: null,
      #   )
      # end
    end
  end
end
