# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::DecimalProperty, type: :property do
  describe "parse" do
    it "allows floats" do
      expect(property.parse(3.14)).to eql(3.14)
    end

    it "allows integers" do
      expect(property.parse(10)).to eql(10)
    end

    it "casts strings to floats" do
      expect(property.parse("3.14")).to eql(3.14)
      expect(property.parse("-3.14")).to eql(-3.14)
      expect(property.parse("+3.14")).to eql(3.14)
    end

    it "raises an error when given an string that contains any non-numerics or decimals" do
      expect{property.parse("0-test")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a boolean" do
      expect{property.parse(true)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "serializes numbers" do
      expect(property.serialize(100)).to eql(100)
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.decimal(:amount)
      expect(builder.klass.properties.keys).to match_array(%i[amount])
    end

    it "defines a reader and a writer method" do
      builder.decimal(:amount)
      expect{instance.amount = 5.2}.to change{instance.amount}.from(nil).to(5.2)
    end
  end
end
