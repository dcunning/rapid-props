# frozen_string_literal: true

module RapidProps
  class EnumProperty < Property
    class UnknownEnumError < InvalidPropertyError; end

    TYPE = "enum"

    attr_reader :choices

    def initialize(id, options = {})
      @choices = options.delete(:choices)
      super(id, **options)

      raise ArgumentError, "choices required" unless @choices
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def parse(value, context: nil)
      raise(UnknownEnumError, value) unless @choices.include?(value)

      value
    end

    def serialize(value, context: nil)
      value
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def to_hash
      super.merge(choices: @choices)
    end

    # :nodoc:
    module Builder
      def enum(id, choices:, default: nil, null: true, method_name: id)
        prop = EnumProperty.new(
          id,
          klass:,
          choices:,
          default:,
          null:,
          reader_name: method_name,
        )

        define_reader(prop)
        define_writer(prop)
        add_property(prop)

        prop
      end

      # def enums(id, choices:, default: nil, null: true)
      #   def_property ArrayProperty.new(
      #     id,
      #     default: default,
      #     null: null,
      #     klass: EnumProperty,
      #     # TODO: how to limit choices?
      #   )
      # end
    end
  end
end
