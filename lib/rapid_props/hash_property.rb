# frozen_string_literal: true

module RapidProps
  # Internal class used to define hash properties (a set of unstructured key-value pairs)
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
      # Hash property definition: unstructured key-value pairs.
      #
      # Minimum usage that automatically creates a child class:
      #
      #   properties do |p|
      #     p.hash :environment_variables
      #   end
      #
      # === Options
      #
      # The declaration can also include an +options+ hash to specialize the behavior of the property
      #
      # Options are:
      # [:default]
      #   Specify the default value for this property. This argument will be passed into the +#parse+
      #   function and supports a +proc+ that calculates the default value given the parent object.
      # [:null]
      #   When explicitly +false+ this property will raise an error when setting the property to a +nil+
      #   or when the property value is not specified.
      # [:method_name]
      #   The method used to access this property. By default it is the property's `id`. Especially useful
      #   when the property's name conflicts with built-in Ruby object methods (like `hash` or `method`).
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

        define_method(name) do
          value = send(prop.reader_name)

          errors.add(prop.id, :blank) unless value
        end
      end
    end
  end
end
