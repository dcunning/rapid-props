# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module RapidProps
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

      super(id, **props)
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
      def embeds_one(id,
                     default: nil,
                     null: true,
                     polymorphic: false,
                     class_name: nil,
                     superclass: nil,
                     method_name: id,
                     &block)
        klass.send(:include, InstanceMethods)

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

        klass.define_method :"#{id}_properties" do
          read_property(id)&.properties
        end

        validation_method = :"validate_embeds_one_#{id}"
        klass.validate(validation_method)
        klass.define_method(validation_method) do
          validate_embeds_one(id)
        end

        add_property(prop)
        prop
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/ParameterLists

    private

      def define_embeds_one_writer(property)
        klass.define_method(property.writer_name) do |value|
          value = nil if value == false
          value = {} if value == true

          raise TypeError, value unless property.valid_type?(value)

          existing = read_property(property.id)
          existing && value ? existing.properties = value : write_property(property.id, value)
        end
      end

      def define_child_class(class_name, superclass: nil, extends: [], &block)
        Class.new(superclass || EmbeddedChild).tap do |k|
          klass.const_set(class_name, k)

          extends.each { |m| k.extend(m) }
          block.call(k.def_properties) if block_given?
        end
      end

      def define_build_method(prop)
        prop.klass.define_method :"build_#{prop.id}" do |properties = {}|
          write_property(prop.id, prop.child_class.new(**properties))
        end
      end
    end

    # :nodoc:
    module InstanceMethods
      def validate_embeds_one(id)
        child = read_property(id)
        return if child.nil? || child.valid?

        errors.add(id, :invalid)
      end
    end
  end
end
