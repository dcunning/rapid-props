# frozen_string_literal: true

module RapidProps
  # A set of property definitions.
  class Schema
    attr_reader :klass
    attr_writer :allow_writing_invalid_properties

    with_options to: :@delegate do
      delegate :[]
      delegate :all?
      delegate :count
      delegate :key?
      delegate :length
      delegate :size
      delegate :values
    end

    with_options to: :values do
      delegate :as_json
      delegate :each
      delegate :each_with_object
      delegate :filter
      delegate :map
      delegate :select
    end

    def initialize(klass)
      @klass = klass
      @delegate = HashWithIndifferentAccess.new

      @parent = @klass.superclass.properties if @klass.superclass.respond_to?(:properties)
      @parent = nil unless @parent.is_a?(self.class)

      # TODO: remove properties for subclasses when they are
      # removed from the super class
      @delegate.merge!(@parent.to_hash) if @parent
    end

    def []=(id, property)
      unless id.is_a?(Symbol) || id.is_a?(String)
        raise ArgumentError, "expected String or Symbol, got #{id.class.inspect}"
      end

      @delegate[id] = property
    end

    def find(id)
      self[id] || raise(UnknownPropertyError, [id, klass])
    end

    def keys
      @delegate.keys.uniq.map(&:to_sym)
    end

    def except_unknown(hash)
      hash.keys.each_with_object({}) do |key, result|
        value = hash[key]
        prop = self[key]

        result[key] = prop.except_unknown_value(value) if prop
      end
    end
    alias_method :slice_known, :except_unknown

    def strong_parameters
      arr = []
      hash = {}

      each do |property|
        p = property.strong_parameters

        if p.is_a?(Symbol)
          arr << p
        elsif p
          hash.merge!(p)
        end
      end

      arr << hash if hash.any?
      arr
    end

    def allow_writing_invalid_properties?
      if @allow_writing_invalid_properties.nil? && @parent
        @parent.allow_writing_invalid_properties?
      else
        @allow_writing_invalid_properties
      end
    end

    def to_hash
      @delegate.clone
    end
  end
end
