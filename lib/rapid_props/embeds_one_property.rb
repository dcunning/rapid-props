# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module RapidProps
  # Internal class used to define embeds_one properties
  class EmbedsOneProperty < Property
    TYPE = "embeds_one"

    attr_reader :child_class_name
    attr_reader :superclass
    attr_reader :polymorphic

    alias_method :polymorphic?, :polymorphic

    def initialize(id, polymorphic: false, child_class_name: nil, superclass: nil, **props)
      @polymorphic = polymorphic
      @child_class_name = child_class_name
      @superclass = superclass

      unless @polymorphic
        raise ArgumentError, "superclass only supported when polymorphic" if @superclass
        raise ArgumentError, "child_class_name required" unless @child_class_name
      end

      super(id, scalar: false, **props)
    end

    def parse(value, context: nil)
      case value
      when child_class, superclass
        value

      when true
        klass.new

      when false, nil
        nil

      when Hash
        parse_hash_value(value, context)

      else
        raise InvalidPropertyError, value
      end
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def serialize(value, context: nil)
      value.as_json.tap do |hash|
        hash.reverse_merge!("type" => value.class.name) if polymorphic?
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def strong_parameters
      { "#{id}_properties": child_class.properties.strong_parameters }
    end

    def as_json(options = {})
      super(options).reverse_merge("embedded" => child_class.properties.as_json(options))
    end

    def child_class
      return @child_class if defined?(@child_class)

      @child_class = define_child_class
    end

    def default_for(context)
      super || ((superclass || child_class).new(parent: context) if required?)
    end

    def valid_type?(value)
      value.nil? ||
        value.is_a?(Hash) ||
        (child_class && value.is_a?(child_class)) ||
        (superclass && value.is_a?(superclass))
    end

  private

    def ensure_superclass(klass)
      raise InvalidPropertyError, "expected #{@superclass} got #{klass}" unless klass <= @superclass
    end

    def define_child_class
      if child_class_name.is_a?(Proc)
        child_class_name.call
      elsif child_class_name.present?
        child_class_name.constantize
      end
    end

    def parse_hash_value(value, context)
      klass = child_class

      if polymorphic?
        klass = value[:type]&.constantize || child_class || superclass
        ensure_superclass(klass) if superclass
        value = value.except(:type)
      end

      value = value.merge(parent: context) if context
      value = value.deep_symbolize_keys

      klass.new(**value)
    end

    # :nodoc:
    module Builder
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/MethodLength

      # Embeds one property definition: nested hash.
      #
      # Minimum usage that automatically creates a child class:
      #
      #   properties do |p|
      #     p.embeds_one :author do |t|
      #       t.string :name
      #     end
      #   end
      #
      # === Options
      #
      # The declaration can also include an +options+ hash to specialize the behavior of the property
      #
      # Options are:
      # [:default]
      #   A hash of properties that pre-populate this association.
      # [:null]
      #   When explicitly +false+ this property will raise an error when setting the property to a +nil+
      #   or when the property value is not specified.
      # [:class_name]
      #   Specify the name of a predefined class this association must use.
      # [:polymorphic]
      #   Specify whether subclasses are supported.
      # [:superclass]
      #   Specify a required superclass for all instances of this association.
      # [:method_name]
      #   The method used to access this property. By default it is the property's `id`. Especially useful
      #   when the property's name conflicts with built-in Ruby object methods (like `hash` or `method`).
      def embeds_one(id,
                     default: nil,
                     null: true,
                     polymorphic: false,
                     class_name: nil,
                     superclass: nil,
                     method_name: id,
                     &block)
        klass.send(:include, InstanceMethods)

        raise ArgumentError, "you cannot use class_name with a new properties block" if class_name && block_given?

        prop = EmbedsOneProperty.new(
          id,
          klass:,
          child_class_name: class_name || (
            !polymorphic && define_child_class(id.to_s.camelize, superclass:, &block).name
          ),
          default:,
          null:,
          reader_name: method_name,
          polymorphic:,
          superclass: (superclass if polymorphic),
        )

        define_reader(prop)
        define_embeds_one_writer(prop)
        define_build_method(prop)

        define_method :"#{id}_properties" do
          read_embeds_one_property(id)
        end

        validation_method = :"validate_embeds_one_#{id}"
        validate(validation_method)
        define_method validation_method do
          validate_embeds_one_property(id)
        end

        add_property(prop)
        prop
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/ParameterLists

    private

      def define_child_class(class_name, superclass: nil, extends: [], &block)
        Class.new(superclass || EmbeddedChild).tap do |k|
          klass.const_set(class_name, k)

          extends.each { |m| k.extend(m) }
          block.call(k.def_properties) if block_given?
        end
      end

      def define_embeds_one_writer(property)
        define_method property.writer_name do |value|
          write_embeds_one_property(property.id, value)
        end
      end

      def define_build_method(prop)
        define_method :"build_#{prop.id}" do |properties = {}|
          build_embeds_one_property(prop.id, properties)
        end
      end
    end

    # :nodoc:
    module InstanceMethods
      def read_embeds_one_property(id)
        read_property(id)&.properties
      end

      def validate_embeds_one_property(id)
        child = read_property(id)
        return if child.nil? || child.valid?

        errors.add(id, :invalid)
      end

      # requires special code to support boolean values
      # which can specify whether the relationship exists.
      def write_embeds_one_property(id, value)
        value = nil if value == false
        value = {} if value == true

        property = self.class.find_property(id)
        raise TypeError, value unless property.valid_type?(value)

        existing = read_property(property.id)
        existing && value ? existing.properties = value : write_property(property.id, value)
      end

      def build_embeds_one_property(id, value)
        property = self.class.find_property(id)
        write_property(id, property.child_class.new(**value))
      end
    end
  end
end
