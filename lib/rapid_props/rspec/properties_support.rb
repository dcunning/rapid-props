# frozen_string_literal: true

module RapidProps
  module RSpec
    # Helps test Property subclasses in RSpec
    module PropertiesSupport
      def self.included(base)
        base.metadata[:type] = :property
        base.extend DSL
        base.send :include, Matchers

        base.around(:each) do |example|
          base.with_test_class(&example)
        end

        super
      end

      # :nodoc:
      module Matchers
        extend ::RSpec::Matchers::DSL

        def builder(klass = TestClass)
          RapidProps::Builder.new(klass)
        end

        def property(id = "test_property", **kargs)
          described_class.new(id, **kargs.reverse_merge(klass: TestClass))
        end
      end

      # :nodoc:
      module DSL
        def with_test_class(&block)
          klass = Class.new
          klass.send(:include, RapidProps::Container)
          RapidProps::RSpec.send(:const_set, :TestClass, klass)
          block.call
        ensure
          RapidProps::RSpec.send(:remove_const, :TestClass)
        end
      end
    end
  end
end
