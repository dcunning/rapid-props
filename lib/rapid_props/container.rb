# frozen_string_literal: true

module RapidProps
  module Container
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include ActiveModel::Validations

        delegate :as_json, to: :properties

        # HACK: goes here to override the errors method
        # added by ActiveModel::Validations
        def errors
          @errors ||= Errors.new(self)
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

      value = property.parse(value, context: self) unless value.nil?

      @properties ||= {}
      @properties[key] = value
    end

    def flat_errors
      @flat_errors ||= FlatErrors.new(self)
    end

    def to_hash
      properties.transform_values do |value|
        value.respond_to?(:to_hash) ? value.to_hash : value
      end
    end

    def inspect
      # defaults can cause `SystemStackError` depending on what they access
      # so let's just skip them.
      %(#<#{self.class.name} properties=#{properties(skip_defaults: true)}>)
    end

    # :nodoc:
    class FlatErrors
      def initialize(container)
        @container = container
      end

      def details
        root = @container.errors.details.deep_dup
        flatten_details(@container, root)
        root
      end

      # TODO: implement this too
      # def full_messages
      # end

    private

      def flatten_details(parent, details)
        details.to_a.each do |(attr, errors)|
          next unless errors.include?(error: :invalid)

          child_details = flatten_child(parent, attr)
          next unless child_details&.any?

          errors.delete(error: :invalid)
          details.delete(attr) if details[attr].empty?

          details.merge!(child_details)
        end
        details
      end

      def flatten_child(parent, attr)
        child = parent.send(attr) if parent.respond_to?(attr)

        if child.is_a?(Array)
          h = {}
          child.each_with_index do |c, i|
            flatten_child_details(c, "#{attr}[#{i}]", h)
          end
          h
        else
          flatten_child_details(child, attr, {})
        end
      end

      def flatten_child_details(child, attr, hash)
        errors = child.errors if child.respond_to?(:errors)
        details = errors.details.deep_dup if errors.respond_to?(:details)
        return unless details

        flatten_details(child, details).each do |k, v|
          hash[:"#{attr}.#{k}"] = v
        end
        hash
      end
    end

    # :nodoc:
    class Errors < ActiveModel::Errors
      attr_accessor :base_path

      def full_messages_with_paths
        gather(@base, base_path || default_base_path)
      end

    private

      def default_base_path
        path = @base.class.name.split("::").last.underscore
        path = "app" if path == "base"
        path
      end

      def gather(obj, path)
        messages = []
        obj.errors.details.each do |attr, errors|
          errors.each do |error|
            messages += gather_error(obj, "#{path}.#{attr}", attr, error)
          end
        end
        messages
      end

      def gather_error(obj, path, attr, error)
        type = error[:error]
        child = obj.send(attr) if type == :invalid

        case child
        when Array
          messages = []
          child.each_with_index do |c2, i|
            messages += gather(c2, append_array_path(child, c2, path, i))
          end
          messages
        when NilClass
          verb = obj.errors.generate_message(attr, error[:error], error.except(:error))
          ["#{path} #{verb}"]
        else
          gather(child, path)
        end
      end

      def append_array_path(array, item, path, index)
        property = array.property if array.respond_to?(:property)
        key = property&.key
        value = item.read_property(key) if key && item.respond_to?(:read_property)

        if value
          "#{path}[#{value}]"
        else
          "#{path}[#{index}]"
        end
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
        Builder.new(self, properties, &)
      end

      def find_property(id)
        properties.find(id)
      end

      def property?(id)
        properties[id].present?
      end

      def change_property_default(property_id, value)
        find_property(property_id) # ensure it's valid

        define_method :"default_#{property_id}" do
          value
        end
      end
    end
  end
end
