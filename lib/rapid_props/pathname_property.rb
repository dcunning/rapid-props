# frozen_string_literal: true

module RapidProps
  # Internal class used to parse and serialize string properties
  class PathnameProperty < Property
    TYPE = "pathname"

    attr_reader :prepended_slash
    attr_reader :appended_slash

    alias_method :prepended_slash?, :prepended_slash
    alias_method :appended_slash?, :appended_slash

    def initialize(id, prepended_slash: nil, appended_slash: nil, **kargs)
      if ![true, false, nil].include?(prepended_slash)
        raise ArgumentError, "prepended_slash: #{prepended_slash.inspect}"
      elsif ![true, false, nil].include?(appended_slash)
        raise ArgumentError, "appended_slash: #{appended_slash.inspect}"
      end

      @prepended_slash = prepended_slash
      @appended_slash = appended_slash

      super(id, **kargs)
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      case value
      when Pathname, Numeric, Symbol, String
        parse_value(value).freeze
      else
        raise InvalidPropertyError, "#{value.inspect} (#{value.class})"
      end
    end

    def serialize(value, context: nil)
      value.to_s
    end
    # rubocop:enable Lint/UnusedMethodArgument

  private

    def parse_value(value)
      value = value.to_s.strip

      if prepended_slash == true && value.slice(0) != "/"
        value = "/#{value}"
      elsif prepended_slash == false && value.slice(0) == "/"
        value = value[1..]
      end

      if appended_slash == true && value.slice(-1) != "/"
        value = "#{value}/"
      elsif appended_slash == false && value.slice(-1) == "/"
        value = value[0..-2]
      end

      Pathname.new(value)
    end

    # :nodoc:
    module Builder
      # Pathname property definition
      #
      # === Valid values
      #
      # Values not listed below will raise an RapidProps::InvalidPropertyError error.
      #
      #   # valid values:
      #   # any instance of String, Numeric, Symbol, or Pathname
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
      def pathname(id, prepended_slash: nil, appended_slash: nil, default: nil, null: true, method_name: id)
        prop = PathnameProperty.new(
          id,
          klass:,
          default:,
          null:,
          prepended_slash:,
          appended_slash:,
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
