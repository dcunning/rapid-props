# frozen_string_literal: true

module RapidProps
  # Base class of a property definition.
  class Property
    TYPE = nil

    attr_reader :id
    attr_reader :klass
    attr_reader :required
    attr_reader :reader_name
    attr_reader :writer_name
    attr_reader :default
    attr_reader :scalar

    alias_method :required?, :required
    alias_method :scalar?, :scalar

    # TODO: support dynamic `null/required` value
    # rubocop:disable Metrics/ParameterLists
    def initialize(id,
                   klass: nil,
                   reader_name: nil,
                   writer_name: (:"#{reader_name}=" if reader_name),
                   default: nil,
                   null: true,
                   scalar: true)
      @id = id
      @klass = klass
      @default = default
      @required = !null
      @reader_name = reader_name if klass
      @writer_name = writer_name if klass
      @scalar = scalar
    end
    # rubocop:enable Metrics/ParameterLists

    def parse(value, context: nil)
      raise NotImplementedError
    end

    def serialize(value, context: nil)
      raise NotImplementedError
    end

    def dynamic?(value)
      value.is_a?(Proc) || value.is_a?(Symbol)
    end

    def default_for(context, default: detect_default_method(context) || @default)
      result = @default

      case default
      when NilClass
        nil
      when Proc
        result = default_for_proc(default, context)
        parse(result, context:)
      when Symbol
        result = context.send(default)
        parse(result, context:)
      else
        parse(default, context:)
      end
    rescue RapidProps::InvalidPropertyError => e
      return nil if result.nil?

      raise e
    end

    def strong_parameters
      id
    end

    def to_hash
      { type: self.class.type, id: }.tap do |h|
        if @default
          h[:default] = begin
            case @default
            when Proc
              { type: "proc" }
            when Symbol
              { type: "method" }
            else
              @default
            end
          end
        end

        h[:required] = true if required?
      end
    end

  private

    def detect_default_method(context)
      default_method = :"default_#{id}"

      default_method if context.respond_to?(default_method)
    end

    def default_for_proc(proc, context)
      args = proc.parameters.empty? ? [] : [context]
      proc.call(*args)
    end

    class << self
      def type
        const_get(:TYPE)
      end
    end
  end
end
