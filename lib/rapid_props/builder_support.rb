# frozen_string_literal: true

module RapidProps
  # Methods required by the individual property builders
  module BuilderSupport
    # class receiving sugar methods from the properties being built
    attr_reader :klass

    # schema defined
    attr_reader :schema

    def initialize(klass, schema: klass.properties)
      @schema = schema
      @klass = klass
      yield(self) if block_given?
    end

  private

    with_options to: :klass do
      delegate :alias_method
      delegate :define_method

      # https://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html
      delegate :validate
      delegate :validates
      delegate :validates!
      delegate :validates_each
      delegate :validates_with
      delegate :validators
      delegate :validators_on
      delegate :clear_validators!

      # https://api.rubyonrails.org/classes/ActiveModel/Validations/HelperMethods.html
      delegate :validates_absence_of
      delegate :validates_acceptance_of
      delegate :validates_comparison_of
      delegate :validates_confirmation_of
      delegate :validates_exclusion_of
      delegate :validates_format_of
      delegate :validates_inclusion_of
      delegate :validates_length_of
      delegate :validates_numericality_of
      delegate :validates_presence_of
      delegate :validates_size_of
    end

    def add_property(property, skip_validation: false)
      raise PropertyAlreadyExists, property.id if schema.key?(property.id)

      validates_presence_of(property.reader_name) if property.required? && !skip_validation

      schema[property.id] = property
    end

    def define_reader(property)
      if klass.instance_methods.include?(property.reader_name)
        raise MethodAlreadyExistsError, "#{property.reader_name} method exists"
      end

      define_method property.reader_name do
        read_property(property.id)
      end
    end

    def define_writer(property)
      define_method property.writer_name do |value|
        write_property(property.id, value)
      end
    end
  end
end
