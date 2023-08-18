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
        klass.send(:include, InstanceMethods)

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

        validate_required_hash_property(prop) if prop.required?

        prop
      end

    private

      def validate_required_hash_property(prop)
        name = :"validates_presence_of_#{prop.reader_name}"

        define_method name do
          validates_presence_of_hash_property(prop.id)
        end

        validate name
      end
    end

    # :nodoc:
    module InstanceMethods
      def validates_presence_of_hash_property(id)
        property = self.class.find_property(id)
        value = send(property.reader_name)

        errors.add(property.id, :blank) unless value
      end
    end
  end
end
