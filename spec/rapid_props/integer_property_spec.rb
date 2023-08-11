# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::IntegerProperty, type: :property do
  describe "parse" do
    it "allows integer values" do
      expect(property.parse(10)).to eql(10)
    end

    it "casts strings to integers" do
      expect(property.parse("10")).to eql(10)
    end

    it "raises an error when given an string that contains any non-numeric characters" do
      expect{property.parse("0-test")}.to raise_error(RapidProps::InvalidPropertyError)
      expect{property.parse("1.5")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a float" do
      expect{property.parse(1.4)}.to raise_error(RapidProps::InvalidPropertyError)
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
      builder.integer(:position)
      expect(builder.klass.properties.keys).to match_array(%i[position])
    end

    it "defines a reader and a writer method" do
      builder.integer(:position)
      expect{instance.position = 3}.to change{instance.position}.from(nil).to(3)
    end
  end
end
