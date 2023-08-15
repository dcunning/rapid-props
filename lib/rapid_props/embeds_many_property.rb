# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module RapidProps
  # Internal class used to define embeds_many properties
  class EmbedsManyProperty < Property
    TYPE = "embeds_many"

    attr_reader :key
    attr_reader :child_property
    attr_reader :polymorphic
    attr_reader :scalar

    alias_method :polymorphic?, :polymorphic
    alias_method :scalar?, :scalar

    with_options to: :@child_property do
      delegate :child_class
    end

    # rubocop:disable Metrics/ParameterLists
    def initialize(id, child_property:, key: nil, polymorphic: false, scalar: false, **props)
      @key = key
      @polymorphic = polymorphic
      @child_property = child_property
      @scalar = scalar

      super(id, **props)
    end
    # rubocop:enable Metrics/ParameterLists

    def parse(value, context: nil)
      case value
      when Array
        array = value.collect do |v|
          child_property.parse(v, context:)
        end
        spawn_collection(array, context)

      when Hash
        raise InvalidPropertyError, "expected Array, received Hash" unless key

        array = value.collect do |(k, v)|
          raise InvalidPropertyError, "expected Hash, got #{v.class}" unless v.is_a?(Hash)

          child_property.parse(v.merge(key => k), context:)
        end
        spawn_collection(array, context)

      else
        raise InvalidPropertyError, value
      end
    end

    def serialize(value, context: nil)
      value.collect do |v|
        child_property.serialize(v, context:)
      end
    end

    def strong_parameters
      key = scalar? ? id : :"#{id}_properties"
      { key => child_class.properties.strong_parameters }
    end

    def as_json(options = {})
      super(options).reverse_merge("embedded" => child_class.properties.as_json(options))
    end

    def default_for(context)
      Collection.new(self, context, super || [])
    end

  private

    def spawn_collection(array, context)
      Collection.new(self, context, array)
    end

    # :nodoc:
    class Collection < Array
      attr_reader :parent
      attr_reader :property

      def initialize(property, parent, *args)
        super(*args)
        @property = property
        @parent = parent
      end

      def <<(*args)
        raise ArgumentError, args unless args.length == 1 && allowed_instance?(args[0])

        super(args[0])
      end

      def unshift(*args)
        items = args.collect do |arg|
          allowed_instance?(arg) ? arg : @property.child_class.new(**arg.merge(parent: @parent))
        end

        super(*items)
      end

      def new(properties = {})
        item = @property.child_class.new(**properties.merge(parent: @parent))
        self << item
        item
      end
      alias_method :build, :new
      alias_method :create, :new
      alias_method :create!, :new

      def [](key)
        if key.is_a?(Integer)
          super
        else
          raise NotImplementedError if !@property.key || block_given?

          # OPTIMIZE
          find { |elem| elem.send(@property.key) == key }
        end
      end

      def find(key = nil)
        return self[key] || raise(KeyNotFoundError, key) unless key.nil? && block_given?

        super
      end

      def key?(key)
        raise NotImplementedError unless @property.key

        self[key].present?
      end

      def method_missing(method_id, *args)
        super if args.any? || block_given?

        if method_id =~ /\A(.+)\?\Z/
          key?(Regexp.last_match(1))
        else
          find(method_id.to_s) || super
        end
      end

      def respond_to_missing?(method_id, _include_private = false)
        method_id =~ /\A(.+)\?\Z/ || key?(method_id.to_s)
      end

    private

      def allowed_instance?(object)
        object.is_a?(@property.child_class)
      end
    end

    # :nodoc:
    module Builder
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/ParameterLists

      # Embeds many property definition: nested arrays.
      #
      # Minimum usage that automatically creates a child class:
      #
      #   properties do |p|
      #     p.embeds_many :tags do |t|
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
      #   An array of property hashes that pre-populate this association.
      # [:key]
      #   Specify a property of the child class with unique values that will drive an optimized `#find` method
      #   on the association.
      # [:class_name]
      #   Specify the name of a predefined class this association must use.
      # [:polymorphic]
      #   Specify whether subclasses are supported.
      # [:superclass]
      #   Specify a required superclass for all instances of this association.
      # [:scalar]
      #   If `true`, instances of this association don't have their own properties: they are just a value
      #   onto themselves (like a `String` or `Integer`).
      # [:method_name]
      #   The method used to access this property. By default it is the property's `id`. Especially useful
      #   when the property's name conflicts with built-in Ruby object methods (like `hash` or `method`).
      def embeds_many(id,
                      default: nil,
                      null: true,
                      key: nil,
                      class_name: nil,
                      polymorphic: false,
                      superclass: nil,
                      scalar: false,
                      method_name: id,
                      &block)
        klass.send(:include, InstanceMethods)

        raise ArgumentError, "you cannot use class_name with a new properties block" if class_name && block_given?

        prop = EmbedsManyProperty.new(
          id,
          klass:,
          default:,
          null:,
          reader_name: method_name,

          key:,
          polymorphic:,
          scalar:,
          child_property: EmbedsOneProperty.new(
            id,
            klass:,
            polymorphic:,
            superclass:,
            child_class_name: class_name || define_child_class(id.to_s.camelize.singularize, superclass:, &block).name,
          ),
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop, skip_validation: true)

        unless scalar
          define_method :"#{prop.reader_name}_properties" do
            read_property(id)&.map(&:properties)
          end

          validation_method = :"validate_embeds_many_#{prop.reader_name}"
          validate(validation_method)
          define_method(validation_method) do
            validate_embeds_many(id)
          end
        end

        prop
      end
      # rubocop:enable Metrics/ParameterLists
      # rubocop:enable Metrics/MethodLength
    end

    # :nodoc:
    module InstanceMethods
      def validate_embeds_many(id)
        send(id).each do |child|
          next if child.valid?

          errors.add(id, :invalid)
        end
      end
    end
  end
end
