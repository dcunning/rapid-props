# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::EnumProperty, type: :property do
  let(:choices) { %w[foo bar baz] }

  it "appends the choices to the its hash" do
    expect(property.to_hash[:choices]).to eql(choices)
  end

  describe "parse" do
    it "allows values from the choices" do
      expect(property.parse("foo")).to eql("foo")
    end

    it "raises an error if the value isn't one of the choices" do
      expect{property.parse("z")}.to raise_error(RapidProps::EnumProperty::UnknownEnumError)
    end
  end

  describe "serialize" do
    it "serializes choices to strings" do
      expect(property.serialize("foo")).to eql("foo")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.enum(:category, choices: choices)
      expect(builder.klass.properties.keys).to match_array(%i[category])
    end

    it "defines a reader and a writer method" do
      builder.enum(:category, choices: choices)
      expect{instance.category = "foo"}.to change{instance.category}.from(nil).to("foo")
    end
  end


  describe "non-string choices" do
    let(:choices) { [true, false, "pending"] }

    it "doesn't error when parsing a non-string choice" do
      expect(property.parse(true)).to eql(true)
    end

    it "still errors when given an invalid choice" do
      expect{property.parse("foo")}.to raise_error(RapidProps::EnumProperty::UnknownEnumError)
    end
  end

  private

  def property(**kargs)
    super(**kargs.reverse_merge(choices: choices))
  end
end
