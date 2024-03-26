# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::EmailProperty, type: :property do
  let(:valid_email) { "dan@rapidlybuilt.com" }

  describe "parse" do
    it "allows valid emails" do
      expect(property.parse(valid_email)).to eql(valid_email)
    end

    it "raises an error when given an invalid email" do
      expect{property.parse("dan.com")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a float" do
      expect{property.parse(1.4)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "serializes numbers" do
      expect(property.serialize(valid_email)).to eql(valid_email)
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.email(:admin)
      expect(builder.klass.properties.keys).to match_array(%i[admin])
    end

    it "defines a reader and a writer method" do
      builder.email(:admin)
      expect{instance.admin = valid_email }.to change{instance.admin}.from(nil).to(valid_email)
    end
  end
end
