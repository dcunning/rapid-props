# frozen_string_literal: true

module RapidProps
  # This is the base module for a class that contains properties.
  module Container
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include ActiveModel::Validations

        delegate :as_json, to: :properties

        validate :validates_property_values

        # HACK: goes here to override the errors method
        # added by ActiveModel::Validations
        def errors
          @errors ||= ActiveModel::Errors.new(self)
        end
      end
    end

    def initialize(properties = {})
      self.properties = properties
    end

    def eql?(other)
      other.instance_of?(self.class) && properties.eql?(other.properties)
    end

    def properties(skip_defaults: false)
      self.class.properties.each_with_object({}) do |property, h|
        key = property.id

        if !skip_defaults
          h[key] = read_property(key)
        elsif @properties&.key?(key)
          h[key] = @properties[key]
        end
      end
    end

    def properties=(properties)
      raise ArgumentError, "properties cannot be nil" unless properties

      properties.each do |key, value|
        writer = "#{key}="
        if respond_to?(writer)
          send(writer, value)
        else
          write_property(key, value)
        end
      end
    end

    def property?(key)
      self.class.property?(key)
    end

    def read_property(key)
      key = key.to_sym
      return @properties[key] if @properties&.key?(key)

      property = self.class.find_property(key)

      @properties ||= {}
      @properties[key] = property.default_for(self)
    end

    def write_property(key, value)
      key = key.to_sym
      property = self.class.find_property(key)
      @properties ||= {}

      value = property.parse(value, context: self) unless value.nil?
      @properties[key] = value
    rescue RapidProps::InvalidPropertyError => e
      raise e unless allow_writing_invalid_properties?

      @invalid_properties ||= {}
      @invalid_properties[key] = { error: e.to_sym }

      @properties[key] = value
    end

    def default_property_for(key, default: nil)
      property = self.class.find_property(key)
      property.default_for(self, default:)
    end

    def flat_errors
      @flat_errors ||= FlatErrors.new(self)
    end

    def to_hash
      properties.transform_values do |value|
        value.respond_to?(:to_hash) ? value.to_hash : value
      end
    end

    def allow_writing_invalid_properties?
      self.class.allow_writing_invalid_properties?
    end

    def inspect
      # defaults can cause `SystemStackError` depending on what they access
      # so let's just skip them.
      %(#<#{self.class.name} properties=#{properties(skip_defaults: true)}>)
    end

  private

    def validates_property_values
      @invalid_properties&.each do |key, value|
        errors.add(key, value[:error], **value.except(:error))
      end
    end

    def reset_invalid_properties
      @invalid_properties = nil
    end

    # Allows accessing individual errors on nested relationships
    # instead of just seeing the parent relationship as +:invalid+
    class FlatErrors
      EMPTY_ARRAY = [].freeze # :nodoc:

      def initialize(container)
        @container = container
      end

      def details
        flat = {}
        flat.default = EMPTY_ARRAY

        each_error do |error, path|
          key = flatten_path_for_details(path)

          flat[key] = [] if flat[key] == EMPTY_ARRAY
          flat[key] << error.details
        end
        flat
      end

      def full_messages
        messages = []

        each_error do |error, path|
          messages << flatten_for_message(error, path)
        end

        messages
      end

    private

      def each_error(container = @container, path = [], &)
        container.errors.each do |error|
          yield error, path + [error.attribute] if flat_error?(container, error)
        end

        container.class.properties.each do |property|
          each_property_error(property, container, path, &) unless property.scalar?
        end
      end

      def each_property_error(property, container, path, &)
        type = property.class.name.demodulize.underscore
        method_name = :"each_#{type}_error"

        send(method_name, property, container, path, &) if respond_to?(method_name, true)
      end

      def each_embeds_many_property_error(property, container, path, &)
        container.read_property(property.id).each_with_index do |child, i|
          key = property.key
          suffix = (child.read_property(key) if key) || i

          each_error(child, path + [:"#{property.id}[#{suffix}]"], &)
        end
      end

      def each_embeds_one_property_error(property, container, path, &)
        child = container.read_property(property.id)
        each_error(child, path + [property.id], &) if child
      end

      def flat_error?(container, error)
        return true unless error.type == :invalid

        property = container.class.properties[error.attribute]
        !container_property?(property)
      end

      def container_property?(property)
        property.is_a?(EmbedsManyProperty) || property.is_a?(EmbedsOneProperty)
      end

      def flatten_path_for_details(path)
        path.join(".").to_sym
      end

      def flatten_for_message(error, path)
        noun = flatten_path_for_details(path)
        error.class.full_message(noun, error.message, error.base)
      end
    end

    # :nodoc:
    module ClassMethods
      def properties(&)
        @properties ||= Schema.new(self)
        def_properties(&) if block_given?
        @properties
      end

      def def_properties(&)
        Builder.new(self, schema: properties, &)
      end

      def find_property(id)
        properties.find(id)
      end

      def property?(id)
        properties[id].present?
      end

      def change_property_default(property_id, default)
        property = find_property(property_id)

        # raise an error if value is invalid
        # (unless it's dynamic in which we can't know that yet)
        property.parse(default) unless property.dynamic?(default)

        define_method :"default_#{property_id}" do
          default_property_for(property_id, default:)
        end
      end

      def allow_writing_invalid_properties?
        properties.allow_writing_invalid_properties?
      end

      def allow_writing_invalid_properties=(val)
        properties.allow_writing_invalid_properties = val
      end
    end
  end
end
