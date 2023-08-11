# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::BooleanProperty, type: :property do
  it "has a type" do
    expect(described_class.type).to eql("boolean")
  end

  describe "parse" do
    it "recognizes true" do
      expect(property.parse(true)).to eql(true)
    end

    it "recognizes false" do
      expect(property.parse(false)).to eql(false)
    end

    RapidProps::BooleanProperty::RECOGNIZED_STRINGS.each do |value, result|
      it "cast #{value.inspect} to #{result.inspect}" do
        expect(property.parse(value)).to eql(result)
      end
    end

    it "raises an error when given an array" do
      expect{property.parse([])}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    {
      true => true,
      false => false,
    }.each do |value, result|
      it "serializes #{value.inspect} to #{result.inspect}" do
        expect(property.serialize(value)).to eql(result)
      end
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.boolean(:enabled)
      expect(builder.klass.properties.keys).to match_array(%i[enabled])
    end

    it "defines a reader and a writer method" do
      builder.boolean(:enabled)
      expect{instance.enabled = true}.to change{instance.enabled}.from(nil).to(true)
    end

    it "defines a reader method with a question mark suffix" do
      builder.boolean(:enabled)
      expect(instance.enabled?).to eql(nil)
    end

    it "automatically validates presence of the property when null: false" do
      builder.boolean(:enabled, null: false)
      expect(instance.valid?).to eql(false)
      expect(instance.errors.details[:enabled]).to eql([{ error: :inclusion, value: nil }])
    end

    it "knows that a false value is a presence value" do
      builder.boolean(:enabled, null: false)
      instance.enabled = false
      expect(instance.valid?).to eql(true)
    end
  end
end
