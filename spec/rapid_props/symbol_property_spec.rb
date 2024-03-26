# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::SymbolProperty, type: :property do
  describe "parse" do
    it "allows strings" do
      expect(property.parse("foo")).to eql(:foo)
    end

    it "allows symbols" do
      expect(property.parse(:foo)).to eql(:foo)
    end

    it "raises an error when given a number" do
      expect{property.parse(1)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "serializes symbols" do
      expect(property.serialize(:foo)).to eql("foo")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.symbol(:name)
      expect(builder.klass.properties.keys).to match_array(%i[name])
    end

    it "defines a reader and a writer method" do
      builder.symbol(:name)
      expect{instance.name = "foo"}.to change{instance.name}.from(nil).to(:foo)
    end

    it "automatically validates presence of the property when null: false" do
      builder.symbol(:name, null: false)
      expect(instance.valid?).to eql(false)
      expect(instance.errors.details[:name]).to eql([{ error: :blank }])
    end
  end

  # describe "array of strings" do
  #   class self::Page
  #     include RapidProps::Container

  #     properties do |p|
  #       p.symbols :tags
  #     end
  #   end

  #   let(:klass) { self.class::Page }
  #   let(:property) { klass.find_property(:tags) }
  #   let(:tags) { %w[programming ruby-on-rails] }
  #   let(:itags) { %i[programming ruby-on-rails] }

  #   it "supports parsing" do
  #     expect(property.parse(tags)).to eql(itags)
  #   end

  #   it "accepts them in the constructor" do
  #     expect(klass.new(tags: tags).tags).to eql(itags)
  #   end

  #   it "doesn't define the attributes helper" do
  #     expect(klass.new.respond_to?(:tags_properties)).to be false
  #   end
  # end
end
