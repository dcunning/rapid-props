# frozen_string_literal: true

module RapidProps
  # Internal class used to parse and serialize boolean properties
  class BooleanProperty < Property
    TYPE = "boolean"

    # based off of active_model/type/boolean.rb
    RECOGNIZED_STRINGS = {
      "0" => false,
      "f" => false,
      "F" => false,
      "false" => false,
      "FALSE" => false,
      "off" => false,
      "OFF" => false,
      false => false,
      0 => false,

      "1" => true,
      "t" => true,
      "T" => true,
      "true" => true,
      "on" => true,
      "ON" => true,
      true => true,
      1 => true,
    }.freeze

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when FalseClass, TrueClass
        value
      when String, Integer
        self.class.parse(value.to_s)
      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      value
    end
    # rubocop:enable Lint/UnusedMethodArgument

    # Defines boolean properties
    module Builder
      # Defines a boolean property
      #
      # === Valid values
      #
      # Values not listed below will raise an RapidProps::InvalidPropertyError error.
      #
      #   # true values
      #   [true, 1, "1", "t", "T", "true", "on", "ON"]
      #
      #   # false values
      #   [false, 0, "0", "f", "F", "false", "FALSE", "off", "OFF"]
      #
      # === Options
      #
      # The declaration can also include an +options+ hash to specialize the behavior of the property
      # [:default]
      #   Specify the default value for this property. This argument will be passed into the +#parse+
      #   function and supports a +proc+ that calculates the default value given the parent object.
      # [:null]
      #   When explicitly +false+ this property will raise an error when setting the property to a +nil+
      #   or when the property value is not specified.
      # [:method_name]
      #   The method used to access this property. By default it is the property's +id+. Especially useful
      #   when the property's name conflicts with built-in Ruby object methods (like +hash+ or +method+).
      def boolean(id, default: nil, null: true, method_name: id)
        prop = BooleanProperty.new(
          id,
          klass:,
          default:,
          null:,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop, skip_validation: true)

        alias_method "#{prop.reader_name}?", prop.reader_name

        if prop.required?
          # https://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html#method-i-validates_presence_of
          validates_inclusion_of prop.reader_name, in: [true, false]
        end

        prop
      end
    end

    class << self
      def parse(obj)
        bool = RECOGNIZED_STRINGS[obj]
        raise InvalidPropertyError, obj if bool.nil?

        bool
      end
    end
  end
end
