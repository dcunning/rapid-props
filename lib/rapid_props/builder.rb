# frozen_string_literal: true

module RapidProps
  class Builder
    include BooleanProperty::Builder
    include DateProperty::Builder
    include DatetimeProperty::Builder
    include DecimalProperty::Builder
    include DurationProperty::Builder
    include EmbedsManyProperty::Builder
    include EmbedsOneProperty::Builder
    include EnumProperty::Builder
    include HashProperty::Builder
    include IntegerProperty::Builder
    include StringProperty::Builder
    include UrlProperty::Builder

    attr_reader :klass
    attr_reader :properties

    def initialize(klass, properties)
      @klass = klass
      @properties = properties
      yield(self) if block_given?
    end

    def add_property(property, skip_validation: false)
      raise PropertyAlreadyExists, property.id if properties.key?(property.id)

      klass.validates_presence_of(property.reader_name) if property.required? && !skip_validation

      properties[property.id] = property
    end

    def define_reader(property)
      if klass.instance_methods.include?(property.reader_name)
        raise MethodAlreadyExistsError, "#{property.reader_name} method exists"
      end

      klass.define_method(property.reader_name) do
        read_property(property.id)
      end
    end

    def define_writer(property)
      klass.define_method(property.writer_name) do |value|
        write_property(property.id, value)
      end
    end
  end
end
