# frozen_string_literal: true

module RapidProps
  class HashProperty < Property
    TYPE = "hash"

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Hash
        value
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
      def hash(id, default: nil, null: true, method_name: id)
        prop = HashProperty.new(
          id,
          klass:,
          default:,
          null:,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop, skip_validation: true)

        if prop.required?
          m = define_required_hash_method(prop)
          klass.validate(m)
        end

        prop
      end

    private

      def define_required_hash_method(prop)
        name = :"validates_presence_of_#{prop.reader_name}"

        klass.define_method(name) do
          value = send(prop.reader_name)

          errors.add(prop.id, :blank) unless value
        end
      end
    end
  end
end
