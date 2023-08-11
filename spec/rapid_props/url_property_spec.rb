# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::UrlProperty, type: :property do
  let(:https) { URI("https://rapidlybuilt.com") }
  let(:non_https) { URI("http://rapidlybuilt.com") }

  describe "parse" do
    it "allows HTTPS URI objects" do
      expect(property.parse(https)).to eql(https)
    end

    it "allows HTTP URI objects" do
      expect(property.parse(non_https)).to eql(non_https)
    end

    it "casts strings to URIs" do
      expect(property.parse("https://rapidlybuilt.com")).to eql(https)
    end

    it "raises an error when given an invalid URI" do
      expect{property.parse("<")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a float" do
      expect{property.parse(1.4)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "serializes numbers" do
      expect(property.serialize(https)).to eql("https://rapidlybuilt.com")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.url(:home_page)
      expect(builder.klass.properties.keys).to match_array(%i[home_page])
    end

    it "defines a reader and a writer method" do
      builder.url(:home_page)
      expect{instance.home_page = https}.to change{instance.home_page}.from(nil).to(https)
    end
  end
end
