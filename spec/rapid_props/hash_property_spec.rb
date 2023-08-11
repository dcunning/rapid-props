# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::HashProperty, type: :property do
  describe "parse" do
    it "parses Hash objects" do
      expect(property.parse({ foo: "bar" })).to eql(foo: "bar")
    end

    it "raises an error when given an array" do
      expect{property.parse([])}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "just serializes as a hash" do
      expect(property.serialize({ foo: "bar" })).to eql(foo: "bar")
    end
  end

  describe "builder" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.hash(:settings)
      expect(builder.klass.properties.keys).to match_array(%i[settings])
    end

    it "automatically validates presence of the property when null: false" do
      builder.hash(:settings, null: false)
      expect(instance.valid?).to eql(false)
      expect(instance.errors.details[:settings]).to eql([{ error: :blank }])
    end

    it "knows that an empty hash is a present value" do
      builder.hash(:settings, null: false)
      instance.settings = {}
      expect(instance.valid?).to eql(true)
    end
  end
end
